-- Saving must report real write errors and must never reload away unsaved text.
local M = {}
function M.smart_write()
    if not vim.bo.modifiable or vim.bo.readonly or vim.bo.buftype ~= "" then
        vim.notify("This buffer is not writable", vim.log.levels.WARN)
        return false
    end
    local buf = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_get_name(buf) == "" then
        vim.ui.input({ prompt = "Save as: ", completion = "file", default = vim.fn.getcwd() .. "/" }, function(path)
            if not path or path == "" or not vim.api.nvim_buf_is_valid(buf) then return end
            local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
                vim.cmd("write " .. vim.fn.fnameescape(path))
            end)
            if not ok then vim.notify(err, vim.log.levels.ERROR) end
        end)
        return false
    end
    local ok, err = pcall(vim.cmd, "write")
    if not ok then vim.notify(err, vim.log.levels.ERROR) end
    return ok
end
return M
