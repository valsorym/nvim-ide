-- ~/.config/nvim/lua/config/highlights.lua
-- Softer, elegant Python syntax colors.

local M = {}

function M.setup()
    vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
            -- Triple-quoted strings (docstrings).
            vim.api.nvim_set_hl(0, "@string.documentation.python", {
                fg = "#e6a55c",
                italic = true,
            })

            -- Normal strings ('...' or "...").
            vim.api.nvim_set_hl(0, "@string.python", {
                fg = "#6cc570",
                italic = true,
            })

            -- Comments - keep subtle and soft.
            vim.api.nvim_set_hl(0, "@comment.python", {
                fg = "#6b7280",
                italic = true,
            })

            -- Keywords return / yield.
            vim.api.nvim_set_hl(0, "@keyword.return.python", {
                fg = "#c25b5b",
                bold = true,
            })

            vim.api.nvim_set_hl(0, "@keyword.yield.python", {
                fg = "#c25b5b",
                bold = true,
            })

            -- Function names (after 'def' keyword).
            vim.api.nvim_set_hl(0, "@function.python", {
                fg = "#4fd3c4",
                -- bold = true,
            })

            -- Import and general keywords.
            vim.api.nvim_set_hl(0, "@keyword.import.python", {
                fg = "#5fa8d3",
                bold = true,
            })

            vim.api.nvim_set_hl(0, "@keyword.python", {
                fg = "#5fa8d3",
                bold = true,
            })

            vim.api.nvim_set_hl(0, "@keyword.function.python", {
                fg = "#5fa8d3",
                bold = true,
            })

            vim.api.nvim_set_hl(0, "@keyword.exception.python", {
                fg = "#5fa8d3",
                bold = true,
            })

            vim.api.nvim_set_hl(0, "@keyword.operator.python", {
                fg = "#5fa8d3",
                bold = true,
            })
        end,
    })

    -- Apply highlights right away.
    pcall(function()
        vim.api.nvim_exec_autocmds("ColorScheme", {})
    end)
end

return M
