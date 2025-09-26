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

-- Trailing spaces.
vim.opt.list = true
vim.opt.listchars = {
    trail = "⋅",
    -- tab = "→ ",
    -- extends = "»",
    -- precedes = "«",
    -- nbsp = "␣",
}


-- Neovide
if vim.g.neovide then
    -- Keep window size between runs.
    vim.g.neovide_remember_window_size = true

    -- HiDPI tuning.
    vim.g.neovide_scale_factor = 1.0

    -- Disable cursor/scroll animations that "fly" across splits.
    vim.g.neovide_cursor_animation_length = 0
    vim.g.neovide_cursor_trail_length = 0
    vim.g.neovide_cursor_animate_in_insert_mode = false
    vim.g.neovide_scroll_animation_length = 0

    -- Optional cosmetics.
    vim.g.neovide_hide_mouse_when_typing = true
    vim.g.neovide_padding_top = 10
    vim.g.neovide_padding_bottom = 10
    vim.g.neovide_padding_left = 10
    vim.g.neovide_padding_right = 10
end


-- Local configs.
require("config.nvim-tabs").setup()
require("config.keymaps").setup()
require("config.line-numbers").setup()
require("config.colorcolumn").setup()

require("config.indentation").setup()
require("config.indentation").setup_commands()
require("config.indentation").setup_keymaps()

require("config.auto-reload").setup()

