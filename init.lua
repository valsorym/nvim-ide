-- ~/.config/nvim/init.lua
-- Main NeoVim configuration file

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

-- Basic settings.
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.termguicolors = true

-- Set linter toggles before plugins load.
vim.g.enable_mypy = false    -- start with mypy OFF
vim.g.enable_djlint = false  -- start with djlint OFF

-- Local configs.
require("config.nvim-tabs").setup()
require("config.keymaps").setup()
require("config.line-numbers").setup()
require("config.colorcolumn").setup()
