-- ~/.config/nvim/lua/config/indentation.lua
-- Smart indentation settings per file type

local M = {}

function M.setup()
    -- Default indentation settings
    vim.opt.expandtab = true     -- use spaces instead of tabs
    vim.opt.tabstop = 4          -- display tabs as 4 spaces
    vim.opt.shiftwidth = 4       -- number of spaces for auto-indentation
    vim.opt.softtabstop = 4      -- backspace deletes 4 spaces as one tab
    vim.opt.smartindent = true   -- smart auto-indenting
    vim.opt.autoindent = true    -- copy indent from current line

    -- Create autocmd group for indentation
    local indent_group = vim.api.nvim_create_augroup("IndentSettings", { clear = true })

    -- Go - use real tabs (Go convention)
    vim.api.nvim_create_autocmd("FileType", {
        group = indent_group,
        pattern = "go",
        callback = function()
            vim.opt_local.expandtab = false    -- use real tabs
            vim.opt_local.tabstop = 4          -- tab width = 4 spaces
            vim.opt_local.shiftwidth = 4       -- indent width = 4 spaces
            vim.opt_local.softtabstop = 0      -- don't mix tabs and spaces
        end
    })

    -- JavaScript/TypeScript - 2 spaces (common convention)
    vim.api.nvim_create_autocmd("FileType", {
        group = indent_group,
        pattern = {"javascript", "typescript", "json", "jsonc"},
        callback = function()
            vim.opt_local.expandtab = true
            vim.opt_local.tabstop = 2
            vim.opt_local.shiftwidth = 2
            vim.opt_local.softtabstop = 2
        end
    })

    -- Web technologies - 2 spaces
    vim.api.nvim_create_autocmd("FileType", {
        group = indent_group,
        pattern = {"vue", "html", "css", "scss", "sass", "less"},
        callback = function()
            vim.opt_local.expandtab = true
            vim.opt_local.tabstop = 2
            vim.opt_local.shiftwidth = 2
            vim.opt_local.softtabstop = 2
        end
    })

    -- YAML - 2 spaces (YAML standard)
    vim.api.nvim_create_autocmd("FileType", {
        group = indent_group,
        pattern = {"yaml", "yml"},
        callback = function()
            vim.opt_local.expandtab = true
            vim.opt_local.tabstop = 2
            vim.opt_local.shiftwidth = 2
            vim.opt_local.softtabstop = 2
        end
    })

    -- Python - 4 spaces (PEP 8)
    vim.api.nvim_create_autocmd("FileType", {
        group = indent_group,
        pattern = "python",
        callback = function()
            vim.opt_local.expandtab = true
            vim.opt_local.tabstop = 4
            vim.opt_local.shiftwidth = 4
            vim.opt_local.softtabstop = 4
        end
    })

    -- C/C++ - 4 spaces or 2 spaces (configurable)
    vim.api.nvim_create_autocmd("FileType", {
        group = indent_group,
        pattern = {"c", "cpp", "h", "hpp"},
        callback = function()
            vim.opt_local.expandtab = true
            vim.opt_local.tabstop = 4
            vim.opt_local.shiftwidth = 4
            vim.opt_local.softtabstop = 4
        end
    })

    -- Lua - 4 spaces
    vim.api.nvim_create_autocmd("FileType", {
        group = indent_group,
        pattern = "lua",
        callback = function()
            vim.opt_local.expandtab = true
            vim.opt_local.tabstop = 4
            vim.opt_local.shiftwidth = 4
            vim.opt_local.softtabstop = 4
        end
    })

    -- Markdown - 2 or 4 spaces
    vim.api.nvim_create_autocmd("FileType", {
        group = indent_group,
        pattern = {"markdown", "md"},
        callback = function()
            vim.opt_local.expandtab = true
            vim.opt_local.tabstop = 2
            vim.opt_local.shiftwidth = 2
            vim.opt_local.softtabstop = 2
        end
    })

    -- Shell scripts - 2 or 4 spaces
    vim.api.nvim_create_autocmd("FileType", {
        group = indent_group,
        pattern = {"sh", "bash", "zsh"},
        callback = function()
            vim.opt_local.expandtab = true
            vim.opt_local.tabstop = 2
            vim.opt_local.shiftwidth = 2
            vim.opt_local.softtabstop = 2
        end
    })

    -- Docker - 2 spaces
    vim.api.nvim_create_autocmd("FileType", {
        group = indent_group,
        pattern = {"dockerfile", "docker-compose"},
        callback = function()
            vim.opt_local.expandtab = true
            vim.opt_local.tabstop = 2
            vim.opt_local.shiftwidth = 2
            vim.opt_local.softtabstop = 2
        end
    })

    -- XML-like files - 2 spaces
    vim.api.nvim_create_autocmd("FileType", {
        group = indent_group,
        pattern = {"xml", "svg", "xhtml"},
        callback = function()
            vim.opt_local.expandtab = true
            vim.opt_local.tabstop = 2
            vim.opt_local.shiftwidth = 2
            vim.opt_local.softtabstop = 2
        end
    })

    -- Configuration files - 4 spaces
    vim.api.nvim_create_autocmd("FileType", {
        group = indent_group,
        pattern = {"conf", "config", "ini", "toml"},
        callback = function()
            vim.opt_local.expandtab = true
            vim.opt_local.tabstop = 4
            vim.opt_local.shiftwidth = 4
            vim.opt_local.softtabstop = 4
        end
    })
