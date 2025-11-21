# Neovim IDE - Professional Tab-Focused Development Environment

## Overview

This Neovim configuration creates a modern IDE experience focused on **tab-based workflow** rather than traditional buffer management. This approach makes it more similar to contemporary IDEs like VSCode, IntelliJ IDEA, or Sublime Text, where each file opens in its own tab for easier navigation and organization.

## Key Philosophy: Tab-Centric Workflow

Unlike traditional Vim workflows that rely heavily on buffers, this configuration prioritizes tabs:

- **Files open in tabs** - Each file gets its own tab automatically
- **LSP navigation opens in tabs** - Go to definition, references, etc. open in new tabs
- **Telescope opens in tabs** - File search results open in tabs
- **Smart tab management** - Orphaned buffers are automatically cleaned up
- **Visual tab indicators** - Clear tab bar shows all open files

## Core Features

- **Language Server Protocol (LSP)** - Full IDE features for multiple languages
- **Centralized hotkey system** - All commands through Legendary with Ukrainian layout support
- **Smart file explorer** - Modal file tree with tab integration
- **Advanced search** - Find files and text with tab results
- **Theme switcher** - Multiple beautiful themes with live preview
- **Terminal integration** - Built-in terminal with project awareness
- **Git integration** - Visual git status and operations
- **Minimal auto-startup** - Linters and formatters run manually
- **Grouped hotkey system** - Logical organization of commands

## Installation

### 1. Install Dependencies and Tools

Update system and install essential tools.

```bash
sudo apt remove -y npm;
sudo apt autoremove -y;

sudo apt update && \
sudo apt install -y \
  nodejs \
  npm \
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
  python3-pip \
  ripgrep \
  codespell \
  libssl-dev \
  libfreetype6-dev \
  libfontconfig1-dev \
  libxcb-shape0-dev \
  libxcb-xfixes0-dev \
  libxkbcommon-dev \
  libxkbcommon-x11-dev \
  libegl1-mesa-dev
```

### 2. Install Nerd Fonts

Download and install popular Nerd Fonts.

```bash
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

**⚠️ IMPORTANT**: Set one of the `UbuntuMono Nerd Font Mono` fonts as your terminal's default font for proper icon display.

### 3. Install Neovim

Remove old version.

```bash
sudo apt remove neovim
sudo rm -f /usr/bin/nvim
sudo rm -f /usr/local/bin/nvim
sudo rm -rf /usr/local/share/nvim/
sudo rm -rf /opt/nvim-linux-x86_64
sudo rm -rf /opt/nvim-linux-arm64
sudo rm -rf /opt/nvim
```

Clear cache.

```bash
rm -rf ~/.local/share/nvim/
rm -rf ~/.local/state/nvim/
```

Temporary directory.

```bash
mkdir -p /tmp/nvim
cd /tmp/nvim
```

Install for x86_64.

```bash
curl -LO https://github.com/neovim/neovim/releases/download/v0.11.5/nvim-linux-x86_64.tar.gz
tar xzvf nvim-linux-x86_64.tar.gz
sudo mv nvim-linux-x86_64 /opt/nvim
sudo ln -sf /opt/nvim/bin/nvim /usr/bin/nvim
hash -r
```

Install for arm64.

```bash
curl -LO https://github.com/neovim/neovim/releases/download/v0.11.5/nvim-linux-arm64.tar.gz
tar xzvf nvim-linux-arm64.tar.gz
sudo mv nvim-linux-arm64 /opt/nvim
sudo ln -sf /opt/nvim/bin/nvim /usr/bin/nvim
hash -r
```

Check version.

```bash
nvim --version | head -n 5
```

```txt
NVIM v0.11.5
Build type: Release
LuaJIT 2.1.1741730670
Run "nvim -V1 -v" for more info
```

### 4. Install Python Tools

Global Python formatter installation.

```bash
pip3 install black isort mypy
```

Or for specific project with virtual environment.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install black isort django mypy # add other dependencies as needed
```

### 5. Install Neovim IDE Configuration

