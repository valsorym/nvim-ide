# Neovim IDE 2.0

[Українська](README.UK.md)

A terminal editor with file tabs, a floating explorer, searchable commands and
language tools. The dashboard, dark themes and tab workflow remain familiar;
version 2 uses native Neovim facilities for sessions, terminals, comments and snippets.

## Requirements and installation

- Neovim **0.11.3+**; this configuration is tested with **0.11.5**.
- Git for plugins and ripgrep (`rg`) for file and text search.
- A C compiler for Tree-sitter parsers; `make` enables the optional native Telescope sorter.
- A Nerd Font for icons and a terminal with 24-bit colour.
- Language runtimes and servers only for the languages you use. Node.js is required
  by several web/Python language servers; Python, Go and C/C++ tools have their own runtimes.
- Alacritty is optional, for the separate desktop window. Clipboard integration
  uses the provider available on your OS (`:checkhealth vim.provider`).

Back up an existing `~/.config/nvim` before installing. Keep its data and state
until you have checked your sessions and plugins. Clone into an empty destination:

```sh
git clone https://github.com/valsorym/nvim-ide.git ~/.config/nvim
nvim
```

The first start installs plugins. Subsequent starts do not check for updates or
install language servers automatically. Install language support explicitly:

```vim
:ParsersInstall
:LanguageToolsInstall
```

The second command installs the complete supported server set. Use `:Mason` or
`:LspInstall pyright lua_ls` to choose individual servers instead. Parser builds
need a compiler and network access. Restart after installing language tools.
`:Lazy restore` restores the plugin revisions
in `lazy-lock.json`; update plugins deliberately with `:Lazy update`.

## Ukrainian keyboard layouts

Command keys follow physical QWERTY positions. **`mac` is the default on every OS**:

| Setting | Physical `b` | Physical `s` |
| --- | --- | --- |
| `mac` (default) | `і` / `І` | `и` / `И` |
| `windows` | `и` / `И` | `і` / `І` |

Choose the layout before startup, for example in your shell configuration:

```sh
export NVIM_IDE_UKRAINIAN_LAYOUT=mac
# For the Windows-style Ukrainian layout:
export NVIM_IDE_UKRAINIAN_LAYOUT=windows
```

Alternatively, set this **before** `require("config.langmap").setup()` in `init.lua`:

```lua
vim.g.nvim_ide_ukrainian_layout = "mac" -- or "windows"
```

An explicit Lua value takes precedence over the environment variable. Restart
Neovim after changing it. This selects keyboard positions; it does not change
the OS layout or infer it from the OS name.

`<leader>` is **Space**. `Space wD`, `Space цВ`, `Space wВ` and `Space цD` all delete
the current session. Native commands such as `dw` also work at the same physical
positions. Command maps receive Ukrainian aliases as they are registered,
including lazy plugins and buffer-local menus; the command legend lists only
the English spelling. Insert, search and Ex-command text is not transliterated.
Ctrl/Alt combinations still depend on the keycodes sent by your terminal; the
layout option does not intercept terminal or OS shortcuts.

## Keys and command groups

`Space Space` searches the command legend; `Space ?` selects a group.
Keys are sequential, not held together. Uppercase letters require Shift.
The tables below list configured global mappings. `n` = Normal, `x` = Visual,
`o` = operator-pending, `i` = Insert. Native Vim commands remain available.

| Prefix | Group |
| --- | --- |
| `Space b` | Buffers and explorer |
| `Space c` | Code navigation, symbols and environments |
| `Space d` | Document formatting and indentation |
| `Space e` | Editing and clipboard |
| `Space f` | Finding and replacing |
| `Space g` | Git |
| `Space o` | Tool managers and configuration |
| `Space r` | Running terminals and REPLs |
| `Space t` | Tabs |
| `Space u` | Appearance |
| `Space w` | Workspaces and sessions |
| `Space x` | Checks and diagnostics |

