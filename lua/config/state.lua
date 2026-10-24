-- Atomic state writes; JSON updates re-read under a short inter-process lock.
local M = {}
local uv = vim.uv

local function ensure_parent(path)
    local ok, err = pcall(vim.fn.mkdir, vim.fs.dirname(path), "p")
    if not ok then return nil, tostring(err) end
    return true
end

local function write_all(fd, text)
    local offset = 0
    while offset < #text do
        local count, err = uv.fs_write(fd, text:sub(offset + 1), offset)
        if not count or count == 0 then return nil, err or "Incomplete state write" end
        offset = offset + count
    end
    return true
end

function M.write(path, text)
    local parent = vim.fs.dirname(path)
    local ready, parent_err = ensure_parent(path)
    if not ready then return nil, parent_err end
    local temp = path .. "." .. vim.fn.getpid() .. "." .. uv.hrtime() .. ".tmp"
    local fd, err = uv.fs_open(temp, "wx", 384)
    if not fd then return nil, err end
    local written, write_err = write_all(fd, text)
    if written then
        local synced, failure = uv.fs_fsync(fd)
        if not synced then write_err = failure or "Could not sync state" end
    end
    local closed, close_err = uv.fs_close(fd)
    if write_err or not closed then uv.fs_unlink(temp); return nil, write_err or close_err end
    local renamed, rename_err = uv.fs_rename(temp, path)
    if not renamed then uv.fs_unlink(temp); return nil, rename_err end
    -- Persist the rename where directory fsync is supported.
    local directory = uv.fs_open(parent, "r", 0)
    if directory then uv.fs_fsync(directory); uv.fs_close(directory) end
    return true
end

function M.read_json(path, default)
    local file, err, code = io.open(path, "rb")
    if not file then
        if code == 2 then return vim.deepcopy(default) end
        return nil, "Cannot read state file, preserved unchanged: " .. path .. ": " .. tostring(err)
    end
    local text = file:read("*a"); file:close()
    local ok, data = pcall(vim.json.decode, text)
    if not ok or type(data) ~= "table" or data == vim.NIL then
        return nil, "Invalid state file, preserved unchanged: " .. path
    end
    return data
end

local function dead(pid)
    local _, _, code = uv.kill(pid, 0)
    return code == "ESRCH" -- EPERM still means the owner may be alive.
end

local function reap(lock)
    local stat = uv.fs_stat(lock)
    if not stat then return end
    local old = os.time() - stat.mtime.sec >= 5
    if stat.type == "file" then
        -- Recover locks left by older versions, including a crash before writing the PID.
        local file = io.open(lock, "r")
        local contents = file and file:read("*a")
        if file then file:close() end
        local pid = tonumber(contents)
        if pid and (pid <= 0 or pid % 1 ~= 0) then pid = nil end
        if (pid and pid > 0 and dead(pid)) or (not pid and old) then uv.fs_unlink(lock) end
    elseif stat.type == "directory" then
        local owners = {}
        local scan = uv.fs_scandir(lock)
        if not scan then return end
        while true do
            local name = uv.fs_scandir_next(scan)
            if not name then break end
            owners[#owners + 1] = name
        end
        if #owners == 0 and old then uv.fs_rmdir(lock)
        elseif #owners == 1 then
            local pid = tonumber(owners[1]:match("^(%d+)%.%d+$"))
            if pid and pid > 0 and dead(pid) then
                uv.fs_unlink(lock .. "/" .. owners[1])
                uv.fs_rmdir(lock)
            end
        end
    end
end

function M.update_json(path, default, change)
    local ready_parent, parent_err = ensure_parent(path)
    if not ready_parent then return nil, parent_err end
    local lock = path .. ".lock"
    local gate = lock .. ".d"
    local deadline = uv.hrtime() + 200000000
    local owner = string.format("%d.%.0f", vim.fn.getpid(), uv.hrtime())
    local candidate = gate .. "." .. owner .. ".tmp"
    local created, create_err = uv.fs_mkdir(candidate, 448)
    if not created then return nil, create_err end
    local fd, open_err = uv.fs_open(candidate .. "/" .. owner, "wx", 384)
    if not fd then uv.fs_rmdir(candidate); return nil, open_err end
    uv.fs_close(fd)
    -- Publish a complete, nonempty directory atomically. Rename cannot replace a
    -- live nonempty lock; rmdir cannot remove a new owner's nonempty directory.
    local ready = vim.wait(200, function()
        if uv.fs_rename(candidate, gate) then return true end
        reap(gate)
        return false
    end, 10)
    if not ready then
        uv.fs_unlink(candidate .. "/" .. owner); uv.fs_rmdir(candidate)
        return nil, "State is busy; retry the command: " .. path
    end
    local function release_gate()
        uv.fs_unlink(gate .. "/" .. owner); uv.fs_rmdir(gate)
    end
    -- Retain the PID file protocol so editors running an older configuration
    -- still share the same lock, while the directory gate serializes recovery.
    local legacy_fd
    local acquired = vim.wait(math.max(0, math.floor((deadline - uv.hrtime()) / 1000000)), function()
        legacy_fd = uv.fs_open(lock, "wx", 384)
        if legacy_fd then return true end
        reap(lock)
        return false
    end, 10)
    if not acquired then release_gate(); return nil, "State is busy; retry the command: " .. path end
    local identified, identify_err = write_all(legacy_fd, tostring(vim.fn.getpid()))
    if not identified then
        uv.fs_close(legacy_fd); uv.fs_unlink(lock); release_gate()
        return nil, identify_err
    end
    local ok, result = pcall(function()
        local value, err = M.read_json(path, default)
        assert(value, err)
        value = change(value) or value
        local written, write_err = M.write(path, vim.json.encode(value) .. "\n")
        assert(written, write_err)
        return value
    end)
    uv.fs_close(legacy_fd); uv.fs_unlink(lock); release_gate()
    if not ok then return nil, result end
    return result
end
return M
