# NeoVim IDE Configuration

Full-featured IDE configuration for Neovim with support for Python + Django, JavaScript/TypeScript, Vue.js, C/C++, Go, PlatformIO and other programming languages.

## Installation

### 1. Installing Dependencies and Tools

```bash
# System update and essential tools installation
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
  platformio
```

### 2. Installing Nerd Fonts

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

**⚠️ IMPORTANT**: Set one of the Nerd Font Mono as the default font in your terminal for proper icon display.

### 3. Installing NeoVim from Source

```bash
# Create temporary directory and clone repository
mkdir -p /tmp/neovim && cd /tmp/neovim && \
git clone https://github.com/neovim/neovim.git && \
cd neovim && \
git checkout stable && \
make CMAKE_BUILD_TYPE=Release && \
sudo make install
```

### 4. Installing Python Tools

```bash
# Global Python formatters installation
pip3 install black isort

# Or for specific project with virtual environment
python3 -m venv .venv
source .venv/bin/activate
pip install black isort django  # add other dependencies as needed
```

### 5. Installing PlatformIO Core

```bash
# Via pip (recommended method)
pip3 install platformio

# Or via homebrew (macOS)
brew install platformio

# Or via snap (Ubuntu)
sudo snap install --classic platformio

# Verify installation
pio --version
```

### 6. Installing NVim-IDE Configuration

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

On first Neovim launch, it will automatically:
- Install all plugins via Lazy.nvim
- Download LSP servers via Mason
- Configure Treesitter parsers

## Key Features

### Python + Django
- Automatic virtual environment detection (.venv, venv)
- Django template support (htmldjango, jinja2)
- Automatic import sorting with isort
- Code formatting with Black (79 characters per line)
- LSP support with Pyright
- Django management commands via terminal

### Web Development
- Full HTML/CSS/JavaScript/TypeScript support
- Vue.js with Vue Language Server
- CSS/JS in `<style>` and `<script>` blocks of HTML files
- Emmet for rapid HTML/CSS writing
- Prettier for formatting
- JSON schemas from SchemaStore

### PlatformIO - Embedded Development
- Automatic PlatformIO project detection (platformio.ini)
- LSP support for C/C++ with clangd
- Automatic `compile_commands.json` generation
- Support for popular boards: Arduino, ESP32/ESP8266, STM32, Raspberry Pi Pico
- Integration with PlatformIO terminal commands
- Fast code navigation with IntelliSense
- Syntax highlighting for Arduino sketches

#### Supported PlatformIO platforms:
- **Arduino**: Uno, Nano, Mega, Leonardo
- **ESP**: ESP32, ESP8266 (all variants)
- **STM32**: Bluepill, Nucleo, Discovery boards
- **Raspberry Pi**: Pico, Pico W
- **Teensy**: 3.x, 4.x series
- **AVR**: ATmega, ATtiny microcontrollers
- **ARM**: Cortex-M based MCUs
- **RISC-V**: CH32V, ESP32-C3/S3

### Core IDE Features
- LSP servers for 10+ programming languages
- Intelligent file manager with tab mode
- Telescope for fast file and text search
- Git integration with gitsigns
- Multi-functional terminal
- Automatic bracket and symbol pairing
- Smart comments for all languages
- Treesitter for precise syntax highlighting
- Which-key for intuitive navigation
- Automatic formatting on save

## Quick Start - Essential Actions

### 1. Open File Tree
```
F9                    # Open file manager in modal window
<leader>ee            # Alternative method (<leader> = Space)

In file manager:
Enter                 # Open file in new tab or expand folder
t                     # Switch between files and tabs mode
q or Esc              # Close file manager
```

### 2. Open List of Open Buffers/Tabs
```
F8                    # Show list of all open tabs
<leader>et            # Alternative method

F10                   # Show buffers via Telescope
<leader>eb            # Show buffers via Telescope
<leader>fb            # Show buffers via Telescope

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

### 5. PlatformIO Quick Start
```
<leader>pn            # Create new PlatformIO project
<leader>pb            # Build project
<leader>pu            # Upload to device
<leader>pm            # Open serial monitor
<leader>pf            # Build and upload (quick command)
```

### 6. Move Files to Subdirectory (nvim-tree)
```
F9                    # Open nvim-tree
x                     # Cut file
Navigate to destination folder
p                     # Paste file

