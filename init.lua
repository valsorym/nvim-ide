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


-- Preserve original notify.
local original_notify = vim.notify

---@diagnostic disable-next-line: duplicate-set-field
vim.notify = function(msg, level, opts)
  if type(msg) ~= "string" then
    return original_notify(msg, level, opts)
  end

  -- Common noisy or redundant messages to ignore.
  local ignored_patterns = {
    "no matching language servers",
    "request textdocument/formatting failed", -- lowercase for consistency
    "the only change was a new completion item",
    "warning: multiple different client offset_encodings",
  }

  local msg_lower = msg:lower()
  for _, pattern in ipairs(ignored_patterns) do
    if msg_lower:find(pattern, 1, true) then
      return
    end
  end

  return original_notify(msg, level, opts)
end


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
require("config.highlights").setup()
require("config.floating-windows").setup()

-- Python virtual environment support.
require("config.python-venv").setup({
    auto_activate = true,
    notify = true,
    python_files_only = false,
    search_levels = 3,
})


vim.notify(" 🇺🇦 Glory to Ukraine!", vim.log.levels.INFO)