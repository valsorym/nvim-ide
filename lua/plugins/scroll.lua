-- ~/.config/nvim/lua/plugins/scroll.lua
-- Minimal scrollbar for visual file size indication.

return {
    "petertriho/nvim-scrollbar",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        require("scrollbar").setup({
            -- Show scrollbar only when needed
            show = true,
            show_in_active_only = true,
            set_highlights = true,
            folds = 1000, -- handle large files
            max_lines = 20000, -- skip large buffers
            hide_if_all_visible = true, -- hide if entire file is visible
            throttle_ms = 100,

            -- Handle configuration
            handle = {
                text = " ",
                blend = 30, -- transparency
                color_nr = nil, -- use color instead of color_nr
                highlight = "CursorColumn",
                hide_if_all_visible = true
            },

            -- Marks on scrollbar (diagnostics only)
            marks = {
                Cursor = {
                    text = "▒",
                    priority = 0,
                    gui = nil,
                    color_nr = nil,
                    highlight = "Normal"
                },
                Error = {
                    text = { "-", "-" },
                    priority = 2,
                    gui = nil,
                    color_nr = nil,
                    highlight = "DiagnosticVirtualTextError"
                },
                Warn = {
                    text = { "-", "-" },
                    priority = 3,
                    gui = nil,
                    color_nr = nil,
                    highlight = "DiagnosticVirtualTextWarn"
                },
                Info = {
                    text = { "-", "-" },
                    priority = 4,
                    gui = nil,
                    color_nr = nil,
                    highlight = "DiagnosticVirtualTextInfo"
                },
                Hint = {
                    text = { "-", "-" },
                    priority = 5,
                    gui = nil,
                    color_nr = nil,
                    highlight = "DiagnosticVirtualTextHint"
                }
            },

            -- Excluded file types (where scrollbar should not appear)
            excluded_buftypes = {
                "terminal",
                "nofile",
                "quickfix",
                "prompt"
            },
            excluded_filetypes = {
                "dashboard",
                "alpha",
                "NvimTree",
                "neo-tree",
                "oil",
                "mason",
                "lazy",
                "help",
                "TelescopePrompt",
                "TelescopeResults",
                "lspinfo",
                "checkhealth",
                "man",
                "gitcommit",
                "gitrebase",
                "copilot-chat",
                "copilot",
                "noice"
            },

            -- Auto-command setup
            autocmd = {
                render = {
                    "BufWinEnter",
                    "TabEnter",
                    "TermEnter",
                    "WinEnter",
                    "CmdwinLeave",
                    "TextChanged",
                    "VimResized",
                    "WinScrolled"
                },
                clear = {
                    "BufWinLeave",
                    "TabLeave",
                    "TermLeave",
                    "WinLeave"
                }
            },

            -- Handler configuration
            handlers = {
                cursor = true,
                diagnostic = true,
                gitsigns = false, -- disabled - already shown in sign column
                handle = true,
                search = false, -- disabled - hlslens not installed
                ale = false
            }
        })

    end,
}
