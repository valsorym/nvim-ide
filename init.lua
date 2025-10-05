-- ~/.config/nvim/init.lua
-- Main NeoVim configuration file.

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system(
        {
            "git",
            "clone",
            "--filter=blob:none",
            "https://github.com/folke/lazy.nvim.git",
            "--branch=stable",
            lazypath
        }
    )
end
vim.opt.rtp:prepend(lazypath)

-- Leader keys.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load plugins.
require("lazy").setup("plugins")

vim.filetype.add({
    extension = {
        html = "htmldjango", -- all HTML files to use htmldjango filetype.
    },
})

-- Basic settings.
vim.opt.number         = true
vim.opt.relativenumber = false
vim.opt.expandtab      = true
vim.opt.shiftwidth     = 2
vim.opt.tabstop        = 2
vim.opt.smartindent    = true
vim.opt.wrap           = false
vim.opt.ignorecase     = true
vim.opt.smartcase      = true
vim.opt.termguicolors  = true

-- Linters toggles.
vim.g.enable_mypy      = false -- MyPy (Python type checker)
vim.g.enable_djlint    = false -- djlint (Django/Jinja linter)
vim.g.enable_codespell = true  -- spelling (safe default)
vim.g.enable_eslint    = false -- example: ESLint (if you add it)
vim.g.enable_flake8    = false -- example: Flake8 (if you add it)

-- Single column for git/LSP signs
-- %s - sign column (git signs, LSP diagnostics)
-- %l - absolute line number
-- %C - fold column (іконки ⌄ »)
vim.opt.signcolumn = "yes"
vim.opt.statuscolumn = "%s%l %C"


-- Trailing spaces.
vim.opt.list = true
vim.opt.listchars = {
    trail = "⋅",
    -- tab = "→ ",
    -- extends = "»",
    -- precedes = "«",
    -- nbsp = "␣",
}

-- Local configs.
require("config.nvim-tabs").setup()
require("config.keymaps").setup()
require("config.line-numbers").setup()
require("config.colorcolumn").setup()

require("config.indentation").setup()
require("config.indentation").setup_commands()
require("config.indentation").setup_keymaps()

require("config.auto-reload").setup()