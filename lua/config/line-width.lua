-- Preferred display widths, not mandatory limits or automatic paragraph reflow.
local M = {}
local widths = {
    python = 79, c = 100, cpp = 100, go = 120, rust = 100,
    javascript = 100, javascriptreact = 100, typescript = 100, typescriptreact = 100,
    vue = 100, html = 120, htmldjango = 120, xml = 120,
    css = 100, scss = 100, sass = 100, less = 100, lua = 100,
    sh = 80, bash = 80, dockerfile = 100, make = 100,
    json = 100, jsonc = 100, yaml = 100, toml = 100, dosini = 100, ini = 100,
    vim = 80, help = 78,
}

function M.is_prose(buf)
    local ft = vim.bo[buf or 0].filetype
    return ft == "text" or ft == "markdown" or ft == "rst"
end

function M.default_width(buf)
    return widths[vim.bo[buf or 0].filetype] or 100
end

function M.width(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    local ft = vim.bo[buf].filetype
    if vim.bo[buf].buftype ~= "" or M.is_prose(buf)
        or vim.tbl_contains({ "gitignore", "NvimTree", "neo-tree", "oil", "dashboard", "alpha" }, ft) then
        return nil
    end
    -- Neovim already resolves EditorConfig; do not scan projects a second time.
    local config = vim.b[buf].editorconfig
    local width = type(config) == "table" and config.max_line_length
    if width == "off" then return nil end
    return tonumber(width) or M.default_width(buf)
end

function M.column(buf)
    local width = M.width(buf)
    return width and width > 0 and tostring(width + 1) or ""
end

function M.toggle()
    local column = M.column()
    vim.wo.colorcolumn = column ~= "" and vim.wo.colorcolumn == "" and column or ""
end

return M
