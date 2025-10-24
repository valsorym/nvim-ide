-- ~/.config/nvim/lua/config/filetype-settings.lua
-- Minimal filetype settings - most handled by ftplugin/*.lua

local M = {}

function M.setup()
    -- Set global defaults: 4 spaces, colorcolumn at 79
    vim.opt.colorcolumn = "79"
    vim.opt.wrap = false
    vim.opt.expandtab = true
    vim.opt.tabstop = 4
    vim.opt.shiftwidth = 4
    vim.opt.softtabstop = 4
    vim.opt.smartindent = true
    vim.opt.autoindent = true

    -- Hide colorcolumn for special buffers
    local group = vim.api.nvim_create_augroup(
        "FileTypeSettings",
        {clear = true}
    )

    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        callback = function()
            local buftype = vim.bo.buftype
            local filetype = vim.bo.filetype

            -- Hide colorcolumn for special buffers
            if buftype ~= "" or
               filetype == "NvimTree" or
               filetype == "neo-tree" or
               filetype == "oil" or
               filetype == "help" or
               filetype == "dashboard" or
               filetype == "alpha" then
                vim.opt_local.colorcolumn = ""
            end
        end,
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
    local wrap = vim.wo.wrap
    local colorcolumn = vim.wo.colorcolumn

    print(string.format(
        "File: %s | wrap: %s | cc: %s | expandtab: %s | " ..
        "tab: %d | shift: %d | soft: %d",
        filetype,
        wrap and "true" or "false",
        colorcolumn,
        expandtab and "true" or "false",
        tabstop,
        shiftwidth,
        softtabstop
    ))
end

function M.setup_commands()
    vim.api.nvim_create_user_command("TabsToSpaces",
        M.tabs_to_spaces,
        {desc = "Convert tabs to spaces in current buffer"}
    )

    vim.api.nvim_create_user_command("SpacesToTabs",
        M.spaces_to_tabs,
        {desc = "Convert spaces to tabs in current buffer"}
    )

    vim.api.nvim_create_user_command("IndentInfo",
        M.show_indent_info,
        {desc = "Show current indentation settings"}
    )

    vim.api.nvim_create_user_command("Indent2", function()
        vim.opt_local.expandtab = true
        vim.opt_local.tabstop = 2
        vim.opt_local.shiftwidth = 2
        vim.opt_local.softtabstop = 2
        print("Set indentation to 2 spaces")
    end, {desc = "Set indentation to 2 spaces"})

    vim.api.nvim_create_user_command("Indent4", function()
        vim.opt_local.expandtab = true
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.softtabstop = 4
        print("Set indentation to 4 spaces")
    end, {desc = "Set indentation to 4 spaces"})

    vim.api.nvim_create_user_command("IndentTab", function()
        vim.opt_local.expandtab = false
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.softtabstop = 0
        print("Set indentation to tabs")
    end, {desc = "Set indentation to tabs"})
end

function M.setup_keymaps()
    local map = vim.keymap.set

    map("n", "<leader>ui", M.show_indent_info,
        {desc = "Show indent info"})
    map("n", "<leader>ut2", M.tabs_to_spaces,
        {desc = "Tabs → Spaces"})
    map("n", "<leader>us2", M.spaces_to_tabs,
        {desc = "Spaces → Tabs"})

    map("n", "<leader>u2", function()
        vim.opt_local.expandtab = true
        vim.opt_local.tabstop = 2
        vim.opt_local.shiftwidth = 2
        vim.opt_local.softtabstop = 2
        print("Set to 2 spaces")
    end, {desc = "Set 2 spaces"})

    map("n", "<leader>u4", function()
        vim.opt_local.expandtab = true
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.softtabstop = 4
        print("Set to 4 spaces")
    end, {desc = "Set 4 spaces"})
end

return M