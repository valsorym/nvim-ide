# Set up Neovim IDE on Debian

[Українська](SETUP_DEBIAN.UK.md) · [Editor configuration and keys](README.md)

This guide takes a Debian 13 (trixie) desktop from a terminal to Neovim IDE:
Neovim, fonts, configuration, language tools and an optional application-menu
entry in its own terminal window. Commands use Bash and the default XDG paths.
Use your own paths if you set `XDG_CONFIG_HOME` or other XDG variables. Run `sh`
blocks in a terminal; `vim` blocks are commands entered inside Neovim after `:`.


Choose the route you need: sections 1–5 set up terminal editing and language
support; section 6 adds the separate IDE window, menu entry and Cinnamon shortcut;
sections 7–9 finish clipboard, tmux and verification. Install language tools for
the languages you use. A working installation has three separate layers:

| Layer | Installed by | What it provides |
| --- | --- | --- |
| Editor plugins | lazy.nvim on first start; `:Lazy restore` | Explorer, completion UI, theme picker and other editor features |
| Syntax parsers | `:ParsersInstall` / `:TSInstall language` | Tree-sitter highlighting |
| Runtimes, language servers and formatters | OS packages, Mason or project dependencies | Analysis, completion and formatting for the selected languages |

For a server or SSH session, use the terminal route and install the font on the
computer displaying the terminal. The Alacritty/menu steps need a graphical
session. Debian 12 has older packages, including an Alacritty version with YAML
configuration; use a TOML-capable Alacritty (0.13+) before following that section.

## 1. Install the base tools

Run package installation with sudo; all remaining configuration belongs to your
ordinary user. Git downloads plugins, curl/unzip fetch archives, build-essential
provides the compiler/make for parsers and the native sorter, and fontconfig
registers fonts. Ripgrep provides file and text search.

```sh
sudo apt update
sudo apt install --no-install-recommends \
  git curl ca-certificates unzip xz-utils build-essential fontconfig ripgrep
```

Prepare your user executable directory:

```sh
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
```

Add the following line once to `~/.profile` if it is not already there. A shell
that replaces PATH later must also retain this directory.

```sh
export PATH="$HOME/.local/bin:$PATH"
```

Log out of the desktop session and back in after finishing installation so
applications launched from the menu inherit the same PATH. `export` above only
updates the current shell; opening another terminal is not a desktop login.

## 2. Install a compatible Neovim

