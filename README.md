# Neovim IDE - Tab-Focused Development Environment

## Overview

This Neovim configuration creates a modern IDE experience focused on **tab-based workflow** rather than traditional buffer management. This approach makes it more similar to contemporary IDEs like VSCode, IntelliJ IDEA, or Sublime Text, where each file opens in its own tab for easier navigation and organization.

## Key Philosophy: Tab-Centric Workflow

Unlike traditional Vim workflows that rely heavily on buffers, this configuration prioritizes tabs:

- **Files open in tabs** - Each file gets its own tab automatically
- **LSP navigation opens in tabs** - Go to definition, references, etc. open in new tabs
- **Telescope opens in tabs** - File search results open in tabs
- **Smart tab management** - Orphaned buffers are automatically cleaned up
- **Visual tab indicators** - Clear tab bar shows all open files

This makes the experience more intuitive for developers coming from modern IDEs while retaining Vim's powerful editing capabilities.

## Core Features

- **Language Server Protocol (LSP)** - Full IDE features for multiple languages
- **Tab-focused navigation** - All operations work with tabs, not buffers
- **Smart file explorer** - Modal file tree with tab integration
- **Advanced search** - Find files and text with tab results
- **Theme switcher** - Multiple beautiful themes with live preview
- **Terminal integration** - Built-in terminal with project awareness
- **Git integration** - Visual git status and operations
- **Linting/Formatting** - Configurable code quality tools

## Installation

### 1. Install Dependencies and Tools

Update system and install essential tools.

```bash
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
  ripgrep \
  codespell
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

**⚠️ IMPORTANT**: Set one of the Nerd Font Mono fonts as your terminal's default font for proper icon display.

### 3. Install Neovim

Remove old version.

```bash
sudo rm -f /usr/local/bin/nvim
sudo rm -rf /usr/local/share/nvim/
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
curl -LO https://github.com/neovim/neovim/releases/download/v0.11.4/nvim-linux-x86_64.tar.gz
tar xzvf nvim-linux-x86_64.tar.gz
sudo mv nvim-linux-x86_64 /opt/nvim
sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
```

Install for arm64.

```bash
curl -LO https://github.com/neovim/neovim/releases/download/v0.11.4/nvim-linux-arm64.tar.gz
tar xzvf nvim-linux-arm64.tar.gz
sudo mv nvim-linux-arm64 /opt/nvim
sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
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

Clear cache, and clone this repo.

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
rm -rf "$config_dir/.git"
nvim --headless "+Lazy! sync" "+qa"
echo -e "\n\nNeovim IDE installed successfully: $config_dir"
echo "Plugins will install automatically on first launch..."
' && nvim
```

On first launch, Neovim will automatically:
- Install all plugins through Lazy.nvim
- Download LSP servers through Mason
- Configure Treesitter parsers

## Neovide

### Update cargo.

```bash
sudo apt remove cargo rustc
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
rustup install stable
rustup default stable
```

### Install Neovide.

```bash
cargo install --git https://github.com/neovide/neovide
```

### Config Neovide.

```bash
mkdir -p ~/.config/neovide
cat <<'EOF' | install -Dm644 /dev/stdin ~/.config/neovide/config.toml
frame = "full"
idle = true
maximized = false
vsync = true
mouse-cursor-icon = "arrow"
no-multigrid = false
srgb = false
tabs = true
title-hidden = false
wsl = false

[font]
normal = ["JetBrainsMono Nerd Font", "monospace"]
size = 12.0
EOF
```

### Create a desktop entry for Neovide.

```bash
cat > ~/.local/share/applications/neovide.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Neovide
Comment=A simple, fast and good looking Neovim GUI
Exec=neovide %F
Icon=neovide
Terminal=false
Categories=Development;TextEditor;IDE;
StartupNotify=true
StartupWMClass=neovide
MimeType=text/plain;text/x-makefile;text/x-c++hdr;text/x-c++src;text/x-chdr;text/x-csrc;text/x-java;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;application/x-shellscript;text/x-c;text/x-c++;
Actions=NewWindow;

[Desktop Action NewWindow]
Name=New Window
Exec=neovide
OnlyShowIn=Cinnamon;GNOME;KDE;XFCE;Unity;
EOF

