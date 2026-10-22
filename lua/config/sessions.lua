-- Native :mksession with one store; deletion also prevents automatic recreation.
local M = {}
local disabled, managed = {}, {}
local store = require("config.state")
local dir = vim.fn.stdpath("state") .. "/sessions-v2"
local index_path = dir .. "/index.json"

local function normalize(index)
    for _, key in ipairs({ "sessions", "workspaces" }) do
        if type(index[key]) ~= "table" or next(index[key]) == nil then index[key] = vim.empty_dict() end
    end
    if type(index.last) ~= "string" then index.last = nil end
    for cwd, entry in pairs(index.sessions) do
        if type(entry) ~= "table" or type(entry.path) ~= "string" then index.sessions[cwd] = nil
        else entry.cwd, entry.time = entry.cwd or cwd, tonumber(entry.time) or 0 end
    end
    for cwd, name in pairs(index.workspaces) do
        if type(name) ~= "string" then index.workspaces[cwd] = nil end
    end
    return index
end
local function read_index()
    local index, err = store.read_json(index_path, {})
    if not index then vim.notify(err, vim.log.levels.ERROR); return normalize({}) end
    return normalize(index)
end
local function update_index(change)
    local result, err = store.update_json(index_path, {}, function(index) return change(normalize(index)) end)
    if not result then vim.notify(err, vim.log.levels.ERROR) end
    return result
end
local function eligible(cwd)
    if not require("config.project").safe_root(cwd) then return false end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buf].buflisted and vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" then return true end
    end
    return false
end

function M.save(automatic)
    local cwd = vim.fn.getcwd()
    -- A quick `nvim file` visit cannot replace a deliberately saved project session.
    if automatic and (not managed[cwd] or disabled[cwd] or not eligible(cwd)) then return end
    local path = dir .. "/" .. vim.fn.sha256(cwd) .. ".vim"
    local updated = update_index(function(index)
        local temp = path .. "." .. vim.fn.getpid() .. ".tmp"
        local previous = vim.o.sessionoptions
        vim.opt.sessionoptions = { "buffers", "curdir", "folds", "tabpages", "winsize" }
        local ok, err = pcall(vim.cmd, "mksession! " .. vim.fn.fnameescape(temp))
        vim.o.sessionoptions = previous
        if not ok then vim.uv.fs_unlink(temp); error(err) end
        local old = io.open(path, "rb")
        if old then
            local text = old:read("*a"); old:close()
            local backed, backup_err = store.write(path .. ".bak", text)
            if not backed then vim.uv.fs_unlink(temp); error(backup_err) end
        end
        local renamed, rename_err = vim.uv.fs_rename(temp, path)
        assert(renamed, rename_err)
        index.sessions[cwd] = { path = path, cwd = cwd, time = os.time() }
        index.last = cwd
        return index
    end)
    if not updated then return end
    managed[cwd], disabled[cwd] = true, nil
    if not automatic then vim.notify("Session saved: " .. cwd) end
    return true
end

function M.restore(entry)
    if not entry then entry = read_index().sessions[vim.fn.getcwd()] end
    if not entry or vim.fn.filereadable(entry.path) == 0 then
        vim.notify("No saved session for this directory", vim.log.levels.WARN)
        return
    end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buf].modified then
            vim.notify("Save or discard modified buffers before restoring a session", vim.log.levels.WARN)
            return
        end
    end
    local ok, err = pcall(vim.cmd, "source " .. vim.fn.fnameescape(entry.path))
    if not ok then vim.notify(err, vim.log.levels.ERROR); return end
    managed[vim.fn.getcwd()], disabled[vim.fn.getcwd()] = true, nil
    return true
end

function M.delete()
    local cwd = vim.fn.getcwd()
    local updated = update_index(function(index)
        local entry = index.sessions[cwd]
        if entry then
            local ok, err = vim.uv.fs_unlink(entry.path)
            assert(ok or vim.fn.filereadable(entry.path) == 0, err)
            vim.uv.fs_unlink(entry.path .. ".bak")
            index.sessions[cwd] = nil
            if index.last == cwd then index.last = nil end
        end
        return index
    end)
    if not updated then return end
    disabled[cwd], managed[cwd] = true, nil
    vim.notify("Session deleted; automatic saving paused until SessionSave")
end

function M.pick(legacy)
    local entries = {}
    if legacy then
        for _, base in ipairs({ vim.fn.stdpath("data") .. "/sessions", vim.fn.stdpath("state") .. "/sessions" }) do
            for _, path in ipairs(vim.fn.glob(base .. "/*.vim", false, true)) do
                entries[#entries + 1] = { path = path, cwd = vim.fn.fnamemodify(path, ":t"), time = 0 }
            end
        end
    else
        for _, entry in pairs(read_index().sessions) do entries[#entries + 1] = entry end
    end
    table.sort(entries, function(a, b) return a.time > b.time end)
    vim.ui.select(entries, { prompt = legacy and "Legacy sessions (save after restoring)" or "Sessions",
        format_item = function(entry) return entry.cwd end }, function(entry)
        if entry then M.restore(entry) end
    end)
end

function M.add_workspace()
    vim.ui.input({ prompt = "Workspace name: ", default = vim.fs.basename(vim.fn.getcwd()) }, function(name)
        if not name or name == "" then return end
        update_index(function(index)
            index.workspaces[vim.fn.getcwd()] = name
            return index
        end)
    end)
end

function M.workspaces()
    local entries = {}
    for path, name in pairs(read_index().workspaces) do entries[#entries + 1] = { path = path, name = name } end
    table.sort(entries, function(a, b) return a.name < b.name end)
    vim.ui.select(entries, { prompt = "Workspaces", format_item = function(entry) return entry.name .. "  " .. entry.path end }, function(entry)
        if not entry then return end
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.bo[buf].modified then
                vim.notify("Save or discard modified buffers before switching workspaces", vim.log.levels.WARN)
                return
            end
        end
        M.save(true)
        vim.cmd("cd " .. vim.fn.fnameescape(entry.path))
        local saved = read_index().sessions[entry.path]
        if saved then M.restore(saved) end
    end)
end

function M.setup()
    local group = vim.api.nvim_create_augroup("Sessions", { clear = true })
    vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = function() M.save(true) end })
    local commands = {
        SessionSave = function() M.save(false) end,
        SessionRestore = function() M.restore() end,
        SessionLast = function() local index = read_index(); M.restore(index.sessions[index.last]) end,
        SessionDelete = M.delete,
        SessionFind = function() M.pick(false) end,
        SessionLegacy = function() M.pick(true) end,
        WorkspaceAdd = M.add_workspace,
        WorkspaceFind = M.workspaces,
    }
    for name, callback in pairs(commands) do vim.api.nvim_create_user_command(name, callback, {}) end
end
return M
