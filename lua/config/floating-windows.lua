-- Floating windows follow the active theme, including changes made in tmux.
local M = {}
function M.setup()
    vim.o.winborder = "rounded"
    vim.diagnostic.config({ virtual_text = false, signs = {
        text = { [vim.diagnostic.severity.ERROR] = "", [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.INFO] = "", [vim.diagnostic.severity.HINT] = "" },
    }, underline = false, update_in_insert = false, severity_sort = true,
        float = { border = "rounded", source = "always", focusable = false } })
    local function apply()
        local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
        vim.api.nvim_set_hl(0, "NormalFloat", { fg = normal.fg, bg = normal.bg })
        vim.api.nvim_set_hl(0, "FloatBorder", { fg = normal.fg, bg = normal.bg })
        vim.api.nvim_set_hl(0, "Pmenu", { fg = normal.fg, bg = normal.bg })
        vim.api.nvim_set_hl(0, "PmenuSel", { fg = normal.fg,
            bg = vim.o.background == "dark" and "#414559" or "#d0d1d4" })
        -- Key hints live in the lower border of the explorer and list windows.
        local info = vim.api.nvim_get_hl(0, { name = "DiagnosticInfo", link = false })
        local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
        vim.api.nvim_set_hl(0, "FooterKey", { fg = info.fg, bg = normal.bg, bold = true })
        vim.api.nvim_set_hl(0, "FooterDesc", { fg = comment.fg, bg = normal.bg })
    end
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("FloatingWindows", { clear = true }), callback = apply,
    })
    apply()
end
return M
