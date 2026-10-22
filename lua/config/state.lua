-- Atomic state writes; JSON updates re-read under a short inter-process lock.
local M = {}
function M.write(path, text)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    local temp = path .. "." .. vim.fn.getpid() .. "." .. vim.uv.hrtime() .. ".tmp"
    local file, err = io.open(temp, "wb")
    if not file then return nil, err end
    local ok, write_err = file:write(text)
    local closed, close_err = file:close()
    if not ok or not closed then vim.uv.fs_unlink(temp); return nil, write_err or close_err end
    local renamed, rename_err = vim.uv.fs_rename(temp, path)
    if not renamed then vim.uv.fs_unlink(temp) end
    return renamed, rename_err
end
function M.read_json(path, default)
    local file = io.open(path, "rb")
    if not file then return vim.deepcopy(default) end
    local text = file:read("*a"); file:close()
    local ok, data = pcall(vim.json.decode, text)
    if not ok or type(data) ~= "table" or data == vim.NIL then
        return nil, "Invalid state file, preserved unchanged: " .. path
    end
    return data
end
function M.update_json(path, default, change)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    local lock = path .. ".lock"
    local fd
    -- State writes are rare. A busy writer gets a bounded retry, never an overwrite.
    local ready = vim.wait(200, function()
        fd = vim.uv.fs_open(lock, "wx", 384)
        if not fd then
            local existing = io.open(lock, "r")
            local pid = existing and tonumber(existing:read("*a"))
            if existing then existing:close() end
            if pid and not vim.uv.kill(pid, 0) then vim.uv.fs_unlink(lock) end
        end
        return fd ~= nil
    end, 10)
    if not ready then return nil, "State is busy; retry the command: " .. path end
    vim.uv.fs_write(fd, tostring(vim.fn.getpid()))
    local ok, result = pcall(function()
        local value, err = M.read_json(path, default)
        assert(value, err)
        value = change(value) or value
        local written, write_err = M.write(path, vim.json.encode(value) .. "\n")
        assert(written, write_err)
        return value
    end)
    vim.uv.fs_close(fd); vim.uv.fs_unlink(lock)
    if not ok then return nil, result end
    return result
end
return M
