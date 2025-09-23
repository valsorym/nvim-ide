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

-- Temporary fix for deprecated API calls in plugins
-- Monkey patch deprecated functions to avoid warnings
if vim.lsp.buf_get_clients then
    -- Redirect old function to new one
    vim.lsp.buf_get_clients = function(bufnr)
        return vim.lsp.get_clients({ bufnr = bufnr })
    end
end

-- Suppress specific deprecation warnings during plugin initialization
local original_notify = vim.notify
local suppress_until = 0

local function should_suppress_warning(msg)
    if type(msg) ~= "string" then return false end

    local suppress_patterns = {
        "vim%.lsp%.buf_get_clients.*is deprecated",
        "vim%.validate is deprecated",
        "buf_get_clients.*deprecated"
    }

    for _, pattern in ipairs(suppress_patterns) do
        if msg:match(pattern) then
            return true
        end
    end
    return false
end

vim.notify = function(msg, level, opts)
    if should_suppress_warning(msg) and vim.loop.now() < suppress_until then
        return
    end
    original_notify(msg, level, opts)
end

-- Set suppression period (first 5 seconds after startup)
vim.defer_fn(function()
    suppress_until = vim.loop.now() + 5000
end, 100)

-- Leader keys.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load plugins with new additions
require("lazy").setup({
    spec = {
        { import = "plugins" }
    },
    defaults = {
        lazy = false,
        version = false,
    },
    install = {
        colorscheme = { "catppuccin" },
    },
    checker = {
        enabled = true,
        notify = false,
    },
    change_detection = {
        notify = false,
    },
    ui = {
        border = "rounded",
        size = {
            width = 0.8,
            height = 0.8,
        },
    },
    performance = {
        rtp = {
            disabled_plugins = {
                "gzip",
                "tarPlugin",
                "tohtml",
                "tutor",
                "zipPlugin",
            },
        },
    },
})

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

-- Linters toggles.
vim.g.enable_mypy     = false  -- MyPy (Python type checker)
vim.g.enable_djlint   = false  -- djlint (Django/Jinja linter)
vim.g.enable_codespell = true   -- spelling (safe default)
vim.g.enable_eslint    = false  -- example: ESLint (if you add it)
vim.g.enable_flake8    = false  -- example: Flake8 (if you add it)

-- Project and debug status indicators
vim.g.project_type = nil
vim.g.format_on_save = true

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

-- Additional vim options for better experience (set after plugins load)
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 300
vim.opt.timeoutlen = 300
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.pumheight = 10
vim.opt.conceallevel = 0
vim.opt.fileencoding = "utf-8"
vim.opt.hlsearch = true
vim.opt.mouse = "a"
vim.opt.showmode = false
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.writebackup = false
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

-- Disable some default plugins for performance
local disabled_built_ins = {
    "netrw",
    "netrwPlugin",
    "netrwSettings",
    "netrwFileHandlers",
    "gzip",
    "zip",
    "zipPlugin",
    "tar",
    "tarPlugin",
    "getscript",
    "getscriptPlugin",
    "vimball",
    "vimballPlugin",
    "2html_plugin",
    "logipat",
    "rrhelper",
    "spellfile_plugin",
    "matchit"
}

for _, plugin in pairs(disabled_built_ins) do
    vim.g["loaded_" .. plugin] = 1
end

-- Auto-commands for better user experience
local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })

-- Restore original notify after plugins are loaded
vim.api.nvim_create_autocmd("User", {
    pattern = "LazyDone",
    callback = function()
        vim.defer_fn(function()
            vim.notify = original_notify
        end, 1000) -- Wait 1 second after lazy is done
    end,
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
    group = augroup,
    pattern = "*",
    callback = function()
        vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
    end,
})

-- Auto-resize splits when Vim itself is resized
vim.api.nvim_create_autocmd("VimResized", {
    group = augroup,
    pattern = "*",
    command = "wincmd =",
})

-- Close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = {
        "qf",
        "help",
        "man",
        "lspinfo",
        "spectre_panel",
        "startuptime",
        "checkhealth",
        "trouble",
        "dapui_watches",
        "dapui_breakpoints",
        "dapui_scopes",
        "dapui_console",
        "dapui_stacks",
        "dap-repl",
    },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
    end,
})

