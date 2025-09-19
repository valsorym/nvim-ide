# NeoVim IDE Configuration

A full-featured IDE configuration for Neovim with support for Python + Django, JavaScript/TypeScript, Vue.js, C/C++, Go, and other programming languages.

## Installation

### 1. Install Dependencies and Tools

```bash
# Update system and install essential tools
sudo apt update && \
sudo apt install -y \
  build-essential \
  cmake \
  gettext \
  ninja-build \
  unzip \
  curl \
  git \
  libtool \
  libtool-bin \
  autoconf \
  automake \
  pkg-config \
  clangd \
  golang-go \
  fd-find \
  luarocks \
  cargo \
  composer \
  xclip \
  nodejs \
  npm \
  python3-pip \
  ripgrep
```

### 2. Install Nerd Fonts

```bash
# Download and install popular Nerd Fonts
adwaita="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/AdwaitaMono.zip"
anonymous="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/AnonymousPro.zip"
jetbrains="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"
firacode="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraCode.zip"
cascadia="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/CascadiaCode.zip"
hack="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Hack.zip"
sourcecode="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/SourceCodePro.zip"
ubuntu="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/UbuntuMono.zip"
dejavu="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/DejaVuSansMono.zip"
inconsolata="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Inconsolata.zip"

mkdir -p ~/.local/share/fonts && \
mkdir -p ~/tmp/fonts && \
cd ~/tmp/fonts && \
wget $adwaita && \
wget $anonymous && \
wget $jetbrains && \
wget $firacode && \
wget $cascadia && \
wget $hack && \
wget $sourcecode && \
wget $ubuntu && \
wget $dejavu && \
wget $inconsolata && \
unzip -o "*.zip" -d ~/.local/share/fonts/ && \
rm *.zip && \
fc-cache -fv
```

**⚠️ IMPORTANT**: Set one of the Nerd Font Mono fonts as your terminal's default font for proper icon display.

### 3. Install NeoVim from Source

```bash
# Create temporary directory and clone repository
mkdir -p /tmp/neovim && cd /tmp/neovim && \
git clone https://github.com/neovim/neovim.git && \
cd neovim && \
git checkout stable && \
make CMAKE_BUILD_TYPE=Release && \
sudo make install
```

### 4. Install Python Tools

```bash
# Global Python formatter installation
pip3 install black isort

# Or for specific project with virtual environment
python3 -m venv .venv
source .venv/bin/activate
pip install black isort django  # add other dependencies as needed
```

### 5. Install NVim-IDE Configuration

```bash
bash -lc '
set -euo pipefail
cd "$HOME"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/nvim"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/nvim"
[ -e "$config_dir" ] && mv "$config_dir" "$config_dir.bak.$(date +%s)"
[ -e "$data_dir" ] && mv "$data_dir" "$data_dir.bak.$(date +%s)"
[ -e "$state_dir" ] && mv "$state_dir" "$state_dir.bak.$(date +%s)"
[ -e "$cache_dir" ] && mv "$cache_dir" "$cache_dir.bak.$(date +%s)"
mkdir -p "$config_dir"
mkdir -p "$data_dir"
mkdir -p "$state_dir"
mkdir -p "$cache_dir"
echo -e "\n\nCloning NvChad..."
git clone --depth 1 https://github.com/valsorym/nvim-ide "$config_dir"
rm -rf "$config_dir/.git"
nvim --headless "+Lazy! sync" "+qa"
echo -e "\n\nNVim-IDE installed successfully: $config_dir"
echo "Plugins will install automatically on first launch..."
' && nvim
```

On first launch, Neovim will automatically:
- Install all plugins through Lazy.nvim
- Download LSP servers through Mason
- Configure Treesitter parsers

## Features

### Python + Django
- Automatic virtual environment detection (.venv, venv)
- Django template support (htmldjango, jinja2)
- Automatic import sorting with isort
- Code formatting with Black (79 characters per line)
- LSP support with Pyright
- Django management commands through terminal

