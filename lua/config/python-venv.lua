-- Resolve Python per project; switching buffers must not rewrite the process PATH.
local M = {}
local cache, selected, roots = {}, {}, {}

function M.root(path)
    path = path or vim.api.nvim_buf_get_name(0)
    if path == "" then path = vim.fn.getcwd() end
    -- The statusline calls this frequently; avoid walking parent directories on redraw.
    if roots[path] then return roots[path] end
    roots[path] = vim.fs.root(path, require("config.project").python_markers)
        or (vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path))
    return roots[path]
end

function M.find_venv(path)
    local root = M.root(path)
    if selected[root] == false then return nil end
    if selected[root] then return selected[root] end
    if cache[root] ~= nil then return cache[root] or nil end
    local dir = root
    for _ = 1, 4 do
        for _, name in ipairs({ ".venv", "venv", "env", ".env" }) do
            local python = dir .. "/" .. name .. "/bin/python"
            if vim.fn.executable(python) == 1 then
                local value = { path = dir .. "/" .. name, name = name, python = python, project_root = root }
                cache[root] = value
                return value
            end
        end
        local parent = vim.fs.dirname(dir)
        if not parent or parent == dir then break end
        dir = parent
    end
    cache[root] = false
end

function M.python(path)
    local info = M.find_venv(path)
    if info then return info.python end
    if selected[M.root(path)] ~= false and vim.env.VIRTUAL_ENV then
        local python = vim.env.VIRTUAL_ENV .. "/bin/python"
        if vim.fn.executable(python) == 1 then return python end
    end
    return vim.fn.exepath("python3") ~= "" and vim.fn.exepath("python3") or "python3"
end

function M.get_current_venv() return M.find_venv() end

local function update_clients(root)
    for _, client in ipairs(vim.lsp.get_clients({ name = "pyright" })) do
        local matches = require("config.project").normalize(client.config.root_dir)
            == require("config.project").normalize(root)
        if not client.config.root_dir then
            for buf in pairs(client.attached_buffers) do
                if M.root(vim.api.nvim_buf_get_name(buf)) == root then matches = true; break end
            end
        end
        if matches then
            -- workspace/configuration reads client.settings, not a replaced config table.
            client.settings = vim.tbl_deep_extend("force", client.settings or {},
                { python = { pythonPath = M.python(root) } })
            client.config.settings = client.settings
            client:notify("workspace/didChangeConfiguration", { settings = client.settings })
        end
    end
end

function M.activate(info)
    if not info or vim.fn.executable(info.python) == 0 then return false end
    local root = M.root()
    selected[root] = info
    update_clients(root)
    vim.notify("Python: " .. info.python)
    return true
end

function M.deactivate()
    local root = M.root()
    selected[root] = false
    update_clients(root)
    vim.notify("Using system Python for " .. root)
end

function M.status() vim.notify("Python: " .. M.python()) end

function M.setup()
    local group = vim.api.nvim_create_augroup("PythonEnvironment", { clear = true })
    vim.api.nvim_create_autocmd("DirChanged", { group = group, callback = function() cache, roots = {}, {} end })
    vim.api.nvim_create_user_command("VenvActivate", function()
        local root = M.root()
        selected[root], cache[root] = nil, nil
        local info = M.find_venv()
        if info then M.activate(info) else vim.notify("No project environment found", vim.log.levels.WARN) end
    end, { desc = "Detect project Python environment" })
    vim.api.nvim_create_user_command("VenvSelect", function()
        vim.ui.input({ prompt = "Environment directory: ", completion = "dir", default = M.root() .. "/" }, function(path)
            if not path or path == "" then return end
            path = vim.fs.normalize(vim.fn.expand(path))
            if not M.activate({ path = path, name = vim.fs.basename(path), python = path .. "/bin/python", project_root = M.root() }) then
                vim.notify("No executable bin/python in " .. path, vim.log.levels.ERROR)
            end
        end)
    end, { desc = "Select project Python environment" })
    vim.api.nvim_create_user_command("VenvDeactivate", M.deactivate, { desc = "Use system Python for this project" })
    vim.api.nvim_create_user_command("VenvStatus", M.status, { desc = "Show project Python interpreter" })
    vim.api.nvim_create_user_command("VenvFind", function()
        cache, roots = {}, {}
        M.status()
    end, { desc = "Refresh environment detection" })
end

return M