| Key | Mode | Action |
| --- | --- | --- |
| `<leader><leader>` | n | Search commands |
| `<leader>?` | n | Browse key groups |
| `<leader>:` | n | Search Ex commands |
| `<leader>bb` | n | Find buffer |
| `<leader>bn` | n | Next buffer |
| `<leader>bp` | n | Previous buffer |
| `<leader>bd` | n | Delete buffer |
| `<leader>be` | n | File explorer |
| `<leader>bh` | n | Project history |
| `<leader>ca` | n/x | Code action |
| `<leader>cr` | n | Rename symbol |
| `<leader>cd` | n | Go to definition in tab |
| `<leader>cD` | n | Go to declaration in tab |
| `<leader>ci` | n | Go to implementation in tab |
| `<leader>ct` | n | Go to type definition in tab |
| `<leader>ch` | n | Signature help |
| `<leader>cs` | n | Document symbols |
| `<leader>cS` | n | Grouped document symbols |
| `<leader>cw` | n | Workspace symbols |
| `<leader>co` | n | Toggle code outline |
| `<leader>cO` | n | Outline navigation |
| `<leader>cva` | n | Detect Python environment |
| `<leader>cvc` | n | Select Python environment |
| `<leader>cvd` | n | Use system Python |
| `<leader>cvs` | n | Python environment status |
| `<leader>cvf` | n | Refresh Python environment |
| `<leader>cpt` | n | Toggle Copilot |
| `<leader>cps` | n | Copilot status |
| `<leader>cpa` | n | Copilot setup |
| `<leader>cpx` | n | Copilot sign out |
| `<leader>df` | n | Format document |
| `<leader>di` | n | Sort Python imports |
| `<leader>db` | n | Format Python with Black |
| `<leader>ds` | n | Toggle format on save |
| `<leader>dx` | n | Trim trailing whitespace |
| `<leader>d2` | n | Use two-space indentation |
| `<leader>d4` | n | Use four-space indentation |
| `<leader>dt` | n | Use tab indentation |
| `<leader>dS` | n | Convert tabs to spaces |
| `<leader>dT` | n | Convert spaces to tabs |
| `<leader>dI` | n | Show indentation settings |
| `<leader>dr` | n | Toggle Markdown / RST rendering |
| `<leader>ed` | n/x | Delete without yanking |
| `<leader>ec` | n/x | Change without yanking |
| `<leader>ey` | n/x | Yank to system clipboard |
| `<leader>ep` | n/x | Paste system clipboard |
| `<leader>ea` | n | Yank entire document |
| `<leader>eu` | n | Undo history |
| `<leader>ej` | x | Move selection down |
| `<leader>ek` | x | Move selection up |
| `<leader>ff` | n | Find files |
| `<leader>fg` | n | Search project text |
| `<leader>fG` | n | Search including ignored files |
| `<leader>fo` | n | Recent files |
| `<leader>fh` | n | Find help |
| `<leader>fr` | n | Find and replace in project |
| `<leader>fR` | n | Find and replace including ignored files |
| `<leader>fw` | n | Replace current word in project |
| `<leader>fj` | n/x/o | Flash jump |
| `<leader>fJ` | n/x/o | Flash syntax selection |
| `<leader>gs` | n/x | Stage Git hunk |
| `<leader>gr` | n/x | Reset Git hunk |
| `<leader>gp` | n | Preview Git hunk |
| `<leader>gb` | n | Blame current line |
| `<leader>gd` | n | Diff current file |
| `<leader>gt` | n | Toggle line blame |
| `<leader>ol` | n | Plugin manager |
| `<leader>om` | n | Language tool manager |
| `<leader>oc` | n | Open editor configuration |
| `<leader>rf` | n | Floating terminal |
| `<leader>rh` | n | Horizontal terminal |
| `<leader>rv` | n | Vertical terminal |
| `<leader>rp` | n | Python REPL |
| `<leader>rn` | n | Node REPL |
| `<leader>rd` | n | Django shell |
| `<leader>rr` | n | Django development server |
| `<leader>tn` | n | New tab |
| `<leader>tq` | n | Close current tab |
| `<leader>tQ` | n | Discard and close current tab |
| `<leader>tc` | n | Close saved tabs |
| `<leader>to` | n | Close other tabs |
| `<leader>tl` | n | Tab list |
| `<leader>th` | n | Move tab left |
| `<leader>tj` | n | Move tab right |
| `<leader>ta` | n | Quit editor |
| `<leader>ut` | n | Preview and select theme |
| `<leader>us` | n | Select and save theme |
| `<leader>ui` | n | Current theme |
| `<leader>uI` | n | Toggle indent guides |
| `<leader>uw` | n | Toggle wrapping |
| `<leader>ul` | n | Toggle whitespace marks |
| `<leader>uc` | n | Toggle column guide |
| `<leader>ws` | n | Save session |
| `<leader>wr` | n | Restore session |
| `<leader>wl` | n | Restore last session |
| `<leader>wD` | n | Delete current session |
| `<leader>wf` | n | Find session |
| `<leader>wL` | n | Import legacy session |
| `<leader>ww` | n | Find workspace |
| `<leader>wa` | n | Add workspace |
| `<leader>xx` | n | Line diagnostics |
| `<leader>xb` | n | Buffer diagnostics |
| `<leader>xw` | n | Workspace diagnostics |
| `<leader>xq` | n | Quickfix list |
| `<leader>xl` | n | Location list |
| `<leader>xt` | n | Find TODO comments |
| `<leader>xT` | n | Find TODO / FIXME |
| `<leader>xp` | n | Python tools status |
| `<leader>xi` | n | LSP health |
| `<leader>xh` | n | Editor / terminal health |
| `<leader>xL` | n | Buffer performance mode |
| `<F2>` | n/i | Save file |
| `<F5>` | n | Previous tab |
| `<F6>` | n | Next tab |
| `<F7>` | n | Document symbols |
| `<F8>` | n | Tab list |
| `<F9>` | n | File explorer |
| `<F10>` | n | Buffer list |
| `gd` | n | Go to definition in tab |
| `gD` | n | Go to declaration in tab |
| `gri` | n | Go to implementation in tab |
| `grt` | n | Go to type definition in tab |
| `gl` | n | Line diagnostics |
| `<C-LeftMouse>` | n | Go to definition in tab |
| `zR` | n | Open all folds |
| `zM` | n | Close all folds |
| `zr` | n | Open folds except configured kinds |
| `zm` | n | Fold one more level |
| `zp` | n | Preview fold |
| `]t` | n | Next TODO |
| `[t` | n | Previous TODO |
| `]c` | n | Next Git hunk |
| `[c` | n | Previous Git hunk |
| `<Esc>` | n | Clear search highlight |