Alternatively:
c                     # Copy file
p                     # Paste copy
```

### 7. Close File (and All Files)
```
<leader>qq            # Close current tab
<leader>qa            # Close all tabs and exit nvim
<leader>qQ            # Force close current tab (without saving)
<leader>qA            # Force close everything and exit
```

## Complete Key Bindings Reference

### Files and Navigation

| Keys | Action |
|------|--------|
| `F9` | Open/close file manager |
| `<leader>ee` | Open file manager |
| `<leader>ff` | Find files (Telescope) |
| `<leader>fg` | Search text in project (Live Grep) |
| `<leader>fb` | List open buffers |
| `<leader>fh` | Help tags |
| `<leader>fs` | Document symbols |
| `<leader>fw` | Workspace symbols |
| `<leader>fp` | Find projects (Telescope) |

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

**In file manager:**
- `t` - switch between files and tabs mode
- `Enter` - open file in new tab or go to existing one

### PlatformIO - Embedded Development

| Keys         | Action                                     |
| ------------ | ------------------------------------------ |
| `<leader>pb` | Build project (pio run)                    |
| `<leader>pu` | Upload to device (pio run --target upload) |
| `<leader>pm` | Serial monitor (pio device monitor)        |
| `<leader>pc` | Clean build (pio run --target clean)       |
| `<leader>pf` | Build and upload (quick command)           |
| `<leader>pt` | Run tests (pio test)                       |
| `<leader>pl` | List libraries (pio lib list)              |
| `<leader>pi` | Install library (pio lib install)          |
| `<leader>ps` | List devices (pio device list)             |
| `<leader>pn` | Create new project (interactive)           |
| `<leader>pg` | Generate compile_commands.json             |
| `<leader>po` | Open platformio.ini in new tab             |

### Terminal

| Keys | Action |
|------|--------|
| `Ctrl + \` | Open/close floating terminal |
| `<leader>tf` | Floating terminal |
| `<leader>th` | Horizontal terminal |
| `<leader>tv` | Vertical terminal (width 80) |
| `<leader>tp` | Python terminal (with virtual environment) |
| `<leader>td` | Django shell |
| `<leader>tr` | Django runserver |
| `<leader>tn` | Node.js terminal |

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

| Keys | Action |
|------|--------|
| `F2` | Smart save + formatting |
| `<leader>f` | Format current buffer |
| `<leader>F` | Format document |
| `<leader>tf` | Toggle auto-format on save |
| `<leader>is` | Sort Python imports (isort) |

### Diagnostics

| Keys         | Action                              |
| ------------ | ----------------------------------- |
| `]d`         | Next error/warning                  |
| `[d`         | Previous error/warning              |
| `<leader>xx` | Show diagnostics in floating window |
| `gl`         | Show diagnostics in floating window |
| `<leader>xl` | Open error list (quickfix)          |

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

| Keys | Action |
|------|--------|
| `<leader>ya` | Copy entire buffer to clipboard |
| `<leader>yy` | Copy selection to clipboard (also in visual mode) |
| `<leader>yp` | Paste from clipboard (also in visual mode) |

### Windows

| Keys             | Action                   |
| ---------------- | ------------------------ |
| `<C-h/j/k/l>`    | Navigate between windows |
| `<C-Up/Down>`    | Resize window height     |
| `<C-Left/Right>` | Resize window width      |

### Git

| Keys | Action |
|------|--------|
| `<leader>hs` | Stage hunk |
| `<leader>hr` | Reset hunk |
| `<leader>hp` | Preview hunk |
| `<leader>hb` | Show line blame |
| `<leader>tb` | Toggle blame display |
| `<leader>hd` | Show diff |
| `]c` | Next hunk |
| `[c` | Previous hunk |

### Themes and UI

| Keys         | Action                        |
| ------------ | ----------------------------- |
| `<leader>ut` | Theme switcher (preview)      |
| `<leader>us` | Set permanent theme           |
| `<leader>ui` | Current theme info            |
| `<leader>ud` | Show available themes (debug) |

### System and Others

| Keys | Action |
|------|--------|
| `<leader>m` | Open Mason (LSP manager) |
| `<leader>vs` | Select Python virtual environment |
| `<leader>qq` | Close current tab |
| `<leader>qa` | Close all tabs and exit |
| `<leader>qQ` | Force close current tab |
| `<leader>qA` | Force close everything and exit |
| `<leader>h` | Clear search highlights |

## Supported Programming Languages

| Language                  | LSP Server | Formatter     | Features                                  |
| ------------------------- | ---------- | ------------- | ----------------------------------------- |
| **Python**                | Pyright    | Black + isort | Django templates, venv detection          |
| **JavaScript/TypeScript** | ts_ls      | Prettier      | Inlay hints, auto-import                  |
| **Vue.js**                | vue_ls     | Prettier      | Single File Components                    |
| **HTML**                  | html       | Prettier      | Django template support                   |
| **CSS/SCSS**              | cssls      | Prettier      | Emmet integration                         |
| **C/C++**                 | clangd     | clang-format  | PlatformIO support, compile_commands.json |
| **Go**                    | gopls      | goimports     | Automatic imports                         |
| **Lua**                   | lua_ls     | stylua        | Neovim API support                        |
| **JSON**                  | jsonls     | Prettier      | Schema validation                         |
| **YAML**                  | yamlls     | Prettier      | GitHub Actions, Docker Compose            |
| **Docker**                | dockerls   | -             | Dockerfile support                        |
| **Bash**                  | bashls     | -             | Shell scripting                           |

## PlatformIO Workflow

### 1. Creating New Project
```bash
<leader>pn          # Interactive project creation
# Choose project name and board from list

# Available popular boards:
arduino-uno         # Arduino Uno
arduino-nano        # Arduino Nano
arduino-mega        # Arduino Mega
esp32dev           # ESP32 Development Board
esp8266            # ESP8266 (NodeMCU, Wemos D1)
bluepill_f103c8    # STM32 Blue Pill
nucleo_f401re      # STM32 Nucleo
raspberry-pi-pico  # Raspberry Pi Pico
```

### 2. Development and Debugging
```bash
<leader>po          # Open platformio.ini for configuration
<leader>pg          # Generate compile_commands.json for LSP
<leader>pb          # Build project
<leader>pu          # Upload to device
<leader>pm          # Open serial monitor
<leader>pf          # Build and upload (quick command)
```

### 3. Library Management
```bash
<leader>pl          # Show installed libraries
<leader>pi          # Install new library
<leader>ps          # Show connected devices
```

### 4. Testing
```bash
<leader>pt          # Run unit tests
<leader>pc          # Clean build (when having issues)
```

## Example PlatformIO Project Structure

```
my_arduino_project/
├── platformio.ini              # Project configuration
├── src/
│   └── main.cpp               # Main program code
├── include/
│   └── README                 # Header files
├── lib/
│   └── README                 # Private libraries
├── test/
│   └── README                 # Unit tests
└── .pio/                      # Build and cache (auto-generated)
    ├── build/
    │   └── compile_commands.json  # For LSP support
    └── libdeps/
```

### Example platformio.ini:
```ini
[env:uno]
platform = atmelavr
board = uno
framework = arduino
monitor_speed = 9600
lib_deps =
    arduino-libraries/Servo@^1.1.8
    adafruit/Adafruit NeoPixel@^1.10.7

[env:esp32]
platform = espressif32
board = esp32dev
framework = arduino
monitor_speed = 115200
lib_deps =
    bblanchon/ArduinoJson@^6.19.4
    knolleary/PubSubClient@^2.8
```

## Project Structure

```
~/.config/nvim/
├── init.lua                              # Main configuration file
├── after/plugin/
│   └── nvimtree-autoclose.lua           # Auto-close empty tabs
└── lua/
    ├── config/
    │   ├── colorcolumn.lua              # Vertical line at 79 characters
    │   ├── keymaps.lua                  # Centralized key bindings
    │   ├── line-numbers.lua             # Smart line numbers
    │   └── nvim-tabs.lua                # Custom tabs with parent/filename
    └── plugins/
        ├── additional.lua               # Treesitter, Telescope, Git, Terminal
        ├── completion.lua               # nvim-cmp with LuaSnip
        ├── dashboard.lua                # Start screen
        ├── footer.lua                   # Status line (lualine)
        ├── formatting.lua               # null-ls for formatting
        ├── lsp.lua                      # LSP configuration for all languages
        ├── mason.lua                    # LSP server manager
        ├── nvim-tree.lua               # File manager with tab mode
        ├── platformio.lua              # PlatformIO integration
        ├── scroll.lua                   # Scrollbar with indicators
        ├── tabs-list.lua               # Independent tab list
        ├── theme.lua                    # Multi-theme support with switcher
        └── which-key.lua               # Key bindings help
```

## Configuration Features

### Smart Tabs
- Show parent/filename for better navigation
- Automatic closure of empty tabs with only NvimTree
- Preserve last tab with new empty file

### File Manager with Two Modes
- **Files**: standard file tree view
- **Tabs**: list of all open tabs
- Switch with `t` key

### Automatic Environment Detection
**Python:**
1. Checks `VIRTUAL_ENV` variable
2. Looks for `.venv` in current directory
3. Looks for `venv` in current directory
4. Uses system `python3`

**PlatformIO:**
1. Detects `platformio.ini` in project root
2. Automatically generates `compile_commands.json`
3. Configures clangd to work with `.pio/build`
4. Connects specific terminal commands

### Multi-Theme Support
- Catppuccin (Mocha, Latte, Frappe, Macchiato)
- Tokyo Night (Night, Storm, Moon, Day)
- Gruvbox Material
- Kanagawa (Wave, Dragon, Lotus)
- Nord
- One Dark
- Telescope switcher with preview
- Theme persistence between sessions

### Smart Line Numbers
- Hybrid in Normal mode (relative + current absolute)
- Absolute in Insert mode and when losing focus
- Hidden in special buffers (NvimTree, Dashboard)

### Optimized Diagnostics
- Muted colors for virtual text
- Special icons for different message types (☣ ⚠ 💡 ℹ)
- Floating windows with rounded corners
- Scrollbar indicators for file errors

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

### LSP Servers Not Installing
```bash
:Mason
# Select needed server and press 'i' to install
```

### Python Environment Not Found
```bash
:VenvSelect  # Manually select venv
<leader>vs   # Alternative method
```

### PlatformIO Projects Not Recognized
```bash
# Make sure platformio.ini file exists
ls platformio.ini

# Generate compile_commands.json for LSP
<leader>pg
# or
pio run --target compiledb

# Restart LSP server
:LspRestart
```

### Formatting Not Working
```bash
# In virtual environment
pip install black isort

# For C/C++ (PlatformIO)
sudo apt install clang-format

# Check status
:lua print(vim.g.format_on_save)
<leader>tf  # Enable auto-formatting
```

### Telescope Not Finding Files
```bash
# Install ripgrep
sudo apt install ripgrep  # Ubuntu/Debian
brew install ripgrep      # macOS

# For PlatformIO files (.cpp, .h in src/)
<leader>ff  # Telescope finds all files
```

### PlatformIO Commands Not Working
```bash
# Check PlatformIO installation
pio --version

# Install globally
pip3 install platformio

# Add to PATH (if needed)
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
source ~/.bashrc
```

### Fonts Not Displaying Correctly
- Make sure Nerd Font is installed
- Set one of Nerd Font Mono as default terminal font
- Recommended: JetBrains Mono Nerd Font, Fira Code Nerd Font

### Slow which-key Performance
Configuration optimized with:
- `delay = 100ms`
- `timeoutlen = 300ms`
- Disabled notifications

### clangd Issues in PlatformIO
```bash
# Generate compile_commands.json
cd /path/to/your/platformio/project
pio run --target compiledb

# Check if file was created
ls .pio/build/compile_commands.json

# Restart LSP
:LspRestart
```

## Customization

### Changing Theme
```bash
<leader>ut              # Theme preview
<leader>us              # Set permanent theme
```

Or manually in `lua/plugins/theme.lua`:
```lua
flavour = "mocha", -- latte, frappe, macchiato, mocha
```

### Adding New Languages
In `lua/plugins/lsp.lua` add new server:
```lua
new_server = {
  settings = { ... },
  root_markers = { ".git" },
}
```

### Configuring Key Bindings
In `lua/config/keymaps.lua` add new mappings:
```lua
map("n", "<leader>xx", ":YourCommand<CR>", { desc = "Your description" })
```

### PlatformIO Configuration for New Boards
In `lua/plugins/platformio.lua` add new board to list:
```lua
-- In project initialization function
"your-custom-board",
```

### Changing Tab Format
In `lua/config/nvim-tabs.lua` modify style in `tab_name()` function.

### Adding New PlatformIO Commands
In `lua/config/keymaps.lua`:
```lua
map("n", "<leader>px", ":TermExec cmd='pio run --target clean'<CR>",
    {desc = "PlatformIO: Custom command"})
```

## Additional Tips

### PlatformIO Best Practices
1. **Code Organization**: Use `lib/` for custom libraries
2. **Versioning**: Specify exact library versions in `platformio.ini`
3. **Testing**: Create unit tests in `test/` folder
4. **Documentation**: Comment code for better LSP experience

### Performance Optimization
- Use `.pio/` in `.gitignore`
- Regularly clean builds: `<leader>pc`
- Generate `compile_commands.json` after dependency changes: `<leader>pg`

### Git Integration
```bash
# .gitignore for PlatformIO projects
.pio/
.vscode/
*.tmp
*.bak
```

### Working with Large Projects
1. Use `<leader>fs` for symbol navigation
2. `<leader>fw` for workspace-wide search
3. `gr` to find all function usages
4. `gd` for quick definition jumping

## Performance

- Lazy loading plugins for fast startup
- Optimized autocmd groups
- Minimal interface delays
- Efficient memory usage
- Special optimization for PlatformIO projects
- Automatic LSP metadata generation
- Scrollbar with error indicators for quick navigation

## Community Support

This configuration is designed for maximum productivity while maintaining all necessary IDE functionality. It supports both web development (Python/Django, JavaScript/Vue.js) and embedded development (PlatformIO, Arduino, ESP32).

### Useful Resources
- [PlatformIO Documentation](https://docs.platformio.org/)
- [Arduino Reference](https://www.arduino.cc/reference/en/)
- [ESP32 Documentation](https://docs.espressif.com/projects/esp-idf/en/latest/)
- [Neovim LSP Configuration](https://neovim.io/doc/user/lsp.html)

This configuration transforms Neovim into a full-featured IDE that competes with VSCode and integrated development environments, while remaining fast and efficient.