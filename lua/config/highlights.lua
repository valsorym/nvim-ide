-- ~/.config/nvim/lua/config/highlights.lua
-- Softer Python highlight palette.

local M = {}

function M.setup()
    vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
            -- Python docstrings - soft green
            vim.api.nvim_set_hl(0, "@string.documentation.python", {
                fg = "#a4d88c",
                italic = true,
            })

            -- Multi-line strings - gentle mint
            vim.api.nvim_set_hl(0, "@string.python", {
                fg = "#b2e3a4",
            })

            -- Keywords - muted lavender
            vim.api.nvim_set_hl(0, "@keyword.python", {
                fg = "#b6aaf8",
                bold = false,
            })

            -- Keyword functions - calm sky-blue
            vim.api.nvim_set_hl(0, "@keyword.function.python", {
                fg = "#8fbce6",
                bold = false,
            })

            -- Return - soft coral
            vim.api.nvim_set_hl(0, "@keyword.return.python", {
                fg = "#e79a9a",
                bold = false,
            })

            -- Conditionals - light teal
            vim.api.nvim_set_hl(0, "@keyword.conditional.python", {
                fg = "#8dcacb",
                bold = false,
            })

            -- Loops - warm beige
            vim.api.nvim_set_hl(0, "@keyword.repeat.python", {
                fg = "#d8c48f",
                bold = false,
            })

            -- Builtins - mellow orange
            vim.api.nvim_set_hl(0, "@function.builtin.python", {
                fg = "#d7af85",
                bold = false,
            })

            -- Constants - desaturated rose
            vim.api.nvim_set_hl(0, "@constant.builtin.python", {
                fg = "#d78d94",
                bold = false,
            })

            -- Functions - balanced blue
            vim.api.nvim_set_hl(0, "@function.python", {
                fg = "#8fbfe5",
                bold = false,
            })

            -- Classes - soft gold
            vim.api.nvim_set_hl(0, "@type.python", {
                fg = "#e5cfa3",
                bold = false,
            })
        end,
    })

    pcall(function()
        vim.api.nvim_exec_autocmds("ColorScheme", {})
    end)
end

return M
