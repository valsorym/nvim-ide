-- Share Python project boundaries between interpreter selection and pyright.
local M = {}
M.python_markers = { "pyrightconfig.json", "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".git" }
function M.normalize(path)
    return path and vim.fs.normalize(vim.uv.fs_realpath(path) or path):gsub("/+$", "") or nil
end
function M.safe_root(root)
    if not root then return nil end
    local normalized = M.normalize(root)
    if normalized == "" or normalized == M.normalize(vim.env.HOME) or normalized == "/tmp" then return nil end
    return root
end
return M
