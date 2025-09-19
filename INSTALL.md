# NVim-IDE Installation and Usage

## Quick Start

1. **Install Neovim** (>= 0.9.0)
2. **Clone this configuration:**
   ```bash
   git clone https://github.com/valsorym/nvim-ide.git ~/.config/nvim
   ```
3. **Launch Neovim:** `nvim`
4. **Wait for automatic setup** to complete

## Language Setup Guide

### Python Development
```bash
# Install Python development tools
pip install black isort flake8 mypy
pip install debugpy  # For debugging support
```

### Go Development  
```bash
# Install Go tools (handled automatically by vim-go)
go install golang.org/x/tools/gopls@latest
go install github.com/go-delve/delve/cmd/dlv@latest
```

### C/C++ Development
```bash
# Install clang and related tools
sudo apt install clang clang-format clang-tidy
# or on macOS
brew install llvm
```

### Node.js/TypeScript Development
```bash
# Install language servers
npm install -g typescript typescript-language-server
npm install -g prettier eslint
```

### Shell/Bash Development
```bash
# Install shellcheck and shfmt
sudo apt install shellcheck
go install mvdan.cc/sh/v3/cmd/shfmt@latest
```

## Directory Structure

```
~/.config/nvim/
├── init.lua                 # Main configuration entry point
├── lua/
│   ├── config/             # Core Neovim configuration
│   │   ├── options.lua     # Neovim options and settings
│   │   ├── keymaps.lua     # Key mappings
│   │   └── autocmds.lua    # Auto commands and events
│   └── plugins/            # Plugin configurations
│       ├── colorscheme.lua # Theme configuration
│       ├── treesitter.lua  # Syntax highlighting
│       ├── lsp.lua         # Language server setup
│       ├── completion.lua  # Auto-completion
│       ├── telescope.lua   # Fuzzy finder
│       ├── nvim-tree.lua   # File explorer
│       ├── git.lua         # Git integration
│       ├── terminal.lua    # Terminal integration
│       ├── ui.lua          # UI enhancements
│       ├── coding.lua      # Coding utilities
│       ├── languages.lua   # Language-specific configs
│       └── lualine.lua     # Status line
└── README.md               # Documentation
```

## Key Features by Language

### Python
- ✅ LSP with Pyright
- ✅ Django template support
- ✅ Tornado template support
- ✅ Virtual environment integration
- ✅ Auto-formatting with Black
- ✅ Import sorting with isort
- ✅ Debugging with debugpy
- ✅ Type checking
- ✅ Linting integration

### Go
- ✅ LSP with gopls
- ✅ Auto-formatting and imports
- ✅ Test running and coverage
- ✅ Debugging with Delve
- ✅ Module management
- ✅ Build tag support
- ✅ Struct tag generation

### C/C++
- ✅ LSP with clangd
- ✅ Header/source switching
- ✅ Auto-formatting with clang-format
- ✅ Static analysis with clang-tidy
- ✅ Debugging with GDB/LLDB
- ✅ CMake integration
- ✅ Compile commands support

### JavaScript/TypeScript
- ✅ LSP with tsserver
- ✅ Auto-formatting with Prettier
- ✅ Linting with ESLint
- ✅ React/JSX support
- ✅ Import organization
- ✅ Debugging with Node.js
- ✅ Package.json management

### Web Technologies
- ✅ HTML with Emmet support
- ✅ CSS/SCSS with language server
- ✅ Auto-completion and validation
- ✅ Color highlighting
- ✅ Live preview capabilities
- ✅ Template engine support

### Shell/Bash
- ✅ LSP with bash-language-server
- ✅ Syntax validation with shellcheck
- ✅ Auto-formatting with shfmt
- ✅ Script execution
- ✅ Environment variable support