Clear cache and clone this repo.

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
echo -e "\n\nCloning Neovim IDE..."
git clone --depth 1 https://github.com/valsorym/nvim-ide "$config_dir"
# rm -rf "$config_dir/.git"
nvim --headless "+Lazy! sync" "+qa"
echo -e "\n\nNeovim IDE installed successfully: $config_dir"
echo "Plugins will install automatically on first launch..."
' && nvim
```

On first launch, Neovim will automatically:
- Install all plugins through Lazy.nvim
- Download LSP servers through Mason
- Configure Treesitter parsers

### 6. Set NVim as Default

Set NVim as default editor.

```bash
sudo update-alternatives --install /usr/bin/vim vim /usr/local/bin/nvim 60
sudo update-alternatives --install /usr/bin/vi vi /usr/local/bin/nvim 60
sudo update-alternatives --install /usr/bin/editor editor /usr/local/bin/nvim 60
```

## Copilot

### Update NodeJS

Remove form ~/.bashrc

```bash
#export NVM_DIR="$HOME/.nvm"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
```

And reload: `source ~/.bashrc`

Remove old version of the Node.

```bash
sudo apt -y remove --purge nodejs npm
sudo apt autoremove
sudo apt autoclean

sudo rm -rf /usr/local/lib/node_modules
sudo rm -rf ~/.npm
sudo rm -rf ~/.node-gyp
rm -rf ~/.nvm

sudo rm -f /usr/local/bin/node
sudo rm -f /usr/local/bin/npm
sudo rm -f /usr/local/bin/npx

sudo rm -f /etc/apt/sources.list.d/nodesource.list
sudo rm -f /etc/apt/sources.list.d/nodejs.list
sudo apt update
```

Install new Node version.

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
```

Test version.

```bash
node --version
npm --version
which node
```

And test version and path in NVim.

```bash
:lua print(vim.fn.system("node --version"))
:lua print(vim.fn.system("which node"))
```

### Copilot auth

Open in browser: https://github.com/login/device

In NVim press: `<leader>coa`

```
First copy your one-time code: E3A1-56C9
Press ENTER to open GitHub in your browser
```

Enter the code in your browser and click "Authorize Plugin".

### Daily Usage

```bash
<leader>coo          # Toggle Copilot on/off
<leader>cos          # Check Copilot status
<leader>cox          # Sign out of Copilot
```

### While Coding (when enabled)

```bash
# In Insert Mode:
Ctrl+J               # Accept suggestion
Ctrl+H               # Dismiss suggestion
Ctrl+N               # Next suggestion
Ctrl+P               # Previous suggestion
```

## Hotkey System and Commands

### Centralized Command System

The entire configuration uses **Legendary** for centralized command management with Ukrainian layout support.

#### Main Command Menu
```bash
<Space>               # Main menu (or <leader>)
<leader><leader>      # Search all commands
<leader>?             # Browse by groups
<leader>:             # Search commands
```

#### Command Groups (`<leader>` + letter)
- **`<leader>t`** - 📑 **Tabs** (tab management)
- **`<leader>w`** - 🏢 **Workspaces** (sessions and workspaces)
- **`<leader>f`** - 🔍 **Find/Search** (search and replace)
- **`<leader>e`** - 📁 **Explorer** (files and buffers)
- **`<leader>c`** - 💻 **Code/LSP** (code and LSP operations)
- **`<leader>x`** - ⚙️ **System** (system and settings)
- **`<leader>g`** - 🔀 **Git** (Git operations)
- **`<leader>y`** - 📋 **Yank** (clipboard)
- **`<leader>u`** - 🎨 **UI/Themes** (interface and themes)
- **`<leader>d`** - 📝 **Document** (formatting)
- **`<leader>a`** - 🗺️ **Aerial** (code navigation)
- **`<leader>s`** - 🔎 **Search** (advanced search)

### Function Keys
```bash
F2    # Save and format
F5    # Previous tab
F6    # Next tab
F7    # Code Inspector (document symbols)
F8    # Tabs list
F9    # File explorer
F10   # Buffers list
```

### Tab Navigation
```bash
Alt+Left/Right        # Previous/next tab
Alt+1..9             # Go to tab 1-9
Alt+h/l              # Move tab left/right
Ctrl+t               # New tab
```

### Core Navigation Hotkeys
```bash
gd                   # Go to definition (in new tab)
gD                   # Go to declaration
gi                   # Go to implementation
gr                   # Show references
K                    # Documentation under cursor
Ctrl+k               # Function signature
```

## Language Support

### 🐍 Python Development

#### Virtual Environments
```bash
<leader>cva          # Activate venv
<leader>cvd          # Deactivate venv
<leader>cvs          # Venv status
<leader>cvf          # Find venv
<leader>cvc          # Select venv
```

#### Code Formatting
```bash
<leader>df           # Combined formatting (isort + black)
<leader>ci           # Sort imports (isort)
<leader>cb           # Black formatting
F2                   # Save + format
```

#### Python Terminals
```bash
<leader>xtp          # Python REPL with active venv
<leader>xtd          # Django shell (if manage.py exists)
```

