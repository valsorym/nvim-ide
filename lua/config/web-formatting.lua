-- Shared, side-effect-free selection for formatting and the health report.
local M = {}
local extensions = { javascript = "js", javascriptreact = "jsx", typescript = "ts", typescriptreact = "tsx",
    vue = "vue", json = "json", jsonc = "jsonc", yaml = "yaml", html = "html", css = "css", scss = "scss",
    less = "less", markdown = "md" }

function M.supports(filetype) return extensions[filetype] ~= nil end

function M.select(buf, source_path, filetype)
    buf = buf or vim.api.nvim_get_current_buf()
    filetype = filetype or vim.bo[buf].filetype
    local path = source_path or vim.api.nvim_buf_get_name(buf)
    local preference = vim.g.nvim_ide_web_formatter or "prettierd"
    local invalid = preference ~= "prettierd" and preference ~= "prettier"
    if invalid then preference = "prettierd" end
    local tools = require("config.tools")
    local daemon = preference == "prettierd" and tools.executable("prettierd", buf, filetype, path) or nil
    return { name = daemon and "prettierd" or "prettier",
        executable = daemon or tools.executable("prettier", buf, filetype, path),
        preference = preference, invalid_preference = invalid }
end

function M.plan(buf)
    local filetype = vim.bo[buf].filetype
    local selected = M.select(buf)
    if not selected.executable then return selected end
    local path = vim.api.nvim_buf_get_name(buf)
    if path == "" then path = vim.fn.getcwd() .. "/untitled." .. extensions[filetype] end
    local width = require("config.line-width")
    local args = { selected.executable }
    if selected.name == "prettierd" then
        args[#args + 1] = path
        -- prettierd keeps one process per cwd: share it across a project's subdirectories.
        selected.cwd = vim.fs.root(path, { "package.json", ".git" }) or vim.fs.dirname(path)
        selected.cwd = vim.uv.fs_realpath(selected.cwd) or selected.cwd
    else
        vim.list_extend(args, { "--stdin-filepath", path })
    end
    -- prettierd accepts option values with '='; both backends accept this syntax.
    if filetype == "markdown" then
        args[#args + 1] = "--prose-wrap=preserve"
    else
        args[#args + 1] = "--print-width=" .. tostring(width.width(buf) or width.default_width(buf))
        args[#args + 1] = "--config-precedence=prefer-file"
    end
    selected.command = args
    return selected
end

return M
