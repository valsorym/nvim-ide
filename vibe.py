#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
A robust tool to collect project files and emit chunked text packs for
LLM review. Produces .vibe/000.txt (prompt + optional lists) and
subsequent 001.txt, 002.txt, ... with file contents.

Highlights:
- Globs for include/ignore (fnmatch, ** supported)
- Optional Git-aware collection (respects .gitignore via git ls-files)
- Streaming chunk build (low RAM), soft UTF-8 decode
- Language fences + per-file metadata (lines/bytes/short sha)
- Optional directory trees: -d (filtered) and -t/--tree (full)
- Dry-run, stdout mode, and a "clear" subcommand to remove .vibe

Usage examples:
  # basic scans
  ./vibe.py ./app/core
  ./vibe.py ./app/core:mod,serv -m md,pdf
  ./vibe.py -o py,ts -f ./app
  ./vibe.py -s 3 ./app
  ./vibe.py --git -o py,ts .

  # ignore file patterns and extensions
  ./vibe.py -i "*.log,temp*" ./         # ignore by file patterns
  ./vibe.py -m md,pdf ./                # ignore by extensions
  ./vibe.py -o py,js,ts ./              # only include specific extensions

  # directory trees
  ./vibe.py -d ./             # filtered tree (hides .vibe and vibe.py)
  ./vibe.py -t ./             # full tree (shows everything)

  # maintenance
  ./vibe.py clear             # delete .vibe directory