#### Diagnostics and Tools
```bash
<leader>ca           # Code Actions
<leader>cr           # Rename symbol
<leader>cc           # Line diagnostics
<leader>cC           # Project diagnostics
```

#### Python Configuration
```bash
:PythonToolsStatus   # Python tools status
:CreatePyprojectToml # Create pyproject.toml
:CreatePyrightConfig # Create pyrightconfig.json
```

#### Linters (manual trigger)
```bash
<leader>cks          # Python tools status
<leader>ckp          # Create pyproject.toml
<leader>ckr          # Create pyrightconfig.json
```

### 🚀 Go Development

#### Formatting and Organization
```bash
<leader>df           # Format with goimports
F2                   # Save + auto-format
```

#### Go-specific Commands
```bash
gd                   # Go to definition
gi                   # Go to interface
<leader>ca           # Code Actions (add imports, etc.)
```

#### Go Tools
```bash
:GoMod tidy          # Clean go.mod (via LSP)
```

### 🌐 HTML/CSS Development

#### Template Support
- **HTML**: Full HTML5 support with Emmet
- **Django Templates**: Automatic recognition of `.html` files as Django templates
- **CSS/SCSS**: Full support with autocompletion

#### Formatting
```bash
<leader>df           # Format via Prettier
F2                   # Save + format
```

#### Emmet Expansion
```bash
# In HTML files
div.container>ul>li*3    # Expands to HTML structure
Ctrl+y,              # Activate Emmet (if configured)
```

#### Rendering
```bash
<leader>dr           # Toggle rendering (Markdown/RST)
```

### 🔧 JavaScript/TypeScript

#### Formatting and Linting
```bash
<leader>df           # Format via Prettier
<leader>cke          # Toggle ESLint (placeholder)
```

#### TypeScript Specific
```bash
<leader>ca           # Code Actions
<leader>cr           # Rename
K                    # Hover info with types
```

## Linter and Formatter System

### ⚠️ Important: Minimal Auto-startup

This configuration uses **minimal auto-startup** linters to preserve performance. Most tools run **manually** via hotkeys.

#### Automatic Actions
- Format on save: `F2` or `:w`
- Clean trailing spaces: automatically on save
- LSP diagnostics: real-time

#### Manual Linter Triggers
```bash
<leader>ckc          # Toggle Codespell (spell checking)
<leader>ckd          # Toggle djlint (Django templates)
<leader>cke          # Toggle ESLint (JavaScript)
<leader>ckf          # Toggle Flake8 (Python)
```

## File and Project Management

### File Explorer (F9)
```bash
F9 or <leader>ee     # Open file explorer

# In explorer:
Enter                # Open file/folder
a                    # Create file/folder
d                    # Delete
rn                   # Rename
c                    # Copy
x                    # Cut
p                    # Paste
f                    # Filter files
F                    # Clear filter
H                    # Show/hide hidden files
r                    # Refresh
q or Esc             # Close
```

### Find Files and Text
```bash
<leader>ff           # Find files
<leader>fg           # Live grep (search in text)
<leader>fG           # Search including ignored files
<leader>fb           # Find buffers
<leader>fo           # Recent files
<leader>fd           # Document symbols
```

### Text Replacement
```bash
<leader>fc           # Find & replace via Telescope
<leader>fC           # Find & replace (including ignored)
<leader>fx           # Replace current word

# In current file
:%s/old/new/g        # Replace all
:%s/old/new/gc       # Replace with confirmation
```

## Theme Management

### Temporary Theme Change
```bash
<leader>ut           # Open theme switcher
# Navigate with arrows, Enter to apply
# Theme only lasts until restart
```

### Permanent Theme Change
```bash
<leader>us           # Set permanent theme
# Select theme and press Enter
# Theme saves forever

<leader>ui           # Current theme information
```

## Tab Management

### Smart Tab Closing
```bash
<leader>tq           # Smart close (returns to Dashboard if last)
<leader>tc           # Close all saved tabs
<leader>tQ           # Force close without saving
<leader>tA           # Close all and exit
ZZ                   # Save and smart close tab
```

### Creation and Navigation
```bash
<leader>tn           # New tab
Ctrl+t               # Alternative new tab
<leader>tO           # Close other tabs
```

## Terminals and Tools

### Built-in Terminal
```bash
<leader>xtf          # Floating terminal
<leader>xth          # Horizontal terminal
<leader>xtv          # Vertical terminal
Ctrl+\               # Quick terminal access
```

### Specialized Terminals
```bash
<leader>xtp          # Python REPL with venv
<leader>xtn          # Node.js REPL
```

