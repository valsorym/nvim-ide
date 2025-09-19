-- ~/.config/nvim/lua/config/colorcolumn.lua
-- Vertical line guide at 79 characters.

local M = {}

local function should_show_colorcolumn()
    local buftype = vim.bo.buftype
    local filetype = vim.bo.filetype

    -- Exclude special buffers.
    if buftype ~= "" then
        return false
    end

    -- Exclude file explorers and help.
    if
        filetype == "NvimTree" or filetype == "neo-tree" or filetype == "oil" or filetype == "help" or
            filetype == "dashboard" or
            filetype == "alpha"
     then
        return false
    end

    return true
end

function M.setup()
    -- Set default colorcolumn.
    vim.opt.colorcolumn = "79"

    -- Create autocmd group.
    local colorcolumn_group = vim.api.nvim_create_augroup("ColorColumn", {clear = true})

    -- Handle buffer type changes.
    vim.api.nvim_create_autocmd(
        {"BufEnter", "BufWinEnter", "FileType"},
        {
            group = colorcolumn_group,
            callback = function()
                if should_show_colorcolumn() then
                    vim.wo.colorcolumn = "79"
                else
                    vim.wo.colorcolumn = ""
                end
            end
        }
    )
end

return M