### Native editing and local menus

Use `hjkl`, `w/b/e`, `f/t`, `ciw`, `dap`, `y/p`, `u`, `Ctrl-r` and text objects as
in Vim. `gc` comments a motion or selection; `gcc` comments a line. `=` indents
and `gq` wraps text. Window commands use `Ctrl-w`; `gt`/`gT` switch tabs.
`Ctrl-t` returns through the tag stack, `Ctrl-o`/`Ctrl-i` through jumps.
Native `:q`, `:new`, `:split` and `:vsplit` retain their meanings. `:Q` closes the
current IDE tab with a save/discard/cancel prompt; `:Q!` discards its changes.

- Completion: `Ctrl-n`/`Ctrl-p` navigate, `Ctrl-Space` requests completion,
  `Tab` accepts the current/first suggestion or advances a snippet, `Shift-Tab`
  goes back. `Enter` accepts only an explicitly selected suggestion, otherwise
  inserts a newline. `Ctrl-e` closes completion. Command-line completion is native.
- Telescope: `Ctrl-n`/`Ctrl-p` (also `Ctrl-j`/`Ctrl-k`) move, `Tab` selects multiple
  results, `Enter` accepts. File results open or reuse a tab. `Esc` leaves Insert
  mode; another `Esc` closes the picker.
- Explorer: `Enter` opens a file in a tab, `t` expands a directory, `T` collapses,
  `C` makes the selected directory the root, `B` uses the working directory,
  `P` goes to the parent, `gR` asks for a root path. `R` refreshes, `H` toggles
  hidden files, `F` filters, `X` clears the filter; `n/d/r/c/x/p` create/delete/
  rename/copy/cut/paste. `g?` shows local help, `Esc` closes the explorer.
- Project history (`Space bh`): `/` filters paths, `j/k` move, `Enter` selects,
  `d` removes an entry, `C` clears history and `q` closes the window.
- Tab list: `j/k` move, `/` or `i` searches, `Enter` selects, `d` closes with
  unsaved-work protection, `q` closes the list.
- Terminal: `Ctrl-\ Ctrl-n` returns to Normal mode. Run the same terminal mapping
  again to hide/show its buffer. Jobs are reused by working directory and task.
- Copilot remains optional and disabled initially. `Space cpt` enables it;
  `Space cpa` configures authentication. Insert-mode `Ctrl-g Ctrl-y` accepts,
  `Ctrl-g Ctrl-n`/`Ctrl-g Ctrl-p` cycle, `Ctrl-g Ctrl-e` dismisses suggestions.