mkdir -p ~/.local/share/icons/hicolor/scalable/apps/
wget -O ~/.local/share/icons/hicolor/scalable/apps/neovide.svg \
  https://raw.githubusercontent.com/neovide/neovide/main/assets/neovide.svg

update-desktop-database ~/.local/share/applications/ >/dev/null 2>&1 || true
```

### Cinnamon

```bash
rm -rf ~/.cinnamon/spices.cache
rm -rf ~/.cache/cinnamon/
nohup cinnamon --replace >/dev/null 2>&1 &
```

## Language Support

### Python + Django
- **LSP**: Pyright for type checking and IntelliSense
- **Formatting**: Black (79 character limit)
- **Import sorting**: isort (Black-compatible)
- **Linting**: Optional Codespell for spell checking
- **Virtual environment**: Automatic detection (.venv, venv)
- **Django templates**: Support for .htmldjango files

### JavaScript/TypeScript
- **LSP**: ts_ls for full IDE features
- **Formatting**: Prettier (79 character limit)
- **Linting**: ESLint support (configurable)

### Vue.js
- **LSP**: Vue language server with TypeScript support
- **Formatting**: Prettier for templates and scripts

### HTML/CSS
- **LSP**: HTML and CSS language servers
- **Django templates**: Special support for .htmldjango files
- **Emmet**: Abbreviation expansion for HTML/CSS

### Other Languages
- **Go**: gopls with goimports formatting
- **C/C++**: clangd with LLVM style formatting
- **Lua**: lua_ls with Neovim-specific configuration
- **Docker**: Dockerfile language server
- **JSON/YAML**: Schema validation and formatting

## Practical Examples

### 📖 How to find text in current file
```bash
# Basic search in current file
/search_term              # Search forward
?search_term              # Search backward
n                         # Next occurrence
N                         # Previous occurrence
<leader>h                 # Clear highlighting
```

### 🔍 How to find text in all project files
```bash
<leader>fg                # Open Live Grep (search in all files)
# Type text to search and press Enter
# Results open in new tabs when pressing Enter
```

### 🎯 Search using regular expressions (Regex)
```bash
# In current file
/\v(pattern1|pattern2)    # Search multiple variants
/\cText                   # Case insensitive
/\<word\>                 # Whole words only
/^\s*function             # Lines starting with "function"
/\d{3}-\d{2}-\d{4}        # Search phone numbers

# In all files through Live Grep
<leader>fg
# Enter regex: class\s+\w+\(.*\):  # Find all Python classes
```

### ✏️ How to replace text in current file
```bash
:%s/old_text/new_text/g      # Replace all occurrences
:%s/old_text/new_text/gc     # Replace with confirmation
:%s/old_text/new_text/gi     # Ignore case

# In selected range
:1,10s/old/new/g             # Lines 1-10
:.,$s/old/new/g              # From current line to end
```

### 🔄 How to replace text in all files
```bash
# Method 1: Through Live Grep
<leader>fg                   # Find text in all files
# After getting results:
:cfdo %s/old/new/g | update  # Replace in all found files