"""

from __future__ import annotations

import argparse
import hashlib
import shutil
import subprocess
import sys
from dataclasses import dataclass
from fnmatch import fnmatch
from pathlib import Path
from typing import Iterable, List, Optional, Set, Tuple

# ------------------------------ Prompts ----------------------------------

BASE_PROMPT = (
    'You will receive a codebase in multiple parts ("chunks"). Each '
    "chunk includes a file list and fenced contents with language tags.\n\n"
    "Guidelines:\n"
    '1) After each chunk, reply only with: "Keep going."\n'
    "2) Do not propose changes until I say we finished sending chunks.\n"
    "3) When modifying code later, rewrite only entire functions/methods\n"
    "   that change. Include the full updated function/method.\n"
    "4) Comments and texts in the code must be in English only.\n"
    "5) For programming code (py,go,c/c++,js,ts), keep lines ≤79 characters.\n"
    "6) Explanations in Ukrainian.\n"
    "7). Do'not create migration files unless explicitly requested.\n\n"
    "Acknowledge and wait for parts."
)
FILES_LIST_HEADER = (
    "Complete file list across all parts:\n"
    "P.S. Be sure to specify the name of the file you are making changes to.\n"
)
DIRECTORY_STRUCTURE_HEADER = "Project structure:\n\n"
FULL_TREE_HEADER = "Full project tree (unfiltered):\n\n"

CHUNK_HEADER = (
    "You are now being provided with the following files:\n{file_list}\n\n"
    "This is part of the codebase. Don't take any action, just review it "
    'and reply: "Keep going."\n\n'
)

LARGE_FILE_SPLIT_LABEL = "{rel} is large; emitting part {part}/{total}.\n\n"

# ------------------------------ Defaults ---------------------------------

DEFAULT_TEXT_EXTENSIONS: Set[str] = {
    # programming
    "py",
    "ts",
    "js",
    "c",
    "cpp",
    "h",
    "hpp",
    "cs",
    "java",
    "php",
    "rb",
    "lua",
    "dart",
    "r",
    "jl",
    "scala",
    "rs",
    "vb",
    "swift",
    # web/markup
    "html",
    "htm",
    "xml",
    "css",
    "scss",
    "sass",
    "md",
    "rst",
    "tex",
    # config/data
    "yaml",
    "yml",
    "ini",
    "toml",
    "cfg",
    "json",
    "json5",
    "csv",
    "sql",
    "diff",
    "patch",
    # scripting
    "sh",
    "bat",
    "ps1",
    "jsx",
    "tsx",
    # misc
    "txt",
    # extra useful
    "proto",
    "vue",
    "svelte",
    "astro",
    "gradle",
    "bzl",
    "cmake",
    "kt",
}

IGNORED_DIRECTORIES: Set[str] = {
    "__pycache__",
    "migrations",
    ".git",
    ".vscode",
    ".venv",
    ".vibe",
}

IGNORED_FILES: Set[str] = {
    "vibe.py",
    ".gitignore",
    ".gitkeep",
    ".env",
}

SPECIAL_NAMES_LANG = {
    "Makefile": "make",
    "Dockerfile": "dockerfile",
    "CMakeLists.txt": "cmake",
    "Procfile": "",
    "LICENSE": "",
    "go.mod": "",
    "go.sum": "",
    "BUILD": "bzl",
    "WORKSPACE": "bzl",
}

LANG_BY_EXT = {
    "py": "python",
    "ts": "ts",
    "tsx": "tsx",
    "js": "javascript",
    "jsx": "jsx",
    "go": "go",
    "rs": "rust",
    "java": "java",
    "kt": "kotlin",
    "c": "c",
    "h": "c",
    "cpp": "cpp",
    "hpp": "cpp",
    "cs": "csharp",
    "rb": "ruby",
    "php": "php",
    "swift": "swift",
    "sh": "bash",
    "ps1": "powershell",
    "lua": "lua",
    "html": "html",
    "htm": "html",
    "css": "css",
    "scss": "scss",
    "sass": "sass",
    "xml": "xml",
    "vue": "vue",
    "svelte": "svelte",
    "astro": "astro",
    "toml": "toml",
    "ini": "ini",
    "cfg": "ini",
    "yaml": "yaml",
    "yml": "yaml",
    "json": "json",
    "json5": "json",
    "csv": "csv",
    "md": "md",
    "rst": "rst",
    "proto": "proto",
    "gradle": "gradle",
    "cmake": "cmake",
    "bzl": "bzl",
}

# ------------------------------ Helpers ----------------------------------


@dataclass(frozen=True)
class FileMeta:
    path: Path
    rel: Path


def language_for(path: Path) -> str:
    """Return language tag for fenced code blocks."""
    name = path.name
    if name in SPECIAL_NAMES_LANG:
        return SPECIAL_NAMES_LANG[name]
    ext = path.suffix[1:].lower()
    return LANG_BY_EXT.get(ext, "")


def short_sha256_head(path: Path, limit: int = 4096) -> str:
    """Short digest of the first bytes for lightweight identity."""
    h = hashlib.sha256()
    with path.open("rb") as f:
        h.update(f.read(limit))
    return h.hexdigest()[:12]


def read_text_soft(path: Path) -> Tuple[str, int]:
    """Read as UTF-8; on decode error, replace unknown characters."""
    try:
        txt = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        txt = path.read_text(encoding="utf-8", errors="replace")
    lines = txt.count("\n")
    if txt and not txt.endswith("\n"):
        lines += 1
    return txt, lines


def is_in_ignored_dir(path: Path) -> bool:
    """True if any ignored directory is in the path parts."""
    return any(part in IGNORED_DIRECTORIES for part in path.parts)


def build_tree_lines(base_dir: Path, include_all: bool) -> List[str]:
    """Build unicode tree. If include_all, do not filter anything except minimal exclusions."""
    lines: List[str] = []
    base = base_dir.resolve()
    if not base.exists():
        return [f"{base_dir} [directory does not exist]"]

    def skip(p: Path) -> bool:
        if include_all:
            # For full tree mode (-t), only skip .git, .vibe directories and vibe.py file
            if p.is_dir():
                return p.name in {".git", ".vibe"}
            elif p.is_file():
                return p.name == "vibe.py"
            return False
        else:
            # For filtered tree mode (-d), use original logic
            if p.is_dir() and is_in_ignored_dir(p):
                return True
            if p.is_file() and p.name in IGNORED_FILES:
                return True
            return False

    def walk(p: Path, pref: str, last: bool) -> None:
        conn = "└── " if last else "├── "
        lines.append(pref + conn + p.name)
        newp = pref + ("    " if last else "│   ")
        if p.is_dir():
            try:
                kids = [k for k in sorted(p.iterdir(), key=_sort_key) if not skip(k)]
            except PermissionError:
                lines.append(newp + "[Permission denied]")
                return
            for i, k in enumerate(kids):
                walk(k, newp, i == len(kids) - 1)

    lines.append(str(base_dir))
    try:
        first = [k for k in sorted(base.iterdir(), key=_sort_key) if not skip(k)]
        for i, k in enumerate(first):
            walk(k, "", i == len(first) - 1)
    except PermissionError:
        lines.append("  [Permission denied]")
    return lines


def _sort_key(p: Path) -> Tuple[int, str]:
    return (1 if p.is_file() else 0, p.name.lower())


def parse_target(target: str) -> Tuple[Path, List[str]]:
    """Parse TARGET like path or path:pattern1,pattern2."""
    t = target.rstrip("/")
    if ":" in t:
        d, pats = t.split(":", 1)
        patterns = [x for x in pats.split(",") if x]
    else:
        d, patterns = t, []
    return Path(d).resolve(), patterns


def match_any(name: str, patterns: Iterable[str]) -> bool:
    return any(fnmatch(name, p) for p in patterns)


def normalize_exts(csv: Optional[str]) -> Set[str]:
    if not csv:
        return set()
    return {e.strip().lower().lstrip(".") for e in csv.split(",") if e}


def should_take_by_ext(path: Path, only: Set[str]) -> bool:
    ext = path.suffix[1:].lower()
    if not only:
        return ext in DEFAULT_TEXT_EXTENSIONS or ext == ""
    return ext in only or ext == ""


def collect_git_files(root: Path) -> List[Path]:
    """Use git to list tracked files. Falls back to rglob on error."""
    try:
        out = subprocess.check_output(
            ["git", "ls-files"], cwd=str(root), stderr=subprocess.DEVNULL
        )
        rels = out.decode("utf-8", "ignore").splitlines()
        files = [root.joinpath(r).resolve() for r in rels]
        return [p for p in files if p.is_file()]
    except Exception:
        return [p for p in root.rglob("*") if p.is_file()]


def collect_from_target(
    directory: Path,
    patterns: List[str],
    miss_ext: Set[str],
    only_ext: Set[str],
    ignore_masks: List[str],
    use_git: bool,
) -> List[Path]:
    """Collect files respecting globs, ext filters, and ignore masks."""
    if not directory.exists():
        print(
            f"Warning: Directory {directory} does not exist",
            file=sys.stderr,
        )
        return []

    # candidate universe
    if use_git:
        universe = collect_git_files(directory)
    else:
        universe = [p for p in directory.rglob("*") if p.is_file()]

    def keep_by_patterns(p: Path) -> bool:
        if not patterns:
            return True
        rel = p.relative_to(directory).as_posix()
        return any(fnmatch(rel, pat + "*") or fnmatch(rel, pat) for pat in patterns)

    files: List[Path] = []
    for p in universe:
        if is_in_ignored_dir(p):
            continue
        name = p.name
        if name in IGNORED_FILES:
            continue
        rel = p.relative_to(directory).as_posix()
        if ignore_masks and (
            match_any(name, ignore_masks) or match_any(rel, ignore_masks)
        ):
            continue
        ext = p.suffix[1:].lower()
        if ext in miss_ext:
            continue
        if not should_take_by_ext(p, only_ext):
            continue
        if not keep_by_patterns(p):
            continue
        files.append(p)

    return sorted(set(files))


def build_file_block(path: Path) -> Tuple[str, int, int]:
    """Return (rendered block, line_count, byte_size)."""
    txt, lines = read_text_soft(path)
    rel = path.relative_to(Path.cwd())
    lang = language_for(path)
    dig = short_sha256_head(path)
    size = path.stat().st_size
    head = f"{rel}  |  {lines} lines  |  {size} bytes  |  sha:{dig}\n"
    fence = lang if lang else ""
    block = f"{head}```{fence}\n{txt}\n```\n"
    return block, lines, size


def write_prompt(
    outdir: Optional[Path],
    include_files: bool,
    files: List[Path],
    tree_lines: Optional[List[str]],
    full_tree_lines: Optional[List[str]],
    stdout: bool,
) -> None:
    """Write 000.txt with prompt, file list, and trees."""
    buf: List[str] = [BASE_PROMPT]
    if include_files and files:
        buf.append("\n\n" + FILES_LIST_HEADER)
        for p in files:
            rel = p.relative_to(Path.cwd())
            buf.append(f"- {rel}")
    if tree_lines:
        buf.append("\n\n" + DIRECTORY_STRUCTURE_HEADER)
        buf.extend(tree_lines)
    if full_tree_lines:
        buf.append("\n\n" + FULL_TREE_HEADER)
        buf.extend(full_tree_lines)

    text = "\n".join(buf) + "\n"
    if stdout:
        sys.stdout.write("===== 000.txt =====\n")
        sys.stdout.write(text)
        return

    assert outdir is not None
    p = outdir / "000.txt"
    p.write_text(text, encoding="utf-8")


def emit_chunks(
    files: List[Path],
    max_lines: int,
    outdir: Optional[Path],
    stdout: bool,
) -> Tuple[int, int, int]:
    """Stream files into chunk files. Return (chunks, lines, bytes)."""
    tol = int(max_lines * 1.1)
    cur_lines = 0
    cur_files: List[str] = []
    cur_buf: List[str] = []
    idx = 1
    total_lines = 0
    total_bytes = 0

    def flush() -> None:
        nonlocal cur_lines, cur_files, cur_buf, idx
        if not cur_buf:
            return
        header = CHUNK_HEADER.format(file_list="\n".join(f"- {s}" for s in cur_files))
        body = header + "".join(cur_buf)
        if stdout:
            sys.stdout.write(f"===== {idx:03d}.txt =====\n")
            sys.stdout.write(body)
        else:
            assert outdir is not None
            path = outdir / f"{idx:03d}.txt"
            path.write_text(body, encoding="utf-8")
        idx += 1
        cur_lines = 0
        cur_files.clear()
        cur_buf.clear()

    for p in files:
        try:
            block, lines, bsize = build_file_block(p)
            total_lines += lines
            total_bytes += bsize
        except Exception as e:
            print(f"Error reading {p}: {e}", file=sys.stderr)
            continue
        if lines > tol:
            flush()
            text, _ = read_text_soft(p)
            parts: List[str] = []
            ll = text.splitlines()
            for i in range(0, len(ll), max_lines):
                parts.append("\n".join(ll[i : i + max_lines]))
            total = len(parts)
            rel = p.relative_to(Path.cwd())
            lang = language_for(p)
            fence = lang if lang else ""
            for i, part in enumerate(parts, 1):
                label = LARGE_FILE_SPLIT_LABEL.format(rel=rel, part=i, total=total)
                body = label + f"```{fence}\n{part}\n```\n"
                cur_files[:] = [f"{rel} (part {i}/{total})"]
                cur_buf[:] = [body]
                cur_lines = max_lines
                flush()
            continue
        if cur_buf and cur_lines + lines > tol:
            flush()
        cur_buf.append(block)
        cur_files.append(str(p.relative_to(Path.cwd())))
        cur_lines += lines
    flush()
    return idx - 1, total_lines, total_bytes


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Aggregate project files into .vibe/ chunks",
    )

    p.add_argument(
        "targets",
        nargs="*",
        default=["."],
        help="Targets: 'path' or 'path:pattern1,pattern2', or 'clear' to remove .vibe",
    )
    p.add_argument(
        "-d",
        "--dir",
        help="Directory to print a filtered tree from",
    )
    p.add_argument(
        "-t",
        "--tree",
        help="Directory to print a full tree from",
    )
    p.add_argument(
        "-f",
        "--files",
        action="store_true",
        help="Include scanned file list in 000.txt",
    )
    p.add_argument(
        "-i",
        "--ignore",
        action="append",
        help="Ignore masks (glob). Can be repeated or comma-separated",
    )
    p.add_argument(
        "-m",
        "--miss",
        help="Comma-separated extensions to ignore",
    )
    p.add_argument(
        "-o",
        "--only",
        help="Comma-separated extensions to include",
    )
    p.add_argument(
        "-s",
        "--sep",
        type=int,
        help="Separate files into chunks of N*1000 lines (default 10)",
    )
    p.add_argument(
        "--git",
        action="store_true",
        help="Use 'git ls-files' as the file universe",
    )
    p.add_argument(
        "--stdout",
        action="store_true",
        help="Write all output to stdout instead of .vibe/ files",
    )
    p.add_argument(
        "--dry",
        dest="dry_run",
        action="store_true",
        help="Do not write contents; print a summary then exit",
    )
    p.add_argument(
        "-q",
        "--quiet",
        action="store_true",
        help="Less console noise",
    )

    return p.parse_args()


def cmd_clear() -> None:
    outdir = Path("./.vibe")
    if outdir.exists():
        shutil.rmtree(outdir)
        print(f"Removed {outdir.resolve()}")
    else:
        print(".vibe does not exist")


def main() -> None:
    args = parse_args()

    # Check if 'clear' is in targets
    if "clear" in args.targets:
        cmd_clear()
        return

    miss_ext = normalize_exts(args.miss)
    only_ext = normalize_exts(args.only)

    ignore_masks: List[str] = []
    if args.ignore:
        for group in args.ignore:
            ignore_masks.extend([x for x in group.split(",") if x])

    tree_lines: Optional[List[str]] = None
    if args.dir:
        tree_lines = build_tree_lines(Path(args.dir), include_all=False)

    full_tree_lines: Optional[List[str]] = None
    if args.tree:
        full_tree_lines = build_tree_lines(Path(args.tree), include_all=True)

    all_files: Set[Path] = set()

    # Filter out 'clear' from targets if present
    scan_targets = [t for t in args.targets if t != "clear"]
    if not scan_targets:
        scan_targets = ["."]

    for target in scan_targets:
        try:
            directory, patterns = parse_target(target)
            if not args.quiet:
                pats = ",".join(patterns) if patterns else "all recursively"
                print(f"Scanning {directory} with patterns: {pats}")
            found = collect_from_target(
                directory=directory,
                patterns=patterns,
                miss_ext=miss_ext,
                only_ext=only_ext if only_ext else DEFAULT_TEXT_EXTENSIONS,
                ignore_masks=ignore_masks,
                use_git=args.git,
            )
            all_files.update(found)
        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)

    files = sorted(all_files)

    if args.dry_run:
        print(f"Files: {len(files)}")
        for p in files:
            rel = p.relative_to(Path.cwd())
            print(f"- {rel}")
        if tree_lines:
            print("\nTree (filtered):\n")
            print("\n".join(tree_lines))
        if full_tree_lines:
            print("\nTree (full):\n")
            print("\n".join(full_tree_lines))
        return

    if args.stdout:
        outdir = None
    else:
        outdir = Path("./.vibe")
        if outdir.exists():
            shutil.rmtree(outdir)
        outdir.mkdir(parents=True, exist_ok=True)

    max_lines = (args.sep * 1000) if args.sep else 10000

    write_prompt(
        outdir=outdir,
        include_files=args.files,
        files=files,
        tree_lines=tree_lines,
        full_tree_lines=full_tree_lines,
        stdout=args.stdout,
    )

    chunks, total_lines, total_bytes = emit_chunks(
        files=files, max_lines=max_lines, outdir=outdir, stdout=args.stdout
    )

    # Summary at the end
    print("\n--- Scan summary ---")
    print(f"Files scanned: {len(files)}")
    print(f"Total lines:   {total_lines}")
    print(f"Total bytes:   {total_bytes}")
    print(f"Chunks written:{chunks:>4}")
    if files:
        print("\nFiles:")
        for p in files:
            rel = p.relative_to(Path.cwd())
            print(f"- {rel}")


if __name__ == "__main__":
    main()
