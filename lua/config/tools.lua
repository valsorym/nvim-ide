-- Prefer project tools, then executable paths (including Mason's bin directory).
local M = {}
function M.setup_path()
    local separator = vim.fn.has("win32") == 1 and ";" or ":"
    local paths = vim.split(vim.env.PATH or "", separator, { plain = true, trimempty = true })
    local home = vim.fn.expand("~")
    local candidates = { home .. "/.local/bin", (vim.env.CARGO_HOME or (home .. "/.cargo")) .. "/bin" }
    for _, root in ipairs(vim.split(vim.env.GOPATH or (home .. "/go"), separator, { plain = true, trimempty = true })) do
        candidates[#candidates + 1] = root .. "/bin"
    end
    candidates[#candidates + 1] = (vim.env.GOROOT or "/usr/local/go") .. "/bin"
    -- Desktop launchers may miss shell PATH exports. Keep explicit PATH choices first.
    for _, path in ipairs(candidates) do
        if vim.fn.isdirectory(path) == 1 and not vim.tbl_contains(paths, path) then
            paths[#paths + 1] = path
        end
    end
    local mason = vim.fn.stdpath("data") .. "/mason/bin"
    paths = vim.tbl_filter(function(path) return path ~= mason end, paths)
    table.insert(paths, 1, mason)
    vim.env.PATH = table.concat(paths, separator)
end

function M.executable(name, buf, filetype, source_path)
    buf = buf or vim.api.nvim_get_current_buf()
    local path = source_path or vim.api.nvim_buf_get_name(buf)
    if (filetype or vim.bo[buf].filetype) == "python" then
        local python = require("config.python-venv").python(path)
        local candidate = vim.fs.dirname(python) .. "/" .. name
        if vim.fn.executable(candidate) == 1 then return candidate end
    end
    local root = vim.fs.root(path ~= "" and path or vim.fn.getcwd(), { "package.json", ".git" })
    if root and vim.fn.executable(root .. "/node_modules/.bin/" .. name) == 1 then
        return root .. "/node_modules/.bin/" .. name
    end
    local exe = vim.fn.exepath(name)
    return exe ~= "" and exe or nil
end
return M