end

-- Utility functions for indentation conversion
function M.tabs_to_spaces()
    vim.cmd("set expandtab")
    vim.cmd("retab")
    print("Converted tabs to spaces")
end

function M.spaces_to_tabs()
    vim.cmd("set noexpandtab")
    vim.cmd("retab!")
    print("Converted spaces to tabs")
end

function M.show_indent_info()
    local bufnr = vim.api.nvim_get_current_buf()
    local expandtab = vim.bo[bufnr].expandtab
    local tabstop = vim.bo[bufnr].tabstop
    local shiftwidth = vim.bo[bufnr].shiftwidth
    local softtabstop = vim.bo[bufnr].softtabstop
    local filetype = vim.bo[bufnr].filetype

    print(string.format(
        "File: %s | expandtab: %s | tabstop: %d | shiftwidth: %d | softtabstop: %d",
        filetype,
        expandtab and "true" or "false",
        tabstop,
        shiftwidth,
        softtabstop
    ))
end

-- Commands for manual indentation control
function M.setup_commands()
    vim.api.nvim_create_user_command("TabsToSpaces", M.tabs_to_spaces, {
        desc = "Convert tabs to spaces in current buffer"
    })

    vim.api.nvim_create_user_command("SpacesToTabs", M.spaces_to_tabs, {
        desc = "Convert spaces to tabs in current buffer"
    })

    vim.api.nvim_create_user_command("IndentInfo", M.show_indent_info, {
        desc = "Show current indentation settings"
    })

    -- Quick commands for setting indentation
    vim.api.nvim_create_user_command("Indent2", function()
        vim.opt_local.expandtab = true
        vim.opt_local.tabstop = 2
        vim.opt_local.shiftwidth = 2
        vim.opt_local.softtabstop = 2
        print("Set indentation to 2 spaces")
    end, { desc = "Set indentation to 2 spaces" })

    vim.api.nvim_create_user_command("Indent4", function()
        vim.opt_local.expandtab = true
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.softtabstop = 4
        print("Set indentation to 4 spaces")
    end, { desc = "Set indentation to 4 spaces" })

    vim.api.nvim_create_user_command("IndentTab", function()
        vim.opt_local.expandtab = false
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.softtabstop = 0
        print("Set indentation to tabs")
    end, { desc = "Set indentation to tabs" })
end

-- Setup keymaps for indentation functions
function M.setup_keymaps()
    local map = vim.keymap.set

    -- Show indent info
    map("n", "<leader>ui", M.show_indent_info, { desc = "· Show indent info" })

    -- Convert indentation
    map("n", "<leader>ut2", M.tabs_to_spaces, { desc = "· Tabs → Spaces" })
    map("n", "<leader>us2", M.spaces_to_tabs, { desc = "· Spaces → Tabs" })

    -- Quick indent settings
    map("n", "<leader>u2", function()
        vim.opt_local.expandtab = true
        vim.opt_local.tabstop = 2
        vim.opt_local.shiftwidth = 2
        vim.opt_local.softtabstop = 2
        print("Set to 2 spaces")
    end, { desc = "· Set 2 spaces" })

    map("n", "<leader>u4", function()
        vim.opt_local.expandtab = true
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.softtabstop = 4
        print("Set to 4 spaces")
    end, { desc = "· Set 4 spaces" })
end

return M