This configuration requires **Neovim 0.11.3+** and is tested on **0.11.5**.
Check `nvim --version` first; skip installation if you already have a compatible
version. The [Debian 13 stable package](https://packages.debian.org/trixie/neovim)
is 0.10.4, which is too old. The commands below install the tested upstream
0.11.5 archive for AMD64 or ARM64, with its SHA-256 from the
[official release](https://github.com/neovim/neovim/releases/tag/v0.11.5).

```sh
(
  set -eu
  nvim_version=0.11.5
  case "$(uname -m)" in
    x86_64)
      nvim_platform=linux-x86_64
      nvim_sha256=b2f91117be5b5ea39edd7297156dc2a4a8df4add6c95a90809a8df19e7ab6f52
      ;;
    aarch64|arm64)
      nvim_platform=linux-arm64
      nvim_sha256=ea4f9a31b11cc1477ff014aebb7b207684e7280f94ffa97abdab6cacd9b98519
      ;;
    *) printf '%s\n' 'Use the Neovim source-build instructions for this architecture.' >&2; exit 1 ;;
  esac
  nvim_prefix="$HOME/.local/opt/nvim-$nvim_version"
  if [ -e "$nvim_prefix" ]; then
    printf 'Already exists: %s; inspect it before reinstalling.\n' "$nvim_prefix" >&2
    exit 1
  fi
  nvim_download_dir=$(mktemp -d)
  trap 'rm -rf "$nvim_download_dir"' EXIT
  nvim_archive="nvim-$nvim_platform.tar.gz"
  curl -fL --retry 3 \
    "https://github.com/neovim/neovim/releases/download/v$nvim_version/$nvim_archive" \
    -o "$nvim_download_dir/$nvim_archive"
  (cd "$nvim_download_dir"; printf '%s  %s\n' "$nvim_sha256" "$nvim_archive" | sha256sum -c -)
  tar -xzf "$nvim_download_dir/$nvim_archive" -C "$nvim_download_dir"
  mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
  mv "$nvim_download_dir/nvim-$nvim_platform" "$nvim_prefix"
  if [ -e "$HOME/.local/bin/nvim" ] || [ -L "$HOME/.local/bin/nvim" ]; then
    mv "$HOME/.local/bin/nvim" "$HOME/.local/bin/nvim.bak.$(date +%Y%m%d-%H%M%S)"
  fi
  ln -s "$nvim_prefix/bin/nvim" "$HOME/.local/bin/nvim"
) && {
  hash -r
  command -v nvim
  nvim --version | head -n 1
}
```

The entire archive stays together under `~/.local/opt/nvim-0.11.5`, including
its runtime. This does not replace Debian-owned files in `/usr/bin`. The selected
binary should be `~/.local/bin/nvim`, and the version line should say `v0.11.5`.
If another version appears, check `type -a nvim` for aliases or PATH precedence.
On other architectures, follow the [official source build instructions](https://github.com/neovim/neovim/blob/v0.11.5/BUILD.md).

## 3. Install and select a Nerd Font

Icons require a Nerd Font **selected in the terminal**, not just downloaded.
One family is enough. This example installs UbuntuMono Nerd Font 3.4.0 for your
user, preserving existing font files:

```sh
(
  set -eu
  font_archive=$(mktemp --suffix=.zip)
  trap 'rm -f "$font_archive"' EXIT
  curl -fL --retry 3 \
    https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/UbuntuMono.zip \
    -o "$font_archive"
  mkdir -p "$HOME/.local/share/fonts/UbuntuMonoNerdFont"
  unzip -nq "$font_archive" -d "$HOME/.local/share/fonts/UbuntuMonoNerdFont"
  fc-cache -f "$HOME/.local/share/fonts/UbuntuMonoNerdFont"
)
fc-match 'UbuntuMono Nerd Font Mono'
```

`fc-match` should report `UbuntuMono Nerd Font Mono`, not a fallback such as
DejaVu Sans Mono. Choose that exact family in your terminal profile and reopen
terminal windows. The Mono variant keeps icons within terminal cells. Alacritty
configuration is shown in step 6; other [Nerd Font families](https://www.nerdfonts.com/font-downloads)
can be used instead. Missing icons do not require reinstalling Neovim plugins.

## 4. Clone the configuration and start Neovim

Close other Neovim instances before replacing a configuration. The following
moves an existing config aside and clones `master`; it keeps plugin data, sessions,
undo history and caches. Do not delete `~/.local/share/nvim`, `~/.local/state/nvim`
or `~/.cache/nvim` as a routine installation step.

```sh
(
  set -eu
  mkdir -p "$HOME/.config"
  if [ -e "$HOME/.config/nvim" ] || [ -L "$HOME/.config/nvim" ]; then
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak.$(date +%Y%m%d-%H%M%S)"
  fi
  git clone --branch master https://github.com/valsorym/nvim-ide.git "$HOME/.config/nvim"
)
nvim
```

For a fixed version, replace `--branch master` with `--branch v2.7.0`; a tag
checkout is detached and is updated by selecting another tag rather than pulling.
The first launch needs network access to install the locked plugin revisions.
Wait for installation to finish. Open the plugin window and restore the
repository's locked plugin revisions:

```vim
:Lazy
:Lazy restore
```

Wait for tasks to complete, quit with `:qa`, and reopen Neovim. Plugins are not
language servers or formatter executables: install those in the next section.
Avoid `:Lazy update` / `:Lazy sync` during installation if you want the tested
revisions from `lazy-lock.json`.


## 5. Add search and the language tools you need

Ripgrep is already installed in step 1. Run shell commands in a second terminal
or quit Neovim with `:qa`. Commands beginning with `:` belong inside Neovim.

### Runtimes

Python needs its interpreter and venv support:

```sh
sudo apt install --no-install-recommends python3 python3-venv
```

Web language servers, pyright and optional Copilot use Node.js. For current
packages use **Node.js 22+**. Check `node --version`; if a compatible runtime is
already available to desktop applications, keep it. This optional user-space
installation uses **Node.js v24.22.1 LTS**, including npm, and preserves existing
user executables. It does not replace Debian's `/usr/bin/node`.
The [official release list](https://nodejs.org/en/about/previous-releases) explains
LTS support; the archive checksums come from the official distribution.

```sh
(
  set -eu
  node_version=v24.22.1
  case "$(uname -m)" in
    x86_64) node_platform=linux-x64; node_sha256=6c172a9ab6718f7b801fb5a7bd486af2ee5e32758086a04b84fcce2aa77095e6 ;;
    aarch64|arm64) node_platform=linux-arm64; node_sha256=dbabf7a1cbf947e6059ffad2c27b80041db97dea1e553b62afdee7f13fca336e ;;
    *) printf '%s\n' 'Use the official Node.js installer for this architecture.' >&2; exit 1 ;;
  esac
  node_prefix="$HOME/.local/opt/node-$node_version"
  if [ -e "$node_prefix" ]; then
    printf 'Already exists: %s; inspect it before reinstalling.\n' "$node_prefix" >&2
    exit 1
  fi
  node_download_dir=$(mktemp -d)
  trap 'rm -rf "$node_download_dir"' EXIT
  node_archive="node-$node_version-$node_platform.tar.xz"
  curl -fL --retry 3 \
    "https://nodejs.org/dist/$node_version/$node_archive" \
    -o "$node_download_dir/$node_archive"
  (cd "$node_download_dir"; printf '%s  %s\n' "$node_sha256" "$node_archive" | sha256sum -c -)
  tar -xJf "$node_download_dir/$node_archive" -C "$node_download_dir"
  mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
  mv "$node_download_dir/node-$node_version-$node_platform" "$node_prefix"
  for executable in node npm npx; do
    if [ -e "$HOME/.local/bin/$executable" ] || [ -L "$HOME/.local/bin/$executable" ]; then
      mv "$HOME/.local/bin/$executable" "$HOME/.local/bin/$executable.bak.$(date +%Y%m%d-%H%M%S)"
    fi
    ln -s "$node_prefix/bin/$executable" "$HOME/.local/bin/$executable"
  done
) && {
  hash -r
  node --version
  npm --version
}
```

The complete Node.js directory must stay together. The symlinks in `~/.local/bin`
make this runtime visible to the launcher after the PATH/login step in section 1.
If using nvm/fnm or another version manager, its selected Node.js must also be
visible to applications launched from the desktop menu.

### Editor support and language servers

Reopen `nvim`. A Python/Lua starting set is:

```vim
:ParsersInstall
:LspInstall pyright lua_ls
:MasonInstall ruff stylua
```

`:ParsersInstall` installs the configured parser set; use `:TSInstall python lua`
for a smaller selection. These commands need network access and a C compiler.
Choose language servers individually with the commands below:

| Language | Command inside Neovim |
| --- | --- |
| Python | `:LspInstall pyright` |
| JavaScript / TypeScript / JSX / TSX | `:LspInstall ts_ls emmet_ls` |
| Vue | `:LspInstall vue_ls ts_ls` |
| HTML / Django HTML | `:LspInstall html emmet_ls` |
| CSS / SCSS / Less | `:LspInstall cssls emmet_ls` |
| Go | `:LspInstall gopls` |
| C / C++ | `:LspInstall clangd` |
| Lua | `:LspInstall lua_ls` |
| Shell / Bash | `:LspInstall bashls` |
| JSON / JSONC | `:LspInstall jsonls` |
| YAML | `:LspInstall yamlls` |
| Dockerfile | `:LspInstall dockerls` |
| Markdown | `:LspInstall marksman` |

For the full configured server set and the common external formatters:

```vim
:LanguageToolsInstall
:MasonInstall ruff prettierd stylua
```

`LanguageToolsInstall` installs servers; it does not install Go/Python/Node.js,
compilers or every formatter. `:Mason` shows installation progress and failures;
`:MasonLog` gives details. Restart Neovim after installation and open an actual
project file so the corresponding client can attach.

### Formatters and system toolchains

These are executable programs, not additional Neovim plugins. Run `:MasonInstall`
inside Neovim and `sudo apt install` in a terminal. Pick the rows you need:

| Language / files | Install formatter / toolchain |
| --- | --- |
| Python | `:MasonInstall ruff` |
| JavaScript / TypeScript / Vue / HTML / CSS / SCSS / Less / JSON / YAML / Markdown | `:MasonInstall prettierd` |
| Lua | `:MasonInstall stylua` |
| Go | `sudo apt install golang-go` |
| C / C++ | `sudo apt install clang-format` |
| Rust | `sudo apt install cargo rustfmt` |
| Shell / Bash | `sudo apt install shfmt` |

For Go, `gofmt` comes with the Go toolchain; `gopls` is a separate language
server. For C/C++, install `clangd` as well as `clang-format` when you want both
analysis and formatting (`sudo apt install clangd clang-format`). Rust currently
has native editing plus rustfmt formatting; rust-analyzer is not configured.

The web formatter defaults to prettierd, started only on the first format.
If it is absent, the editor uses Prettier CLI (`:MasonInstall prettier` or a
project development dependency). With Node.js 20, use the compatible
`:MasonInstall prettierd@0.28.0`; newer releases require Node.js 22+.
The project-local Prettier version/configuration is respected. See the
[formatting settings](README.md#formatting-and-replacement) for the CLI switch,
Markdown paragraph preservation and daemon restart after dependency updates.

Django HTML deliberately keeps external formatting disabled; use native `=` / `gq`.
Sass indentation, TXT/RST and TOML/XML/INI/Make use their native editing commands.
No missing external formatter is an error for those native workflows.

For Python, Ruff may instead live in the project's own environment:

```sh
python3 -m venv .venv
.venv/bin/python -m pip install ruff
```

No global pip installation or Python provider package is needed. Pyright analyzes
the selected environment; `Space cvc` selects another one. `Space df` formats the
current document. Formatting on save is optional (`Space ds`). Open `Space xH`
/ `:IdeHealth` to see resolved paths and missing requirements for the source project.
Parsers and language tools are never downloaded just by opening a file.

## 6. Optional: launch as a desktop IDE in Alacritty

Install Alacritty and the application-menu utilities:

```sh
sudo apt install --no-install-recommends alacritty desktop-file-utils
mkdir -p "$HOME/.config/alacritty"
```

Create `~/.config/alacritty/alacritty.toml` with the font settings below. If that
file already exists, back it up and merge these settings into its existing font
tables; do not create duplicate tables or overwrite your other preferences.
This is Alacritty's default profile, shared by its other windows too.

```toml
[font]
size = 13.0

[font.normal]
family = "UbuntuMono Nerd Font Mono"
style = "Regular"

[font.bold]
family = "UbuntuMono Nerd Font Mono"
style = "Bold"

[font.italic]
family = "UbuntuMono Nerd Font Mono"
style = "Italic"

[font.bold_italic]
family = "UbuntuMono Nerd Font Mono"
style = "Bold Italic"
```

Install the supplied launcher and desktop entry. Back up existing files with
the same names first if you customized them. The desktop entry uses an absolute
launcher path so the menu can find it:

```sh
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"
install -m 755 "$HOME/.config/nvim/bin/nvim-ide" "$HOME/.local/bin/nvim-ide"
nvim_executable=$(readlink -f "$(command -v nvim)")
nvim_prefix=$(dirname "$(dirname "$nvim_executable")")
if [ -f "$nvim_prefix/share/icons/hicolor/128x128/apps/nvim.png" ]; then
  install -Dm644 "$nvim_prefix/share/icons/hicolor/128x128/apps/nvim.png" \
    "$HOME/.local/share/icons/hicolor/128x128/apps/nvim.png"
fi
desktop-file-install \
  --dir="$HOME/.local/share/applications" \
  --set-key=Exec --set-value="\"$HOME/.local/bin/nvim-ide\" %F" \
  --set-key=TryExec --set-value="$HOME/.local/bin/nvim-ide" \
  "$HOME/.config/nvim/extras/nvim-ide.desktop"
update-desktop-database "$HOME/.local/share/applications"
nvim-ide
```

After logging back into the desktop, find **Neovim IDE** in the application menu
and pin it to the panel if desired. The launcher creates its own maximized
Alacritty window with class `NVimIDE`; no wmctrl or separate GUI editor is needed.
It runs the same configuration as terminal `nvim` and accepts its arguments:

```sh
nvim-ide -p first.py second.py
nvim-ide --terminal first.py
```

### Add a Cinnamon keyboard shortcut

1. Print your launcher command in a terminal and copy the resulting quoted path:

```sh
printf '"%s"\n' "$HOME/.local/bin/nvim-ide"
```

2. Open **System Settings → Keyboard → Shortcuts → Custom Shortcuts** and choose
   **Add custom shortcut**.
3. Name it **Neovim IDE**. Paste the command from step 1, for example
   `"/home/YOUR_USER/.local/bin/nvim-ide"`, then click **Add**.
4. Select the new shortcut, double-click an **unassigned** entry under keyboard
   bindings, and press an unused combination, for example **Super+Shift+N**.
5. Close Settings and press the combination. It should open the maximized IDE
   window. Pin **Neovim IDE** from the application menu to the panel if desired.

The OS shortcut launches the editor; it is independent of Neovim's leader keys.
Use the full path rather than a bare `~` or `$HOME` in the shortcut command.
On another desktop, add the same command in its custom/application shortcut
settings. The font and window settings are described in the
[Alacritty manual](https://alacritty.org/config-alacritty.html).

### Choose an editor theme

Six theme families are configured: **Catppuccin**, **Tokyo Night**, **Gruvbox
Material**, **Kanagawa**, **Nord** and **One Dark**, with several variants. The
default is **Catppuccin Mocha**. Neovim also offers its built-in schemes.

- `Space ut` previews and selects a theme for this session; Esc cancels the preview.
- `Space us` selects and saves a theme for future starts.
- `Space ui` shows the active theme.

**`(default)`** always labels the theme configured by `default_theme` in
`lua/config/theme.lua`, currently **Catppuccin Mocha**. Changing themes for the
session or saving a personal preference does not move this marker. Dashboard previews
are centered inside the preview pane. The terminal needs true colour for the
palette and a Nerd Font for icons; a Neovim theme does not install a terminal font.

## 7. Enable the system clipboard

Check which graphical session you use:

```sh
printf '%s\n' "$XDG_SESSION_TYPE"
```

On X11 (including Cinnamon X11), install:

```sh
sudo apt install --no-install-recommends xclip
```

On Wayland, install:

```sh
sudo apt install --no-install-recommends wl-clipboard
```

Restart Neovim after installing the provider. Check it with
`:checkhealth vim.provider`; `"+yy` copies a line to the system clipboard.
Remote SSH sessions need their own clipboard solution; installing xclip on a
headless server alone does not connect it to your local desktop clipboard.

## 8. Optional: correct colours inside tmux

Install tmux and the extended terminal descriptions:

```sh
sudo apt install --no-install-recommends tmux ncurses-term
infocmp tmux-256color >/dev/null
```

Add this line to your existing `~/.tmux.conf` (keep other settings):

```tmux
source-file ~/.config/nvim/extras/tmux.conf
```

If a tmux server is already running, reload and inspect the client features:

```sh
tmux source-file "$HOME/.tmux.conf"
tmux display-message -p '#{client_termname} #{client_termfeatures}'
```

Detach and reattach the client, then create a **new pane**; existing panes keep
their earlier TERM. The fragment uses `tmux-256color` internally and advertises
RGB for Alacritty and xterm-256color clients. Add the actual outer terminal name
if different. Do not globally export a fabricated TERM in shell startup files.
For SSH, terminfo must also exist on the remote host. See the [tmux FAQ](https://github.com/tmux/tmux/wiki/FAQ).

## 9. Check the result and maintain the installation

In the terminal:

```sh
command -v nvim
nvim --version | head -n 1
rg --version | head -n 1
cc --version | head -n 1
fc-match 'UbuntuMono Nerd Font Mono'
```

In Neovim:

```vim
:checkhealth nvim_ide
:checkhealth vim.provider
:checkhealth vim.lsp
:checkhealth nvim-treesitter
```

Start with `:IdeHealth` (`Space xH`): `/` filters both languages, `r` refreshes,
`e` / `u` switches English/Ukrainian, and `q` closes. It shows which formatter is
selected and gives installation suggestions; it does not execute or install tools.

Open a file for an installed language before checking its LSP. Missing optional
servers/formatters in health output do not prevent editing other languages.
The dashboard, icons, `Space be` explorer and `Space h` keyboard help should work.
A Linux virtual console has more limited fonts/colours than a graphical terminal.

To update a clean `master` checkout after reviewing changes:

```sh
git -C "$HOME/.config/nvim" pull --ff-only
```

Keep local changes and the backup config until you have checked the update.
Restart Neovim and restore the repository's plugin versions:

```vim
:Lazy restore
```

Update installed parsers with `:TSUpdate` when plugin revisions change.
`:Lazy update` changes dependencies and is a deliberate upgrade, not a required
installation step. Copy the launcher/desktop entry again if an update changes
their supplied templates. Keys, Ukrainian layout options and everyday use are in
[README.md](README.md).
