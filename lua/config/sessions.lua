-- Native :mksession with one store; deletion also prevents automatic recreation.
local M = {}
local disabled = {}
local dir = vim.fn.stdpath("state") .. "/sessions-v2"
local index_path = dir .. "/index.json"

local function read_index()
    local file = io.open(index_path, "r")
    if not file then return { sessions = {}, workspaces = {} } end
    local text = file:read("*a")
    file:close()
    local ok, value = pcall(vim.json.decode, text)
    return ok and value or { sessions = {}, workspaces = {} }
end

local function write_index(index)
    vim.fn.mkdir(dir, "p")
    local temp = index_path .. "." .. vim.fn.getpid() .. ".tmp"
    vim.fn.writefile({ vim.json.encode(index) }, temp)
    assert(vim.uv.fs_rename(temp, index_path))
end

local function eligible(cwd)
    if cwd == vim.env.HOME or cwd == "/" or cwd == "/tmp" then return false end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buf].buflisted and vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" then return true end
    end
    return false
end

function M.save(automatic)
    local cwd = vim.fn.getcwd()
    if automatic and (disabled[cwd] or not eligible(cwd)) then return end
    vim.fn.mkdir(dir, "p")
    local path = dir .. "/" .. vim.fn.sha256(cwd) .. ".vim"
    local temp = path .. "." .. vim.fn.getpid() .. ".tmp"
    local previous = vim.o.sessionoptions
    vim.opt.sessionoptions = { "buffers", "curdir", "folds", "tabpages", "winsize" }
    local ok, err = pcall(vim.cmd, "mksession! " .. vim.fn.fnameescape(temp))
    vim.o.sessionoptions = previous
    if not ok then
        if not automatic then vim.notify(err, vim.log.levels.ERROR) end
        return
    end
    local renamed, rename_err = vim.uv.fs_rename(temp, path)
    if not renamed then vim.notify(rename_err, vim.log.levels.ERROR); return end
    local index = read_index()
    index.sessions[cwd] = { path = path, cwd = cwd, time = os.time() }
    index.last = cwd
    write_index(index)
    disabled[cwd] = nil
    if not automatic then vim.notify("Session saved: " .. cwd) end
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
    if not ok then vim.notify(err, vim.log.levels.ERROR) end
end

function M.delete()
    local cwd = vim.fn.getcwd()
    local index = read_index()
    local entry = index.sessions[cwd]
    if entry then
        local ok, err = vim.uv.fs_unlink(entry.path)
        if not ok and vim.fn.filereadable(entry.path) == 1 then vim.notify(err, vim.log.levels.ERROR); return end
        index.sessions[cwd] = nil
        if index.last == cwd then index.last = nil end
        write_index(index)
    end
    disabled[cwd] = true
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
        local index = read_index()
        index.workspaces[vim.fn.getcwd()] = name
        write_index(index)
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