### Web Development
- Full HTML/CSS/JavaScript/TypeScript support
- Vue.js with Vue Language Server
- CSS/JS in `<style>` and `<script>` blocks within HTML files
- Emmet for rapid HTML/CSS development
- Prettier for formatting
- JSON schemas from SchemaStore

### Core IDE Features
- LSP servers for 10+ programming languages
- Intelligent file manager with file filtering
- Telescope for fast file and text search
- Git integration with gitsigns
- Multi-functional terminal
- Automatic bracket and pair closing
- Smart comments for all languages
- Treesitter for accurate syntax highlighting
- Which-key for intuitive navigation
- Automatic formatting on save

## Quick Start - Essential Actions

### 1. Open File Tree
```
F9                    # Open file manager in modal window
<leader>ee            # Alternative way (<leader> = Space)

In file manager:
Enter                 # Open file in new tab or expand folder
f                     # Start filtering files by name
F                     # Clear file filter
q or Esc              # Close file manager
```

### 2. Open List of Open Buffers/Tabs
```
F8                    # Show list of all open tabs
<leader>et            # Alternative way

F10                   # Show buffers through Telescope
<leader>eb            # Show buffers through Telescope
<leader>fb            # Show buffers through Telescope

In tabs list:
Enter                 # Switch to selected tab
d                     # Close selected tab
q or Esc              # Close list
```

### 3. Navigate Between Tabs
```
Alt + Left / F5       # Previous tab
Alt + Right / F6      # Next tab
Alt + 1-9             # Go to tab number 1-9
Alt + h               # Move current tab left
Alt + l               # Move current tab right
```

### 4. Activate Python venv
```
<leader>vs            # Select Python virtual environment
:VenvSelect           # Command for manual venv selection

Automatic detection:
1. Checks VIRTUAL_ENV variable
2. Looks for .venv in current directory
3. Looks for venv in current directory
4. Uses system python3
```

### 5. Move Files in Subdirectory (nvim-tree)
```
F9                    # Open nvim-tree
x                     # Cut file
Navigate to destination folder
p                     # Paste file

Alternatively:
c                     # Copy file
p                     # Paste copy
```

### 6. Close File (and All Files)
```
<leader>qq            # Close current tab
<leader>qa            # Close all tabs and exit nvim
<leader>qQ            # Force close current tab (without saving)
<leader>qA            # Force close everything and exit
```

## Complete Key Bindings Reference

### Files and Navigation

| Keys         | Action                             |
| ------------ | ---------------------------------- |
| `F9`         | Open/close file manager            |
| `<leader>ee` | Open file manager                  |
| `<leader>ff` | Find files (Telescope)             |
| `<leader>fg` | Search text in project (Live Grep) |
| `<leader>fb` | List open buffers                  |
| `<leader>fh` | Help (Help tags)                   |
| `<leader>fs` | Document symbols                   |
| `<leader>fw` | Workspace symbols                  |

### Tabs

| Keys                 | Action                   |
| -------------------- | ------------------------ |
| `Alt + Left` / `F5`  | Previous tab             |
| `Alt + Right` / `F6` | Next tab                 |
| `Alt + 1-9`          | Go to tab 1-9            |
| `Alt + h`            | Move tab left            |
| `Alt + l`            | Move tab right           |
| `F8`                 | List all open tabs       |
| `<leader>et`         | List all open tabs       |
| `F10`                | List buffers (Telescope) |
| `<leader>eb`         | List buffers (Telescope) |
| `<leader>fb`         | List buffers (Telescope) |

### Terminal

