-- Core Neovim options and settings

-- Leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- General settings
vim.opt.number = true           -- Show line numbers
vim.opt.relativenumber = true   -- Show relative line numbers
vim.opt.mouse = "a"             -- Enable mouse support
vim.opt.clipboard = "unnamedplus" -- Use system clipboard
vim.opt.wrap = false            -- Disable line wrapping
vim.opt.linebreak = true        -- Break lines at word boundaries
vim.opt.showbreak = "↳ "        -- String to put at the start of wrapped lines

-- Indentation
vim.opt.expandtab = true        -- Use spaces instead of tabs
vim.opt.shiftwidth = 2          -- Size of an indent
vim.opt.tabstop = 2             -- Number of spaces tabs count for
vim.opt.softtabstop = 2         -- Number of spaces tabs count for in insert mode
vim.opt.smartindent = true      -- Smart autoindenting

-- Search
vim.opt.ignorecase = true       -- Ignore case in search
vim.opt.smartcase = true        -- Override ignorecase if search contains uppercase
vim.opt.hlsearch = true         -- Highlight search results
vim.opt.incsearch = true        -- Show search results as you type

-- Visual
vim.opt.termguicolors = true    -- Enable 24-bit RGB colors
vim.opt.signcolumn = "yes"      -- Always show sign column
vim.opt.scrolloff = 8           -- Keep 8 lines above/below cursor
vim.opt.sidescrolloff = 8       -- Keep 8 columns left/right of cursor
vim.opt.cursorline = true       -- Highlight current line
vim.opt.splitbelow = true       -- Open new horizontal splits below
vim.opt.splitright = true       -- Open new vertical splits to the right

-- Files
vim.opt.backup = false          -- Don't create backup files
vim.opt.writebackup = false     -- Don't create backup files before writing
vim.opt.swapfile = false        -- Don't create swap files
vim.opt.undofile = true         -- Enable persistent undo
vim.opt.updatetime = 250        -- Faster completion
vim.opt.timeoutlen = 500        -- Faster key sequence completion

-- Performance
vim.opt.lazyredraw = true       -- Don't redraw while executing macros
vim.opt.synmaxcol = 240         -- Don't highlight long lines

-- Completion
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.pumheight = 10          -- Maximum number of entries in popup menu

-- Folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldenable = false      -- Don't fold by default

-- File encoding
vim.opt.fileencoding = "utf-8"
vim.opt.encoding = "utf-8"