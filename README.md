# NVim-IDE

A comprehensive Neovim configuration designed for developers working with multiple programming languages and technologies. This configuration provides a complete IDE experience with modern features, language support, and productivity enhancements.

## 🚀 Features

### Language Support
- **Shell/Bash** - Complete shell scripting support with syntax highlighting and LSP
- **C/C++** - Full development environment with Clang integration
- **Go** - Comprehensive Go development with automatic formatting and tools
- **Python** - Django and Tornado template support, virtual environment integration
- **CSS/SCSS** - Advanced styling support with Emmet integration
- **HTML** - Full HTML development with template engine support
- **JavaScript/JSON** - Modern JS development with TypeScript support
- **TypeScript** - Complete TypeScript development environment

### IDE Features
- 🎨 **Beautiful UI** - Modern colorscheme with customizable themes
- 🔍 **Fuzzy Finding** - Fast file and content search with Telescope
- 📁 **File Explorer** - Integrated file tree with Git integration
- 💻 **Terminal Integration** - Built-in terminal with floating windows
- 🔧 **LSP Support** - Language Server Protocol for all supported languages
- ✨ **Auto-completion** - Intelligent code completion with snippets
- 🐛 **Debugging** - Integrated debugging support with DAP
- 🌳 **Syntax Highlighting** - Advanced syntax highlighting with Treesitter
- 📝 **Code Formatting** - Automatic code formatting on save
- 🔀 **Git Integration** - Full Git workflow integration
- 📚 **Documentation** - Hover documentation and signature help

## 📋 Requirements

- **Neovim** >= 0.9.0
- **Git** >= 2.19.0
- **Node.js** >= 14.0.0 (for LSP servers)
- **Python** >= 3.6 (for Python development)
- **Go** >= 1.19 (for Go development)
- **GCC/Clang** (for C/C++ development)
- **Make** (for building certain plugins)

### Optional Dependencies
- **ripgrep** - Enhanced grep searching
- **fd** - Fast file finding
- **lazygit** - Git UI integration
- **fzf** - Additional fuzzy finding

## 🛠 Installation

### 1. Backup Existing Configuration
```bash
# Backup your existing Neovim configuration
mv ~/.config/nvim ~/.config/nvim.backup
mv ~/.local/share/nvim ~/.local/share/nvim.backup
mv ~/.local/state/nvim ~/.local/state/nvim.backup
mv ~/.cache/nvim ~/.cache/nvim.backup
```

### 2. Clone NVim-IDE
```bash
git clone https://github.com/valsorym/nvim-ide.git ~/.config/nvim
```

### 3. Install Dependencies

#### On Ubuntu/Debian:
```bash
sudo apt update
sudo apt install -y neovim git nodejs npm python3 python3-pip golang-go build-essential ripgrep fd-find
```

#### On macOS:
```bash
brew install neovim git node python go ripgrep fd lazygit
```

#### On Arch Linux:
```bash
sudo pacman -S neovim git nodejs npm python python-pip go gcc ripgrep fd lazygit
```

### 4. First Launch
1. Open Neovim: `nvim`
2. The plugin manager (lazy.nvim) will automatically install
3. Plugins will be downloaded and installed automatically
4. LSP servers will be installed via Mason
5. Restart Neovim after initial setup

## 📖 Usage Guide

### 🎯 Key Mappings

#### General Navigation
- `<Space>` - Leader key
- `<C-h/j/k/l>` - Navigate between splits
- `<S-h/l>` - Navigate between buffers
- `<Alt-j/k>` - Move lines up/down
- `<Esc>` - Clear search highlight

#### File Operations
- `<Leader>ff` - Find files
- `<Leader>fg` - Live grep (search in files)
- `<Leader>fb` - Browse buffers
- `<Leader>fr` - Recent files
- `<Leader>e` - Toggle file explorer
- `<Leader>o` - Focus file explorer