| Keys         | Action                                     |
| ------------ | ------------------------------------------ |
| `Ctrl + \`   | Open/close floating terminal               |
| `<leader>tf` | Floating terminal                          |
| `<leader>th` | Horizontal terminal                        |
| `<leader>tv` | Vertical terminal (width 80)               |
| `<leader>tp` | Python terminal (with virtual environment) |
| `<leader>td` | Django shell                               |
| `<leader>tr` | Django runserver                           |
| `<leader>tn` | Node.js terminal                           |

### LSP (Language Server)

| Keys         | Action               |
| ------------ | -------------------- |
| `gd`         | Go to definition     |
| `gD`         | Go to declaration    |
| `gr`         | Show all references  |
| `gi`         | Go to implementation |
| `K`          | Show documentation   |
| `<C-k>`      | Signature help       |
| `<leader>ca` | Code actions         |
| `<leader>rn` | Rename symbol        |

### Formatting and Saving

| Keys         | Action                      |
| ------------ | --------------------------- |
| `F2`         | Smart save + formatting     |
| `<leader>f`  | Format current buffer       |
| `<leader>F`  | Format document             |
| `<leader>tf` | Toggle auto-format on save  |
| `<leader>is` | Sort Python imports (isort) |

### Diagnostics

| Keys        | Action                              |
| ----------- | ----------------------------------- |
| `]d`        | Next error/warning                  |
| `[d`        | Previous error/warning              |
| `<leader>d` | Show diagnostics in floating window |
| `<leader>q` | Open error list (quickfix)          |

### Editing

| Keys                | Action                                          |
| ------------------- | ----------------------------------------------- |
| `gcc`               | Comment/uncomment line                          |
| `gbc`               | Block comment                                   |
| `gcO`               | Comment above                                   |
| `gco`               | Comment below                                   |
| `gcA`               | Comment at end of line                          |
| `<` / `>`           | Decrease/increase indent (preserving selection) |
| `Alt + j/k`         | Move lines up/down                              |
| `J/K` (visual mode) | Move blocks up/down                             |

### Clipboard

| Keys         | Action                                            |
| ------------ | ------------------------------------------------- |
| `<leader>ya` | Copy entire buffer to clipboard                   |
| `<leader>yy` | Copy selection to clipboard (also in visual mode) |
| `<leader>yp` | Paste from clipboard (also in visual mode)        |

### Windows

| Keys             | Action                   |
| ---------------- | ------------------------ |
| `<C-h/j/k/l>`    | Navigate between windows |
| `<C-Up/Down>`    | Change window height     |
| `<C-Left/Right>` | Change window width      |

### Git

| Keys         | Action               |
| ------------ | -------------------- |
| `<leader>hs` | Stage hunk           |
| `<leader>hr` | Reset hunk changes   |
| `<leader>hp` | Preview hunk         |
| `<leader>hb` | Show blame for line  |
| `<leader>tb` | Toggle blame display |
| `<leader>hd` | Show diff            |
| `]c`         | Next hunk            |
| `[c`         | Previous hunk        |

### System and Others

| Keys         | Action                            |
| ------------ | --------------------------------- |
| `<leader>m`  | Open Mason (LSP manager)          |
| `<leader>vs` | Select Python virtual environment |
| `<leader>qq` | Close current tab                 |
| `<leader>qa` | Close all tabs and exit           |
| `<leader>qQ` | Force close current tab           |
| `<leader>qA` | Force close everything and exit   |
| `<leader>h`  | Clear search highlighting         |

## Supported Programming Languages

| Language                  | LSP Server | Formatter     | Features                         |
| ------------------------- | ---------- | ------------- | -------------------------------- |
| **Python**                | Pyright    | Black + isort | Django templates, venv detection |
| **JavaScript/TypeScript** | ts_ls      | Prettier      | Inlay hints, auto-import         |
| **Vue.js**                | vue_ls     | Prettier      | Single File Components           |
| **HTML**                  | html       | Prettier      | Django template support          |
| **CSS/SCSS**              | cssls      | Prettier      | Emmet integration                |
| **Go**                    | gopls      | goimports     | Automatic imports                |
| **C/C++**                 | clangd     | clang-format  | Background indexing              |
| **Lua**                   | lua_ls     | stylua        | Neovim API support               |
| **JSON**                  | jsonls     | Prettier      | Schema validation                |
| **YAML**                  | yamlls     | Prettier      | GitHub Actions, Docker Compose   |
| **Docker**                | dockerls   | -             | Dockerfile support               |
| **Bash**                  | bashls     | -             | Shell scripting                  |

## Project Structure

```
~/.config/nvim/
├── init.lua                              # Main configuration file
├── after/plugin/
│   └── nvimtree-autoclose.lua           # Auto-close empty tabs
└── lua/
    ├── config/
    │   ├── colorcolumn.lua              # Vertical line at 79 characters
    │   ├── keymaps.lua                  # Centralized key mappings
    │   ├── line-numbers.lua             # Smart line numbers
    │   └── nvim-tabs.lua                # Custom tabs with parent/filename
    └── plugins/
        ├── additional.lua               # Treesitter, Telescope, Git, Terminal
        ├── completion.lua               # nvim-cmp with LuaSnip
        ├── dashboard.lua                # Start screen
        ├── formatting.lua               # null-ls for formatting
        ├── lsp.lua                      # LSP configuration for all languages
        ├── mason.lua                    # LSP server manager
        ├── nvim-tree.lua               # File manager
        ├── tabs-list.lua               # Independent tabs list
        ├── theme.lua                    # Catppuccin theme
        └── which-key.lua               # Key bindings helper
```

## Configuration Features

### Smart Tabs
- Show parent/filename for better navigation
- Auto-close empty tabs with only NvimTree
- Preserve last tab with new empty file

### File Manager
- Modal floating window
- Live file filtering with `f` key
- Sync with current file
- Root directory management

### Automatic Python Environment Detection
1. Checks `VIRTUAL_ENV` variable
2. Looks for `.venv` in current directory
3. Looks for `venv` in current directory
4. Uses system `python3`

### Smart Line Numbers
- Hybrid in Normal mode (relative + current absolute)
- Absolute in Insert mode and when losing focus
- Hidden in special buffers (NvimTree, Dashboard)

### Optimized Diagnostics
- Muted colors for virtual text
- Single warning symbol (⚠) for all types
- Floating windows with rounded corners

## Django Development

### Templates
- Automatic recognition of `.html` files as Django templates
- Jinja2 syntax highlighting
- Emmet in Django templates

### Terminals
```bash
<leader>td   # python manage.py shell
<leader>tr   # python manage.py runserver
```

### Automatic Import Sorting
```bash
<leader>is   # isort --profile black --line-length 79
```

## Vue.js Development

- Full Single File Components support
- TypeScript in `<script setup lang="ts">`
- CSS/SCSS in `<style>` blocks
- Template highlighting and autocompletion

## Troubleshooting

### LSP Servers Won't Install
```bash
:Mason
# Select required server and press 'i' to install
```

### Python Environment Not Found
```bash
:VenvSelect  # Manually select venv
<leader>vs   # Alternative way
```

### Formatting Not Working
```bash
# In virtual environment
pip install black isort

# Check status
:lua print(vim.g.format_on_save)
<leader>tf  # Enable auto-formatting
```

### Telescope Can't Find Files
```bash
# Install ripgrep
sudo apt install ripgrep  # Ubuntu/Debian
brew install ripgrep      # macOS
```

### Fonts Not Displaying Correctly
- Ensure Nerd Font is installed
- Set one of the Nerd Font Mono fonts as terminal default
- Recommended: JetBrains Mono Nerd Font, Fira Code Nerd Font

### Slow which-key Performance
Configuration is optimized with:
- `delay = 100ms`
- `timeoutlen = 300ms`
- Disabled notifications

## Customization

### Change Theme
In `lua/plugins/theme.lua` modify:
```lua
flavour = "mocha", -- latte, frappe, macchiato, mocha
```

### Add New Languages
In `lua/plugins/lsp.lua` add new server:
```lua
new_server = {
  settings = { ... },
  root_markers = { ".git" },
}
```

### Configure Key Mappings
In `lua/config/keymaps.lua` add new mappings:
```lua
map("n", "<leader>xx", ":YourCommand<CR>", { desc = "Your description" })
```

### Change Tab Format
In `lua/config/nvim-tabs.lua` modify style in `tab_name()` function.

## Performance

- Lazy loading of plugins for fast startup
- Optimized autocmd groups
- Minimal interface delays
- Efficient memory usage

This configuration is designed for maximum productivity while maintaining all necessary IDE functionality.