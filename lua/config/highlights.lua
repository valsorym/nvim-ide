-- ~/.config/nvim/lua/config/highlights.lua
-- Custom Python syntax highlighting with vibrant keywords and softer strings

local M = {}

function M.setup()
    vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
             -- Multi-line strings with triple quotes (""" or ''') - orange-tinted
            vim.api.nvim_set_hl(0, "@string.documentation.python", {
                fg = "#a4d88c",  -- orange
                italic = true,
            })

            -- Regular strings with single or double quotes - green-tinted
            vim.api.nvim_set_hl(0, "@string.python", {
                fg = "#4ade80",  -- green
            })

            -- Keywords (for, if, else, def, import, from, etc.) - vibrant saturated purple/blue
            vim.api.nvim_set_hl(0, "@keyword.python", {
                fg = "#a78bfa",  -- vibrant purple
                bold = true,
            })

            -- Function keywords (def, async def, lambda) - bright blue
            vim.api.nvim_set_hl(0, "@keyword.function.python", {
                fg = "#60a5fa",  -- bright saturated blue
                bold = true,
            })

            -- Return keyword - bright burgundy/wine red (very visible)
            vim.api.nvim_set_hl(0, "@keyword.return.python", {
                fg = "#dc2626",  -- bright red
                bold = true,
            })

            -- Yield keyword - bright burgundy/wine red (same as return)
            vim.api.nvim_set_hl(0, "@keyword.coroutine.python", {
                fg = "#dc2626",  -- bright red
                bold = true,
            })

            -- Conditionals (if, elif, else) - vibrant cyan
            vim.api.nvim_set_hl(0, "@keyword.conditional.python", {
                fg = "#22d3ee",  -- bright cyan
                bold = true,
            })

            -- Loops (for, while) - vibrant yellow-orange
            vim.api.nvim_set_hl(0, "@keyword.repeat.python", {
                fg = "#fbbf24",  -- bright yellow
                bold = true,
            })

            -- Import keywords - vibrant magenta
            vim.api.nvim_set_hl(0, "@keyword.import.python", {
                fg = "#e879f9",  -- bright magenta
                bold = true,
            })

            -- Exception keywords (try, except, finally, raise) - vibrant orange
            vim.api.nvim_set_hl(0, "@keyword.exception.python", {
                fg = "#fb923c",  -- bright orange
                bold = true,
            })

            -- Operators (and, or, not, in, is) - vibrant teal
            vim.api.nvim_set_hl(0, "@keyword.operator.python", {
                fg = "#14b8a6",  -- bright teal
                bold = true,
            })



            -- Comments - muted and closer to background
            vim.api.nvim_set_hl(0, "@comment.python", {
                fg = "#6b7280",  -- gray muted
                italic = true,
            })

            -- Builtins - soft orange
            vim.api.nvim_set_hl(0, "@function.builtin.python", {
                fg = "#fda4af",
                bold = false,
            })

            -- Constants - soft blue
            vim.api.nvim_set_hl(0, "@constant.builtin.python", {
                fg = "#93c5fd",
                bold = false,
            })

            -- Functions - balanced cyan
            vim.api.nvim_set_hl(0, "@function.python", {
                fg = "#67e8f9",
                bold = false,
            })

            -- Classes - soft yellow
            vim.api.nvim_set_hl(0, "@type.python", {
                fg = "#fcd34d",
                bold = false,
            })

            -- Variables - soft white
            vim.api.nvim_set_hl(0, "@variable.python", {
                fg = "#e5e7eb",
            })

            -- Numbers - soft purple
            vim.api.nvim_set_hl(0, "@number.python", {
                fg = "#c4b5fd",
            })

            -- Boolean - soft pink
            vim.api.nvim_set_hl(0, "@boolean.python", {
                fg = "#fda4af",
            })

            -- None - soft gray
            vim.api.nvim_set_hl(0, "@constant.builtin.none.python", {
                fg = "#9ca3af",
                italic = true,
            })
        end,
    })

    -- Apply highlights immediately
    pcall(function()
        vim.api.nvim_exec_autocmds("ColorScheme", {})
    end)
end

return M