## Language support

Filetype settings are retained for all previously supported languages. A server
starts only when its executable exists and a supported, ordinary-sized file opens.

| Files | Language servers | External formatting (`Space df`) |
| --- | --- | --- |
| Python | pyright | isort, then Black |
| JavaScript, TypeScript, JSX, TSX | ts_ls, emmet_ls | Prettier |
| Vue | vue_ls + ts_ls with Vue TypeScript plugin | Prettier |
| HTML | html, emmet_ls | Prettier |
| Django HTML | html, emmet_ls | Native `=` / `gq`; external formatting disabled |
| CSS, SCSS, Less | cssls; emmet_ls for CSS/SCSS | Prettier |
| Sass | Native syntax/indentation | Native `=` |
| Go | gopls | gofmt |
| C, C++ | clangd | clang-format |
| JSON, JSONC | jsonls with SchemaStore | Prettier |
| YAML | yamlls with SchemaStore | Prettier |
| Lua | lua_ls | StyLua |
| Shell | bashls | shfmt |
| Dockerfile | dockerls | Native `=` |
| Markdown | marksman | Prettier |
| reStructuredText | Native syntax + local renderer | Native `gq` |
| TOML, XML, INI, Make, plain text | Native filetype settings | Native `=` / `gq` |

LSP provides completion, definitions, references (`grr`), rename and diagnostics.
The table lists integrations, not bundled language runtimes. Linters such as
mypy and flake8 are optional external tools; no background lint job is started.
`:PythonToolsStatus` reports executable availability, not lint results.

Python environments are resolved per project (`.venv`, `venv`, `env`, `.env`,
then an inherited `VIRTUAL_ENV`, then system Python). `Space cvc` selects an
environment directory, `Space cvd` chooses system Python for the current project.
This does not rewrite the process PATH or change other projects' pyright clients.
For Vue, install both `vue-language-server` and `typescript-language-server`
through Mason. For C/C++, provide `compile_commands.json` when the project needs it.

### Formatting and replacement

Formatting is manual by default. `Space df` processes the in-memory document
asynchronously; it applies results only if the buffer has not changed in the
meantime. Formatters receive stdin and never overwrite your file directly.
Project Python tools and `node_modules/.bin` take precedence over PATH. If no
external formatter is available, an attached LSP formatter is used when supported.

`Space ds` toggles formatting on save for this editor process. Saving then waits
up to 1.5 seconds per formatter; a failure leaves the text unchanged. Set
`vim.g.format_on_save = true` before setup for a persistent preference. Install
only the tools you need, e.g. `python -m pip install black isort` inside a project
virtual environment, or Prettier as a project development dependency.
Trailing whitespace is removed only by `Space dx`; Markdown hard breaks survive
ordinary saves. Formatting Django templates is deliberately left to native commands.

