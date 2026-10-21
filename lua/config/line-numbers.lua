-- Absolute numbers by default; set nvim_ide_relative_numbers for hybrid numbers.
local M = {}
function M.setup()
    vim.opt.number = true
    vim.opt.numberwidth = 4
    local group = vim.api.nvim_create_augroup("LineNumbers", { clear = true })
    vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "InsertLeave", "InsertEnter", "FileType" }, {
        group = group,
        callback = function()
            local normal = vim.bo.buftype == "" and vim.bo.filetype ~= "dashboard"
            vim.wo.number = normal
            vim.wo.relativenumber = normal and vim.g.nvim_ide_relative_numbers == true
                and vim.fn.mode() ~= "i"
        end,
    })
end
return M