#### Code Navigation
- `gd` - Go to definition
- `gr` - Find references
- `gi` - Go to implementation
- `K` - Hover documentation
- `<Leader>ca` - Code actions
- `<Leader>rn` - Rename symbol
- `<Leader>f` - Format code

#### Git Integration
- `<Leader>gs` - Git status
- `<Leader>gc` - Git commit
- `<Leader>gd` - Git diff
- `<Leader>gb` - Git blame
- `<Leader>gg` - LazyGit (if installed)
- `]h` / `[h` - Next/previous git hunk
- `<Leader>ghs` - Stage hunk
- `<Leader>ghr` - Reset hunk

#### Terminal
- `<C-\>` - Toggle floating terminal
- `<Leader>tt` - Toggle terminal
- `<Leader>tf` - Float terminal
- `<Leader>th` - Horizontal terminal
- `<Leader>tv` - Vertical terminal
- `<Leader>tp` - Python REPL
- `<Leader>tn` - Node.js REPL

#### Debugging
- `<Leader>db` - Toggle breakpoint
- `<Leader>dc` - Continue
- `<Leader>di` - Step into
- `<Leader>do` - Step out
- `<Leader>dO` - Step over
- `<Leader>dr` - Toggle REPL

### 🔧 Language-Specific Features

#### Python Development
- Django template syntax highlighting
- Tornado template support
- Virtual environment detection
- Automatic imports organization
- PEP8 compliant formatting
- Python REPL integration

#### Go Development
- Automatic imports and formatting
- Go-specific tools integration
- Test running capabilities
- Module management
- Performance profiling support

#### C/C++ Development
- Clang-based language server
- Header/source switching (`<Leader>ch`)
- Automatic formatting with Google style
- Build system integration
- Debugging support

#### Web Development
- Emmet support for HTML/CSS
- Auto-completion for web technologies
- CSS/SCSS compilation
- JavaScript/TypeScript support
- JSON schema validation
- Package.json management

#### Shell/Bash
- Advanced shell script support
- Syntax validation
- Shellcheck integration
- Formatting with shfmt

## ⚙️ Configuration

### Customizing Settings
The configuration is modular and can be customized by editing files in:
- `lua/config/` - Core Neovim settings
- `lua/plugins/` - Plugin configurations

### Adding Language Support
To add support for a new language:
1. Install the language server via Mason (`:Mason`)
2. Add configuration in `lua/plugins/lsp.lua`
3. Add formatting rules in `lua/plugins/languages.lua`
4. Install Treesitter parser (`:TSInstall <language>`)

### Theme Customization
Change the colorscheme by modifying `lua/plugins/colorscheme.lua`:
```lua
vim.cmd.colorscheme("tokyonight") -- or kanagawa, etc.
```

## 🔧 Troubleshooting

### Common Issues

#### LSP Not Working
1. Check if the language server is installed: `:Mason`
2. Verify LSP is attached: `:LspInfo`
3. Check for errors: `:checkhealth`

#### Slow Startup
1. Run `:Lazy profile` to identify slow plugins
2. Consider lazy-loading more plugins
3. Update plugins: `:Lazy update`

#### Treesitter Errors
1. Update parsers: `:TSUpdate`
2. Check health: `:checkhealth nvim-treesitter`

#### Terminal Issues
1. Ensure shell is properly configured
2. Check terminal emulator compatibility
3. Verify key mappings in your terminal

### Getting Help
- `:help` - Neovim documentation
- `:Lazy` - Plugin manager interface
- `:Mason` - LSP server management
- `:checkhealth` - System diagnostics
- `:WhichKey` - Key mapping reference

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

This configuration is built on the shoulders of giants:
- [lazy.nvim](https://github.com/folke/lazy.nvim) - Plugin manager
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) - LSP configurations
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) - Syntax highlighting
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - Fuzzy finder
- [catppuccin](https://github.com/catppuccin/nvim) - Beautiful colorscheme
- And many other amazing plugins and their maintainers

---

**Happy Coding! 🚀**