`Space fr` searches for **literal, case-sensitive** text. Mark result lines with
`Tab`, then `Ctrl-r` in the prompt (or `r` in the results' Normal mode) to enter a
replacement. Without a selection, all currently collected result lines are used.
Review the confirmation before applying. Changes remain in undoable buffers;
review them with `:ls` and save with `:wall`. Already modified/read-only buffers,
large files and changed result lines are skipped. `Space fR` includes ignored
files except `.git`. Native `:%s` remains available for regular expressions.

## Performance and large files

Buffers larger than **1 MiB** or **20,000 lines** enter large-file mode. That
buffer skips Tree-sitter, LSP attachment, completion, diagnostics, folding and
indent guides. Other buffers keep their language tools. The original text and
normal editing remain available. `Space xL` / `:LargeFileInfo` shows the mode.
A growing buffer is checked on leaving Insert mode and after saving; reopen a
reduced file to reclassify it. Configure limits before module setup:

```lua
vim.g.nvim_ide_large_file_bytes = 2 * 1024 * 1024
vim.g.nvim_ide_large_file_lines = 30000
```

Completion searches only the current buffer. Python diagnostics cover open files.
Only the selected theme loads at startup; pickers, outlines and tool managers
load on demand. Tree-sitter indentation is disabled in favour of filetype rules.
Tab movement occurs once when a buffer becomes modified. To keep tab order fixed:

```lua
vim.g.nvim_ide_move_modified_tabs = false
```

## Sessions, tabs and themes

File search, the explorer and definition navigation open/reuse file tabs; native
splits remain usable. `Space tq` asks before discarding unsaved work. `Space tc`
closes only tabs whose windows contain no modified buffers. Hidden unrelated
buffers are retained. `F2` saves the current file, asking for a name when needed.

Sessions use native `:mksession` under `stdpath("state")/sessions-v2`. They preserve
files, directories, tabs, windows and folds, **not unsaved buffer text**. Eligible
project sessions save on exit; restore is explicit. `Space wD` deletes the current
session and prevents automatic recreation until `Space ws` explicitly saves it.
Restoring sessions or switching workspaces is refused while buffers are modified.
`Space wa` names the current directory; `Space ww` selects saved workspaces.

For version 1 sessions, use `Space wL` (`:SessionLegacy`), then `Space ws` after
restoring. Existing legacy files are retained. Add workspace names with `Space wa`.

`Space ut` previews themes, `Space us` selects and remembers one. The chosen name
is stored in Neovim's state directory; a legacy `.last_colorscheme` is read as a
fallback. Themes: Catppuccin, Tokyo Night, Gruvbox Material, Kanagawa, Nord, OneDark.
Restart after editing configuration; files are not automatically re-sourced.

## Terminal, desktop window and tmux

Use `nvim`, `nvim file` or `nvim -p first.py second.py` in any supported terminal.
For an independent Alacritty window on Linux:

```sh
mkdir -p ~/.local/bin ~/.local/share/applications
install -m 755 ~/.config/nvim/bin/nvim-ide ~/.local/bin/nvim-ide
install -m 644 ~/.config/nvim/extras/nvim-ide.desktop ~/.local/share/applications/nvim-ide.desktop
nvim-ide -p first.py second.py
```

Ensure `~/.local/bin` is on PATH. The launcher maximizes Alacritty directly and
needs no `wmctrl`. `nvim-ide --terminal file` runs in the current terminal.
It uses the same Neovim configuration and accepts ordinary Neovim arguments.

For true colours in tmux, include the supplied fragment in `~/.tmux.conf`:

```tmux
source-file ~/.config/nvim/extras/tmux.conf
```

Reload with `tmux source-file ~/.tmux.conf`, detach/reattach the client and create
a new pane. The fragment sets `default-terminal` to `tmux-256color` and advertises
RGB for Alacritty and `xterm-256color` clients. Add your actual outer terminal
name if it differs. Keep the terminal's real TERM value; do not force it in shell
startup files. `tmux-256color` terminfo must exist on the host (including SSH hosts).
See the [tmux colour FAQ](https://github.com/tmux/tmux/wiki/FAQ) for terminal-specific setup.

`:checkhealth nvim_ide` checks editor, keyboard and terminal settings;
`:checkhealth vim.lsp` checks language clients. RGB support is separate from the
font: use a Nerd Font if icons are missing. A Linux virtual console may not
support the same palette or glyphs as a graphical terminal emulator.

## Upgrading from version 1

Version 2 reorganizes leader mappings by action; consult `Space ?` and the tables
above. Formatting is under `Space d`, checks under `Space x`, terminals under
`Space r`. Native `z` folds, `Ctrl-w` windows, `Ctrl-t` tags and `Ctrl-k` digraphs
are available. The command legend uses one registry in `lua/config/keymaps.lua`.

Legendary, duplicate session managers, ToggleTerm, LuaSnip and redundant formatting
adapters are replaced by local modules/native APIs. Existing language support,
explorer, themes, Git signs, undo tree and optional Copilot remain. Install the
compatible parsers explicitly after upgrading. Back up configuration and state
before migrating; no legacy session deletion or broad package removal is required.

## Configuration layout

- `init.lua`: defaults, keyboard layout, module setup and lazy.nvim bootstrap.
- `lua/config/`: keys, tabs, sessions, Python environments, formatting, search and UI helpers.
- `lua/plugins/`: one owner per plugin configuration and its load conditions.
- `ftplugin/`: local indentation, comments and text options for each language.
- `lua/nvim_ide/health.lua`: `:checkhealth nvim_ide`.
- `bin/` and `extras/`: desktop launcher and terminal integration.
- `lazy-lock.json`: tested plugin revisions. Release version: `lua/plugins/dashboard.lua`.
