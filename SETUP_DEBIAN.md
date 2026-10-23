# Set up Neovim IDE on Debian

[Українська](SETUP_DEBIAN.UK.md) · [Editor configuration and keys](README.md)

This guide takes a Debian 13 (trixie) desktop from a terminal to Neovim IDE:
Neovim, fonts, configuration, language tools and an optional application-menu
entry in its own terminal window. Commands use Bash and the default XDG paths.
Use your own paths if you set `XDG_CONFIG_HOME` or other XDG variables. Run `sh`
blocks in a terminal; `vim` blocks are commands entered inside Neovim after `:`.

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
  git curl ca-certificates unzip build-essential fontconfig ripgrep
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
)
hash -r
command -v nvim
nvim --version | head -n 1
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

For a fixed version, replace `--branch master` with `--branch v2.3.2`; a tag
checkout is detached and is updated by selecting another tag rather than pulling.
The first launch needs network access to install the locked plugin revisions.
Wait for installation to finish, then quit with `:qa` and reopen Neovim.

## 5. Add search and the language tools you need

Ripgrep is already installed in step 1. For the following shell commands, quit
Neovim with `:qa` or use a second terminal.

For Python/web language servers, install Node.js/npm; Python projects also need
Python and venv support. Skip runtimes you do not use:

```sh
sudo apt install --no-install-recommends nodejs npm python3 python3-venv
node --version
npm --version
```

Some newer language-server releases require a newer Node.js than Debian ships;
check the error in `:MasonLog` and use a supported LTS from the
[official Node.js downloads](https://nodejs.org/en/download) when needed. A Node
version manager must expose the chosen runtime to the desktop session too.

Reopen `nvim`. Inside the editor, this installs all supported syntax parsers,
two example language servers, and the optional Python formatter:

```vim
:ParsersInstall
:LspInstall pyright lua_ls
:MasonInstall ruff
```

Alternatively, install the complete supported server set:

```vim
:LanguageToolsInstall
```

`:LanguageToolsInstall` installs servers, not every language runtime or formatter.
`:Mason` lets you choose individual tools and shows installation failures. Some
binaries are unavailable for particular architectures; use a system package or
the tool's official instructions in that case. Restart Neovim after installation.
Parsers and servers are not downloaded automatically when opening a file.

Additional system tools, only for languages you use:

| Language | Install | Purpose |
| --- | --- | --- |
| Go | `sudo apt install golang-go gopls` | Go toolchain, gofmt and language server |
| C/C++ | `sudo apt install clangd clang-format` | Language server and formatter |
| Shell | `sudo apt install shfmt` | Shell formatter; bashls uses Node.js |

Use `:MasonInstall prettier stylua` for optional web/Lua formatters. Prettier may
instead be a project's development dependency. For Python, Ruff can be installed
in the project's own environment (run from the project directory):

```sh
python3 -m venv .venv
.venv/bin/python -m pip install ruff
```

No global pip installation or Python provider package is needed for this config.
Pyright analyzes the selected project environment; `Space cvc` selects another
one. See [language support](README.md#language-support) for the full integration
list and the distinction between servers, formatters and native editing commands.

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

On Cinnamon, a custom keyboard shortcut can run the absolute path
`/home/YOUR_USER/.local/bin/nvim-ide`. Do not use a bare `~` in a desktop Exec field.
The font and window settings are described in the [Alacritty manual](https://alacritty.org/config-alacritty.html).

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