## Git Integration

### Git Hunk Operations
```bash
<leader>gs           # Stage hunk
<leader>gr           # Reset hunk
<leader>gp           # Preview hunk
<leader>gb           # Blame line
<leader>gd           # Diff current file
<leader>gt           # Toggle blame
```

### Git Change Navigation
```bash
]c                   # Next Git hunk
[c                   # Previous Git hunk
```

## Advanced Features

### Code Analysis and Navigation
```bash
F7                   # Code Inspector (all file symbols)
<leader>cs           # Document symbols
<leader>cg           # Document symbols (grouped)
<leader>cw           # Workspace symbols
<leader>af           # Aerial symbols
```

### TODO Comments
```bash
<leader>st           # Find TODO comments
<leader>sT           # Find TODO/FIX/FIXME
]t                   # Next TODO
[t                   # Previous TODO
```

### Document Formatting
```bash
<leader>df           # Format document (language-specific)
<leader>dr           # Toggle rendering (Markdown/RST)

# Indentation settings
<leader>ds2          # 2 spaces
<leader>ds4          # 4 spaces
<leader>dst          # Toggle tabs ↔ spaces

# ColorColumn
<leader>dc0          # Toggle ColorColumn
<leader>dc1          # ColorColumn at 79 characters
<leader>dc2          # ColorColumn at 120 characters
```

### Clipboard
```bash
<leader>ya           # Copy entire file
<leader>yy           # Copy selection
<leader>yp           # Paste from system clipboard
```

## Settings and System

### Configuration
```bash
<leader>xr           # Reload configuration
<leader>xm           # Mason (LSP server management)
<leader>xu           # Undotree (change history)
<leader>xf           # Toggle auto-format on save
```

### Diagnostics and Errors
```bash
]d                   # Next diagnostic
[d                   # Previous diagnostic
<leader>cc           # Line diagnostics
<leader>cC           # Project diagnostics
<leader>cl           # Diagnostic list
<leader>cq           # Quickfix list
```

## Configuration Structure

```
~/.config/nvim/
├── lua/
│   ├── config/
│   │   ├── keymaps.lua        # All base hotkeys
│   │   ├── safe-save.lua      # Safe file saving
│   │   └── langmap-helper.lua # Ukrainian layout support
│   └── plugins/
│       ├── legendary.lua      # Centralized command system
│       ├── additional.lua     # Core plugins
│       ├── lsp.lua           # Language servers
│       ├── mason.lua         # LSP installer
│       ├── formatting.lua    # Formatting and linting
│       ├── nvim-tree.lua     # File explorer
│       ├── telescope.lua     # Search and navigation
│       ├── theme.lua         # Theme system
│       └── dashboard.lua     # Start screen
└── .last_colorscheme         # Saved theme
```

## Quick Start Guide

### 1. Open File Explorer
```bash
F9                   # Open file manager
<leader>ee           # Alternative way
```

### 2. Navigate Between Tabs
```bash
Alt + Left / F5      # Previous tab
Alt + Right / F6     # Next tab
Alt + 1-9            # Go to tab number 1-9
```

### 3. Search and Replace
```bash
<leader>fg           # Search text in all files
:%s/old/new/g        # Replace in current file
```

### 4. Code Navigation
```bash
gd                   # Go to definition
gr                   # Show references
F7                   # Browse document symbols
<leader>ca           # Code actions
```

### 5. Python Development
```bash
<leader>cvc          # Select virtual environment
<leader>xtp          # Python terminal with venv
<leader>df           # Format (isort + black)
F2                   # Save and format
```

## Tips and Best Practices

1. **Master the tab system** - Let files open in tabs naturally
2. **Use Legendary** - Press `<Space>` and explore available options
3. **Master F-keys** - F7-F10 provide instant access to panels
4. **Use LSP navigation** - Use `gd`, `gr`, `gi` for code exploration
5. **Experiment with themes** - Use `<leader>ut` to find your preference
6. **Configure linters gradually** - Enable tools as needed for projects
7. **Use modal file explorer** - `F9` for quick operations, `Esc` to close
8. **Combine search tools** - Use Telescope + quickfix for mass replacements
9. **Utilize terminal integration** - `Ctrl+\` for quick access
10. **Keep workspace clean** - Use `<leader>tq` for smart tab management

This configuration transforms Neovim into a powerful, modern IDE while maintaining the efficiency and flexibility that makes Vim exceptional. The tab-centric approach bridges the gap between traditional Vim workflows and contemporary IDE expectations.