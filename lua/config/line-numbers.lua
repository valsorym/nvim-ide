-- ~/.config/nvim/lua/config/line-numbers.lua
-- Standard hybrid line numbers with exclusions.

local M = {}

local function should_show_numbers()
    local buftype = vim.bo.buftype
    local filetype = vim.bo.filetype

    -- Exclude special buffers.
    if buftype ~= "" then
        return false
    end

    -- Exclude file explorers and special UIs.
    if
        filetype == "NvimTree" or filetype == "neo-tree" or filetype == "oil" or filetype == "help" or
            filetype == "dashboard"
     then
        return false
    end

    return true
end

local function set_relative_numbers()
    if should_show_numbers() then
        vim.wo.number = true
        vim.wo.relativenumber = false -- set true for relative, false for hybrid
    else
        vim.wo.number = false
        vim.wo.relativenumber = false
    end
end

local function set_absolute_numbers()
    if should_show_numbers() then
        vim.wo.number = true
        vim.wo.relativenumber = false
    else
        vim.wo.number = false
        vim.wo.relativenumber = false
    end
end

function M.setup()
    -- Start with hybrid mode.
    vim.opt.number = true
    vim.opt.relativenumber = true
    vim.opt.numberwidth = 4

    local line_numbers_group = vim.api.nvim_create_augroup("SmartLineNumbers", {clear = true})

    -- Handle buffer type changes.
    vim.api.nvim_create_autocmd(
        {"BufEnter", "BufWinEnter", "FileType"},
        {group = line_numbers_group, callback = set_relative_numbers}
    )

    -- Switch to absolute in insert mode, etc.
    vim.api.nvim_create_autocmd(
        {"InsertEnter", "FocusLost", "WinLeave", "CmdlineEnter"},
        {group = line_numbers_group, callback = set_absolute_numbers}
    )

    -- Switch back to relative in normal mode.
    vim.api.nvim_create_autocmd(
        {"InsertLeave", "FocusGained", "WinEnter", "CmdlineLeave"},
        {
            group = line_numbers_group,
            callback = function()
                if vim.fn.mode() == "n" then
                    set_relative_numbers()
                end
            end
        }
    )
end

return M
