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
require("lazy").setup("plugins", {
    rocks = {
        enabled = true,
        hererocks = true,
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
vim.g.enable_mypy      = false
vim.g.enable_djlint    = false
vim.g.enable_codespell = true
vim.g.enable_eslint    = false
vim.g.enable_flake8    = false

-- Trailing spaces.
vim.opt.list = true
vim.opt.listchars = {
    trail = "⋅",
    tab = "  ",
    extends = " ",
    precedes = " ",
    nbsp = " ",
}

-- -- Debug: track who changes wrap option
-- vim.api.nvim_create_autocmd("OptionSet", {
--     pattern = "wrap",
--     callback = function()
--         local trace = debug.traceback("", 2)
--         print("!!! WRAP CHANGED to " .. tostring(vim.wo.wrap))
--         print(trace)
--     end
-- })

-- Local configs.
require("config.langmap").setup()
require("config.nvim-tabs").setup()
require("config.keymaps").setup()
require("config.line-numbers").setup()

require("config.filetype-settings").setup()
require("config.filetype-settings").setup_commands()
require("config.filetype-settings").setup_keymaps()

require("config.auto-reload").setup()
require("config.tabs-list").setup()