# Method 2: Through specific files
:args **/*.py                # Select all Python files
:argdo %s/old/new/g | update # Replace in all selected files
```

### 🎨 Replace using regular expressions
```bash
# Replace with capture groups
:%s/\v(\w+)\s+(\w+)/\2 \1/g       # Swap words
:%s/\v(\d{4})-(\d{2})-(\d{2})/\3.\2.\1/g  # Date: 2024-12-25 → 25.12.2024

# Complex replacements
:%s/\v<(class|def)\s+(\w+)/\1 NEW_\2/g    # Add prefix to classes & functions
:%s/\vfunction\s+(\w+)\(/const \1 = (/g   # JS: function name() → const name = (
```

### 🌳 How to view file tree (Tree)
```bash
F9                        # Open file explorer
<leader>ee                # Alternative way

# In file tree:
hjkl or arrows            # Navigation
Enter                     # Open file/expand folder
f                         # Start filtering
F                         # Clear filter
H                         # Show/hide hidden files
r                         # Refresh tree
q or Esc                  # Close
```

### 📋 How to view active buffers (Buffers)
```bash
F10                       # List buffers through Telescope
<leader>eb                # Alternative way
<leader>fb                # Another option

# In buffer list:
hjkl or arrows            # Navigation
Enter                     # Open buffer in new tab
Ctrl+x                    # Delete buffer
```

### 📑 How to view active tabs (Tabs)
```bash
F8                        # Show list of all tabs
<leader>et                # Alternative way

# In tab list:
hjkl or arrows            # Navigation
Enter                     # Switch to tab
d                         # Close tab
q or Esc                  # Close list
```

### 🎯 How to navigate code (Code Definitions)
```bash
# Main navigation
gd                        # Go to definition (opens in new tab)
gD                        # Go to declaration
gi                        # Go to implementation
gr                        # Show all references (in quickfix)
K                         # Show documentation
Ctrl+k                    # Function signature

# Symbol navigation
F7                        # Show all symbols in file
<leader>ls                # Alternative way
<leader>lg                # Grouped symbols (by type)
<leader>fw                # Symbols in entire project
```

### 📁 File tree operations: create, delete, rename
```bash
# Open file tree
F9

# File and folder operations:
a                         # Create file (file.txt) or folder (folder/)
d                         # Delete selected file/folder
rn                        # Rename file/folder
c                         # Copy file/folder
x                         # Cut file/folder
p                         # Paste file/folder

# Directory navigation:
C                         # Change root to current working directory
R                         # Select new root directory
P                         # Go to parent directory
```

### ✂️ How to select text
```bash
# Basic selection
v                         # Character selection
V                         # Line selection
Ctrl+v                    # Block (column) selection

# Object selection
viw                       # Select word (inner word)
vaw                       # Select word with spaces (around word)
vip                       # Select paragraph
vi"                       # Select text in double quotes
vi'                       # Select text in single quotes
vi(, vi[, vi{             # Select text in brackets
```

### 📄 How to select entire file
```bash
ggVG                      # Classic Vim way
<leader>ya                # Copy entire file to system clipboard
Ctrl+a                    # Select all (in some modes)
```

### 📋 How to copy
```bash
# Copy to system clipboard
<leader>yy                # Copy selected text
<leader>ya                # Copy entire file
y                         # Copy to internal Vim buffer
yy                        # Copy current line
5yy                       # Copy 5 lines
```

### 📌 How to paste
```bash
# Paste from system clipboard
<leader>yp                # Paste from system clipboard
p                         # Paste after cursor (from Vim buffer)
P                         # Paste before cursor (from Vim buffer)

# In visual mode
# Select text, then <leader>yp - replaces selection
```

### 🚪 How to exit
```bash
# Smart exit (recommended)
<leader>qq                # Close current tab (goes to Dashboard if last)
<leader>qa                # Close all tabs and exit
<leader>qQ                # Force close tab without saving
<leader>qA                # Force close all without saving

# Classic Vim commands
:q                        # Quit (if no changes)
:q!                       # Quit without saving
:wq                       # Save and quit
:x                        # Save and quit (if changes exist)
```

### 💡 How to open hints (Which-Key)
```bash
<leader>                  # Press space and wait
# A window will appear with all available commands

# Navigate through hints:
<leader>e                 # Show Explorer commands
<leader>f                 # Show Find/Search commands
<leader>g                 # Show Git commands
<leader>k                 # Show Linter commands
<leader>t                 # Show Terminal commands
<leader>u                 # Show UI/Theme commands
<leader>q                 # Show Quit commands
```

### 🎨 How to temporarily change theme
```bash
<leader>ut                # Open theme switcher
# Navigate with arrows or type to filter
# Enter - apply theme temporarily (for current session only)
# Theme resets on Neovim restart
```

### 🎯 How to permanently change theme
```bash
<leader>us                # Open permanent theme setting menu
# Navigate and select theme
# Enter - apply and save theme forever
# Theme will load on every startup

<leader>ui                # Show current theme information
```

### 🔧 How to activate/deactivate linters
```bash
# Toggle linters
<leader>kc                # Toggle Codespell (spell checking)
<leader>kd                # Toggle djlint (Django templates)
<leader>ke                # Toggle ESLint (JavaScript)
<leader>kf                # Toggle Flake8 (Python)

# Check status
:PythonToolsStatus        # Show Python tools status
:CreatePyprojectToml      # Create Python configuration file
```

## 20 Additional Useful Examples

### 🚀 Quick Productivity
1. **Quick save with formatting**: `F2` - saves and formats code immediately
2. **Reload file**: `:e!` - reload file from disk
3. **Quick line jump**: `:line_number` or `numberG` - instant jump
4. **Center screen**: `zz` - center current line on screen
5. **Quick indent formatting**: In visual mode `=` - auto-indent

### 🔄 Working with tabs and files
6. **Clone tab**: `:tab split` - duplicate current file in new tab
7. **Move tabs**: `Alt+h` and `Alt+l` - move tab left/right
8. **Close all except current**: `:only` - keep only current tab
9. **Open file in vertical split**: `:vsplit filename`
10. **Jump to last position**: `Ctrl+o` - return to previous cursor position

### ✨ Text editing
11. **Move lines**: `Alt+j/k` - move selected lines up/down
12. **Duplicate line**: `yyp` - copy and paste current line
13. **Join lines**: `J` - join current line with next
14. **Replace character under cursor**: `r + new_character` - replace one character
15. **Delete to end of line**: `D` - delete from cursor to end of line

### 🎮 Advanced features
16. **Python terminal with venv**: `<leader>tp` - open Python REPL with active virtual environment
17. **Django shell**: `<leader>td` - launch Django management shell
18. **Sort Python imports**: `<leader>is` - automatically sort imports according to Black standard
19. **Navigate errors**: `]d` and `[d` - jump to next/previous diagnostic error
20. **Quick comment**: `gcc` - comment/uncomment current line

### 🔍 Bonus search tips
21. **Search word under cursor**: `*` - find next occurrence of word under cursor
22. **Search backwards**: `#` - find previous occurrence of word
23. **Incremental search**: `:set incsearch` - show results while typing
24. **Search in command history**: `:` then `Ctrl+p/n` - navigate command history
25. **Quick access to last search**: `/<Enter>` - repeat last search

### File and Project Navigation

#### File Tree Operations
| Action                 | Key                  | Description                         |
| ---------------------- | -------------------- | ----------------------------------- |
| **Open file explorer** | `F9` or `<leader>ee` | Open modal file tree                |
| **Navigate**           | Arrow keys or `hjkl` | Move through files                  |
| **Open file**          | `Enter`              | Open in new tab                     |
| **Create file/folder** | `a`                  | Add file (use ./ for folder)        |
| **Delete**             | `d`                  | Delete selected item                |
| **Rename**             | `rn`                 | Rename selected item                |
| **Copy**               | `c`                  | Copy selected item                  |
| **Cut**                | `x`                  | Cut selected item                   |
| **Paste**              | `p`                  | Paste item                          |
| **Change root**        | `C`                  | Change to current working directory |
| **Pick root**          | `R`                  | Choose custom root directory        |
| **Go to parent**       | `P`                  | Navigate to parent directory        |
| **Toggle hidden**      | `H`                  | Show/hide hidden files              |
| **Filter files**       | `f`                  | Start live filtering                |
| **Clear filter**       | `F`                  | Clear current filter                |
| **Refresh**            | `r`                  | Refresh file tree                   |
| **Close explorer**     | `Esc` or `q`         | Close file tree                     |

#### Active Buffers and Tabs
| Action                 | Key                         | Description           |
| ---------------------- | --------------------------- | --------------------- |
| **Show all buffers**   | `F10` or `<leader>eb`       | List all open buffers |
| **Show all tabs**      | `F8` or `<leader>et`        | List all open tabs    |
| **Navigate tabs**      | `Alt+Left/Right` or `F5/F6` | Switch between tabs   |
| **Go to specific tab** | `Alt+1` through `Alt+9`     | Jump to tab number    |
| **Move tab position**  | `Alt+h/l`                   | Move tab left/right   |
| **Create new tab**     | `Ctrl+t` or `<leader>tn`    | Open new empty tab    |

#### Code Navigation and Definitions
| Action                   | Key                  | Description                               |
| ------------------------ | -------------------- | ----------------------------------------- |
| **Go to definition**     | `gd`                 | Jump to definition (opens in new tab)     |
| **Go to declaration**    | `gD`                 | Jump to declaration (opens in new tab)    |
| **Go to implementation** | `gi`                 | Jump to implementation (opens in new tab) |
| **Show references**      | `gr`                 | Show all references (opens in quickfix)   |
| **Hover information**    | `K`                  | Show documentation popup                  |
| **Show symbols in file** | `F7` or `<leader>ls` | Browse document symbols                   |
| **Show symbols grouped** | `<leader>lg`         | Browse symbols by type                    |
| **Workspace symbols**    | `<leader>fw`         | Search symbols in project                 |
| **Signature help**       | `Ctrl+k`             | Show function signature                   |

### Text Selection and Clipboard

#### Text Selection
| Action                     | Key                             | Description           |
| -------------------------- | ------------------------------- | --------------------- |
| **Character selection**    | `v` + movement                  | Select characters     |
| **Line selection**         | `V` + movement                  | Select lines          |
| **Block selection**        | `Ctrl+v` + movement             | Select columns        |
| **Select entire file**     | `<leader>ya` or `ggVG`          | Select all content    |
| **Select word**            | `viw` (inner) or `vaw` (around) | Select word           |
| **Select paragraph**       | `vip`                           | Select paragraph      |
| **Select inside quotes**   | `vi"` or `vi'`                  | Select quoted text    |
| **Select inside brackets** | `vi(`, `vi[`, `vi{`             | Select bracketed text |

#### Copy and Paste Operations
| Action                   | Key          | Description                      |
| ------------------------ | ------------ | -------------------------------- |
| **Copy selection**       | `<leader>yy` | Copy to system clipboard         |
| **Copy entire file**     | `<leader>ya` | Copy all to system clipboard     |
| **Paste from clipboard** | `<leader>yp` | Paste from system clipboard      |
| **Paste in visual mode** | `<leader>yp` | Replace selection with clipboard |
| **Regular vim yank**     | `y`          | Copy to vim register             |
| **Regular vim paste**    | `p`          | Paste from vim register          |

### Application Control

#### Exit and Quit Operations
| Action                     | Key          | Description                           |
| -------------------------- | ------------ | ------------------------------------- |
| **Smart quit current tab** | `<leader>qq` | Close tab (goes to Dashboard if last) |
| **Force quit current tab** | `<leader>qQ` | Force close without saving            |
| **Quit all tabs**          | `<leader>qa` | Close all and exit                    |
| **Force quit all**         | `<leader>qA` | Force close all without saving        |

#### Help and Hints
| Action               | Key                | Description              |
| -------------------- | ------------------ | ------------------------ |
| **Open help system** | `<leader>`         | Wait for Which-Key popup |
| **Help for topic**   | `:help topic_name` | Open help documentation  |
| **LSP information**  | `:LspInfo`         | Show LSP server status   |
| **Plugin manager**   | `<leader>m`        | Open Mason (LSP manager) |

### Theme Management

#### Temporary Theme Change
| Action                  | Key          | Description                     |
| ----------------------- | ------------ | ------------------------------- |
| **Open theme switcher** | `<leader>ut` | Browse and preview themes       |
| **Apply temporarily**   | `Enter`      | Apply theme for current session |

#### Permanent Theme Change
| Action                  | Key          | Description            |
| ----------------------- | ------------ | ---------------------- |
| **Set permanent theme** | `<leader>us` | Choose and save theme  |
| **Check current theme** | `<leader>ui` | Show theme information |

### Linter Management

#### Toggle Linters
| Action                   | Key                    | Description                     |
| ------------------------ | ---------------------- | ------------------------------- |
| **Toggle Codespell**     | `<leader>kc`           | Spelling checker on/off         |
| **Toggle djlint**        | `<leader>kd`           | Django template linter on/off   |
| **Toggle ESLint**        | `<leader>ke`           | JavaScript linter (placeholder) |
| **Toggle Flake8**        | `<leader>kf`           | Python linter (placeholder)     |
| **Check tools status**   | `:PythonToolsStatus`   | Show available Python tools     |
| **Create Python config** | `:CreatePyprojectToml` | Generate pyproject.toml         |

## Complete Key Mappings Reference

### Function Keys
| Key   | Action                     |
| ----- | -------------------------- |
| `F2`  | Save and format file       |
| `F5`  | Previous tab               |
| `F6`  | Next tab                   |
| `F7`  | Document symbols inspector |
| `F8`  | Tabs list                  |
| `F9`  | File explorer (modal)      |
| `F10` | Buffers list               |

### Leader Key Combinations (`<leader>` = Space)

#### Explorer (`<leader>e`)
| Key  | Action        |
| ---- | ------------- |
| `ee` | File explorer |
| `eb` | Buffers list  |
| `et` | Tabs list     |

#### Find/Search (`<leader>f`)
| Key  | Action                      |
| ---- | --------------------------- |
| `ff` | Find files                  |
| `fg` | Live grep (search in files) |
| `fb` | Find buffers                |
| `fh` | Help tags                   |
| `fs` | Document symbols            |
| `fw` | Workspace symbols           |

#### Yank/Clipboard (`<leader>y`)
| Key  | Action                 |
| ---- | ---------------------- |
| `ya` | Yank all (entire file) |
| `yy` | Yank selection         |
| `yp` | Paste from clipboard   |

#### Buffers/Tabs (`<leader>b`)
| Key  | Action          |
| ---- | --------------- |
| `bb` | List buffers    |
| `bd` | Delete buffer   |
| `bn` | Next buffer     |
| `bp` | Previous buffer |

#### Git (`<leader>g`) / Hunk Operations (`<leader>h`)
| Key  | Action       |
| ---- | ------------ |
| `hs` | Stage hunk   |
| `hr` | Reset hunk   |
| `hp` | Preview hunk |
| `hb` | Blame line   |
| `hd` | Diff this    |

#### Code/LSP (`<leader>c`)
| Key  | Action        |
| ---- | ------------- |
| `ca` | Code action   |
| `rn` | Rename symbol |

#### Linters (`<leader>k`)
| Key  | Action           |
| ---- | ---------------- |
| `kc` | Toggle Codespell |
| `kd` | Toggle djlint    |
| `ke` | Toggle ESLint    |
| `kf` | Toggle Flake8    |

#### Diagnostics (`<leader>x`)
| Key  | Action                |
| ---- | --------------------- |
| `xx` | Show line diagnostics |
| `xl` | Open diagnostic list  |

#### Terminal/Tools (`<leader>t`)
| Key  | Action              |
| ---- | ------------------- |
| `tf` | Float terminal      |
| `th` | Horizontal terminal |
| `tv` | Vertical terminal   |
| `tp` | Python terminal     |
| `td` | Django shell        |
| `tn` | New tab             |

#### Quit (`<leader>q`)
| Key  | Action          |
| ---- | --------------- |
| `qq` | Smart close tab |
| `qa` | Close all tabs  |
| `qQ` | Force close tab |
| `qA` | Force close all |

#### UI/Themes (`<leader>u`)
| Key  | Action                     |
| ---- | -------------------------- |
| `ut` | Theme switcher (temporary) |
| `us` | Set permanent theme        |
| `ui` | Theme info                 |

#### LSP/Symbols (`<leader>l`)
| Key  | Action                     |
| ---- | -------------------------- |
| `ls` | Document symbols           |
| `lg` | Document symbols (grouped) |

### Alt Key Combinations
| Key              | Action               |
| ---------------- | -------------------- |
| `Alt+Left/Right` | Navigate tabs        |
| `Alt+1-9`        | Jump to specific tab |
| `Alt+h/l`        | Move tab left/right  |
| `Alt+j/k`        | Move lines up/down   |

### Special Keys
| Key            | Action                    |
| -------------- | ------------------------- |
| `Ctrl+t`       | New tab                   |
| `Ctrl+\`       | Toggle floating terminal  |
| `Ctrl+h/j/k/l` | Navigate windows          |
| `Esc`          | Close current modal/popup |

### LSP Navigation
| Key      | Action               |
| -------- | -------------------- |
| `gd`     | Go to definition     |
| `gD`     | Go to declaration    |
| `gi`     | Go to implementation |
| `gr`     | Show references      |
| `K`      | Hover documentation  |
| `Ctrl+k` | Signature help       |

### Diagnostics Navigation
| Key  | Action                |
| ---- | --------------------- |
| `]d` | Next diagnostic       |
| `[d` | Previous diagnostic   |
| `gl` | Show line diagnostics |

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

## Configuration Structure

```
~/.config/nvim/
├── lua/
│   ├── config/
│   │   ├── colorcolumn.lua    # 79-character guide
│   │   ├── keymaps.lua        # All key mappings
│   │   ├── line-numbers.lua   # Hybrid line numbers
│   │   └── nvim-tabs.lua      # Tab bar configuration
│   └── plugins/
│       ├── additional.lua     # Core plugins (Treesitter, Telescope)
│       ├── code-inspector.lua # Symbol browser
│       ├── completion.lua     # Autocompletion
│       ├── dashboard.lua      # Start screen
│       ├── footer.lua         # Status line
│       ├── formatting.lua     # Code formatting and linting
│       ├── lsp.lua           # Language servers
│       ├── mason.lua         # LSP installer
│       ├── nvim-tree.lua     # File explorer
│       ├── scroll.lua        # Scrollbar
│       ├── tabs-list.lua     # Tab management
│       ├── theme.lua         # Theme switcher
│       └── which-key.lua     # Key binding helper
└── .last_colorscheme         # Saved theme preference
```

## Quick Start Guide

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

### 2. Navigate Between Tabs
```
Alt + Left / F5       # Previous tab
Alt + Right / F6      # Next tab
Alt + 1-9             # Go to tab number 1-9
Alt + h               # Move current tab left
Alt + l               # Move current tab right
```

### 3. Search and Replace
```
<leader>fg            # Search text in all files
:%s/old/new/g         # Replace in current file
:cfdo %s/old/new/g | update  # Replace in all search results
```

### 4. Code Navigation
```
gd                    # Go to definition (opens in new tab)
gr                    # Show references
F7                    # Browse document symbols
<leader>ca            # Code actions
<leader>rn            # Rename symbol
```

### 5. Python Development
```
<leader>vs            # Select virtual environment
<leader>tp            # Python terminal with venv
<leader>td            # Django shell
<leader>is            # Sort Python imports
F2                    # Save and format with Black
```

## Django Development Features

### Templates
- Automatic recognition of `.html` files as Django templates
- Jinja2 syntax highlighting
- Emmet in Django templates

### Terminals
```
<leader>td            # python manage.py shell
<leader>tr            # python manage.py runserver
```

### Python Tools
```
<leader>is            # isort --profile black --line-length 79
:PythonToolsStatus    # Check available tools
:CreatePyprojectToml  # Create configuration file
```

## Troubleshooting

### LSP Servers Won't Install
```bash
:Mason
# Select required server and press 'i' to install
```

### Python Environment Not Found
```bash
:VenvSelect           # Manually select venv
<leader>vs            # Alternative way
```

### Formatting Not Working
```bash
# In virtual environment
pip install black isort

# Check status
:lua print(vim.g.format_on_save)
<leader>tf            # Toggle auto-formatting
```

### Telescope Can't Find Files
```bash
# Install ripgrep
sudo apt install ripgrep     # Ubuntu/Debian
brew install ripgrep         # macOS
```

### Fonts Not Displaying Correctly
- Ensure Nerd Font is installed
- Set Nerd Font Mono as terminal default
- Recommended: JetBrains Mono Nerd Font, Fira Code Nerd Font

## Performance Optimizations

- Lazy loading of plugins for fast startup
- Optimized autocmd groups to prevent conflicts
- Minimal interface delays (100ms which-key, 300ms timeout)
- Efficient memory usage with smart buffer cleanup
- Tab-focused workflow reduces buffer overhead

## Tips and Best Practices

1. **Embrace the tab workflow** - Let files open in tabs naturally
2. **Use Which-Key** - Press `<leader>` and explore available options
3. **Master F-keys** - F7-F10 provide instant access to panels
4. **Leverage LSP navigation** - Use `gd`, `gr`, `gi` for code exploration
5. **Experiment with themes** - Use `<leader>ut` to find your preference
6. **Configure linters gradually** - Enable tools as needed for projects
7. **Use modal file explorer** - `F9` for quick operations, `Esc` to close
8. **Combine search tools** - Use Telescope + quickfix for mass replacements
9. **Utilize terminal integration** - `Ctrl+\` for quick access
10. **Keep workspace clean** - Use `<leader>qq` for smart tab management

This configuration transforms Neovim into a powerful, modern IDE while maintaining the efficiency and flexibility that makes Vim exceptional. The tab-centric approach bridges the gap between traditional Vim workflows and contemporary IDE expectations.