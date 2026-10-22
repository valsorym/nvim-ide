-- Core options must be ready before plugins register events or mappings.
if vim.fn.has("nvim-0.11.3") == 0 then
    error("Neovim IDE requires Neovim 0.11.3 or newer")
end
-- This configuration uses Lua plugins; language servers run as separate processes.
local enabled_providers = vim.g.nvim_ide_enabled_providers or {}
for _, provider in ipairs({ "python3", "perl", "ruby", "node" }) do
    local name = "loaded_" .. provider .. "_provider"
    if not enabled_providers[provider] and vim.g[name] == nil then vim.g[name] = 0 end
end
vim.loader.enable()
-- Tool discovery does not require loading Mason's registry on the first file.
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. (vim.env.PATH or "")
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
    local lockpath = vim.fn.stdpath("config") .. "/lazy-lock.json"
    if vim.fn.filereadable(lockpath) == 1 then
        local lock = vim.json.decode(table.concat(vim.fn.readfile(lockpath), "\n"))
        local revision = lock["lazy.nvim"] and lock["lazy.nvim"].commit
        if revision then
            local checked = vim.fn.system({ "git", "-C", lazypath, "checkout", "--detach", revision })
            if vim.v.shell_error ~= 0 then error("Cannot restore lazy.nvim revision: " .. checked) end
        end
    end
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup("plugins", {
    defaults = { lazy = true },
    rocks = { enabled = false },
    checker = { enabled = false },
    change_detection = { enabled = false, notify = false },
})
require("config.theme").setup()
