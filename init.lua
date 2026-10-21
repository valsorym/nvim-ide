-- Core options must be ready before plugins register events or mappings.
if vim.fn.has("nvim-0.11.3") == 0 then
    error("Neovim IDE requires Neovim 0.11.3 or newer")
end
vim.loader.enable()
vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.opt.mouse = "a"
vim.opt.mousemodel = "extend"
vim.opt.clipboard = "unnamedplus"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 300
vim.opt.timeoutlen = 500
vim.opt.ttimeoutlen = 50
vim.opt.undofile = true
vim.opt.confirm = true
vim.opt.wildmode = { "longest:full", "full" }
vim.opt.list = true
vim.opt.listchars = { trail = "⋅", tab = "  ", extends = " ", precedes = " ", nbsp = " " }
vim.opt.fillchars:append({ eob = " " })
vim.opt.shortmess:append("F")
vim.g.format_on_save = vim.g.format_on_save == true

-- Keyboard positions: mac (і=b, и=s) or windows (і=s, и=b).
vim.g.nvim_ide_ukrainian_layout = vim.g.nvim_ide_ukrainian_layout
    or vim.env.NVIM_IDE_UKRAINIAN_LAYOUT or "mac"
require("config.langmap").setup()
require("config.performance").setup()
require("config.filetype-settings").setup()
require("config.filetype-settings").setup_commands()
require("config.line-numbers").setup()
require("config.highlights").setup()
require("config.floating-windows").setup()
require("config.nvim-tabs").setup()
require("config.python-venv").setup()
require("config.sessions").setup()
require("config.formatting").setup()
require("config.keymaps").setup()

-- Bootstrap once; ordinary starts use the installed plugin cache.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    local result = vim.fn.system({ "git", "clone", "--filter=blob:none",
        "--branch=stable", "https://github.com/folke/lazy.nvim.git", lazypath })
    if vim.v.shell_error ~= 0 then error("Cannot install lazy.nvim: " .. result) end
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup("plugins", {
    defaults = { lazy = true },
    rocks = { enabled = false },
    checker = { enabled = false },
    change_detection = { enabled = false, notify = false },
})
require("config.theme").setup()
