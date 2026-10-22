-- Prefer project tools, then executable paths (including Mason's bin directory).
local M = {}
function M.executable(name, buf)
    buf = buf or vim.api.nvim_get_current_buf()
    local path = vim.api.nvim_buf_get_name(buf)
    if vim.bo[buf].filetype == "python" then
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