-- Project detection and setup
vim.api.nvim_create_autocmd("VimEnter", {
    group = augroup,
    callback = function()
        vim.defer_fn(function()
            local ok, project_utils = pcall(require, "project_nvim.utils")
            if ok then
                local root = project_utils.get_project_root()
                if root then
                    -- Set project type for status indicators
                    if vim.fn.filereadable(root .. "/manage.py") == 1 then
                        vim.g.project_type = "django"
                    elseif vim.fn.filereadable(root .. "/setup.py") == 1 or
                           vim.fn.filereadable(root .. "/pyproject.toml") == 1 then
                        vim.g.project_type = "python"
                    elseif vim.fn.filereadable(root .. "/package.json") == 1 then
                        vim.g.project_type = "nodejs"
                    elseif vim.fn.filereadable(root .. "/Cargo.toml") == 1 then
                        vim.g.project_type = "rust"
                    elseif vim.fn.filereadable(root .. "/go.mod") == 1 then
                        vim.g.project_type = "go"
                    end
                end
            end
        end, 500)
    end
})

-- Custom user commands
vim.api.nvim_create_user_command('ReloadConfig', function()
    -- Clear module cache
    for name, _ in pairs(package.loaded) do
        if name:match('^config') or name:match('^plugins') then
            package.loaded[name] = nil
        end
    end

    -- Reload configuration
    dofile(vim.env.MYVIMRC)
    vim.notify("Configuration reloaded!", vim.log.levels.INFO)
end, { desc = "Reload Neovim configuration" })

vim.api.nvim_create_user_command('ConfigEdit', function()
    vim.cmd('edit ' .. vim.fn.stdpath('config') .. '/init.lua')
end, { desc = "Edit Neovim configuration" })

vim.api.nvim_create_user_command('DevStatus', function()
    local current = vim.g.colors_name or "none"
    local project = vim.g.project_type or "none"
    local formatters = vim.g.format_on_save and "ON" or "OFF"
    local lsp_clients = vim.lsp.get_clients({ bufnr = 0 })
    local lsp_names = {}

    for _, client in pairs(lsp_clients) do
        table.insert(lsp_names, client.name)
    end

    print("=== Development Status ===")
    print("Theme: " .. current)
    print("Project type: " .. project)
    print("Format on save: " .. formatters)
    print("LSP clients: " .. table.concat(lsp_names, ", "))
    print("Working directory: " .. vim.fn.getcwd())

    -- DAP status
    local dap_ok, dap = pcall(require, "dap")
    if dap_ok then
        local session = dap.session()
        if session then
            print("Debug session: ACTIVE")
        else
            print("Debug session: INACTIVE")
        end
    end

    -- Plugin status
    local lazy_ok, lazy = pcall(require, "lazy")
    if lazy_ok then
        local stats = lazy.stats()
        print("Plugins: " .. stats.loaded .. "/" .. stats.count .. " loaded")
    end
end, { desc = "Show development status" })

vim.api.nvim_create_user_command('HealthCheck', function()
    vim.cmd('checkhealth')
end, { desc = "Run Neovim health check" })

-- Debug setup helper
vim.api.nvim_create_user_command('DebugSetup', function()
    print("=== Debug Setup Status ===")

    -- Check DAP
    local dap_ok, dap = pcall(require, "dap")
    if dap_ok then
        print("✓ DAP loaded")

        -- Check adapters
        local python_adapter = dap.adapters.python
        local js_adapter = dap.adapters["pwa-node"]

        print("Python adapter: " .. (python_adapter and "✓" or "✗"))
        print("JavaScript adapter: " .. (js_adapter and "✓" or "✗"))

        -- Check configurations
        local python_configs = dap.configurations.python
        local js_configs = dap.configurations.javascript

        if python_configs and #python_configs > 0 then
            print("Python configs: ✓ (" .. #python_configs .. " available)")
        else
            print("Python configs: ✗")
        end

        if js_configs and #js_configs > 0 then
            print("JavaScript configs: ✓ (" .. #js_configs .. " available)")
        else
            print("JavaScript configs: ✗")
        end
    else
        print("✗ DAP not loaded")
    end

    -- Check Mason installations
    local mason_ok, mason_registry = pcall(require, "mason-registry")
    if mason_ok then
        local debug_adapters = {
            "debugpy",
            "js-debug-adapter",
            "node-debug2-adapter"
        }

        print("\n=== Mason Debug Adapters ===")
        for _, adapter in ipairs(debug_adapters) do
            local pkg = mason_registry.get_package(adapter)
            if pkg and pkg:is_installed() then
                print("✓ " .. adapter)
            else
                print("✗ " .. adapter .. " (run :MasonInstall " .. adapter .. ")")
            end
        end
    end
end, { desc = "Check debug setup status" })