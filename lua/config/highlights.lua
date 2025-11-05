-- ~/.config/nvim/lua/config/highlights.lua
-- Custom Python syntax highlighting with vibrant keywords and softer strings.

local M = {}

function M.setup()
    vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
             -- Multi-line strings with triple quotes (""" or ''').
            vim.api.nvim_set_hl(0, "@string.documentation.python", {
                fg = "#ffb74d",
                italic = true,
            })

            -- Regular strings with single or double quotes.
            vim.api.nvim_set_hl(0, "@string.python", {
                fg = "#4caf50",
            })

            -- Comments - muted and closer to background.
            vim.api.nvim_set_hl(0, "@comment.python", {
                fg = "#6b7280",
                italic = true,
            })

            -- Return keyword - bright burgundy/wine red (very visible)
            vim.api.nvim_set_hl(0, "@keyword.return.python", {
                fg = "#e53935",
                bold = true,
            })

            -- Import keywords.
            vim.api.nvim_set_hl(0, "@keyword.import.python", {
                fg = "#03a9f4",
                bold = true,
            })

            -- Keywords (for, if, else, def, etc.).
            vim.api.nvim_set_hl(0, "@keyword.python", {
                fg = "#03a9f4",
                bold = true,
            })

            -- Function keywords (def, async def, lambda).
            vim.api.nvim_set_hl(0, "@keyword.function.python", {
                fg = "#03a9f4",
                bold = true,
            })

            -- Exception keywords (try, except, finally, raise).
            vim.api.nvim_set_hl(0, "@keyword.exception.python", {
                fg = "#03a9f4",
                bold = true,
            })

            -- Operators (and, or, not, in, is).
            vim.api.nvim_set_hl(0, "@keyword.operator.python", {
                fg = "#03a9f4",
                bold = true,
            })
        end,
    })

    -- Apply highlights immediately
    pcall(function()
        vim.api.nvim_exec_autocmds("ColorScheme", {})
    end)
end

return M