-- Saving must report real write errors and must never reload away unsaved text.
local M = {}
function M.write_buffer(buf, path)
    local written, endofline
    -- Capture after formatting hooks. Neovim can clear 'modified' after a
    -- BufWritePost hook changes the text, even though that text was not written.
    local handler = vim.api.nvim_create_autocmd("BufWritePre", { buffer = buf, callback = function()
        written = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        endofline = vim.bo[buf].endofline
    end })
    local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
        vim.cmd("write" .. (path and (" " .. vim.fn.fnameescape(path)) or ""))
    end)
    pcall(vim.api.nvim_del_autocmd, handler)
    if not vim.api.nvim_buf_is_valid(buf) then return false, tostring(err or "Buffer was removed by a write hook") end
    if written and (endofline ~= vim.bo[buf].endofline
        or not vim.deep_equal(written, vim.api.nvim_buf_get_lines(buf, 0, -1, false))) then
        vim.bo[buf].modified = true
    end
    if not ok then return false, tostring(err) end
    if vim.bo[buf].modified then return false, "Buffer still has unsaved changes after writing" end
    return true
end

function M.smart_write()
    if not vim.bo.modifiable or vim.bo.readonly or vim.bo.buftype ~= "" then
        vim.notify("This buffer is not writable", vim.log.levels.WARN)
        return false
    end
    local buf = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_get_name(buf) == "" then
        vim.ui.input({ prompt = "Save as: ", completion = "file", default = vim.fn.getcwd() .. "/" }, function(path)
            if not path or path == "" or not vim.api.nvim_buf_is_valid(buf) then return end
            local ok, err = M.write_buffer(buf, path)
            if not ok then vim.notify(err, vim.log.levels.ERROR) end
        end)
        return false
    end
    local ok, err = M.write_buffer(buf)
    if not ok then vim.notify(err, vim.log.levels.ERROR) end
    return ok
end
return M
