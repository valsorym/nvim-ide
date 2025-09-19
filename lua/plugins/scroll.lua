-- ~/.config/nvim/lua/plugins/scroll.lua
-- Minimal scrollbar for visual file size indication.

return {
    "petertriho/nvim-scrollbar",
    config = function()
        local colors = require("catppuccin.palettes").get_palette("mocha")

        require("scrollbar").setup({
            -- Show scrollbar only when needed.
            show = true,
            show_in_active_only = false,
            set_highlights = true,
            folds = 1000, -- handle large files
            max_lines = false, -- show for any file size
            hide_if_all_visible = true, -- hide if entire file is visible
            throttle_ms = 100,

            -- Handle configuration.
            handle = {
                text = " ",
                blend = 30, -- transparency
                color = colors.surface0,
                color_nr = nil, -- use color instead of color_nr
                highlight = "CursorColumn",
                hide_if_all_visible = true
            },

            -- Marks on scrollbar (diagnostics, search, etc.).
            marks = {
                Cursor = {
                    text = "▒",
                    priority = 0,
                    gui = nil,
                    color = colors.lavender,
                    color_nr = nil,
                    highlight = "Normal"
                },
                Search = {
                    text = { "-", "-" },
                    priority = 1,
                    gui = nil,
                    color = colors.yellow,
                    color_nr = nil,
                    highlight = "Search"
                },
                Error = {
                    text = { "-", "-" },
                    priority = 2,
                    gui = nil,
                    color = colors.red,
                    color_nr = nil,
                    highlight = "DiagnosticVirtualTextError"
                },
                Warn = {
                    text = { "-", "-" },
                    priority = 3,
                    gui = nil,
                    color = colors.peach,
                    color_nr = nil,
                    highlight = "DiagnosticVirtualTextWarn"
                },
                Info = {
                    text = { "-", "-" },
                    priority = 4,
                    gui = nil,
                    color = colors.sky,
                    color_nr = nil,
                    highlight = "DiagnosticVirtualTextInfo"
                },
                Hint = {
                    text = { "-", "-" },
                    priority = 5,
                    gui = nil,
                    color = colors.teal,
                    color_nr = nil,
                    highlight = "DiagnosticVirtualTextHint"
                },
                Misc = {
                    text = { "-", "-" },
                    priority = 6,
                    gui = nil,
                    color = colors.overlay0,
                    color_nr = nil,
                    highlight = "Normal"
                },
                GitAdd = {
                    text = "┃",
                    priority = 7,
                    gui = nil,
                    color = colors.green,
                    color_nr = nil,
                    highlight = "GitSignsAdd"
                },
                GitChange = {
                    text = "┃",
                    priority = 7,
                    gui = nil,
                    color = colors.yellow,
                    color_nr = nil,
                    highlight = "GitSignsChange"
                },
                GitDelete = {
                    text = "▁",
                    priority = 7,
                    gui = nil,
                    color = colors.red,
                    color_nr = nil,
                    highlight = "GitSignsDelete"
                }
            },

            -- Excluded file types (where scrollbar should not appear).
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
                "toggleterm",
                "TelescopePrompt",
                "TelescopeResults",
                "lspinfo",
                "checkhealth",
                "man",
                "gitcommit",
                "gitrebase"
            },

            -- Auto-command setup.
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

            -- Handler configuration.
            handlers = {
                cursor = true,
                diagnostic = true,
                gitsigns = true, -- requires gitsigns.nvim
                handle = true,
                search = true, -- requires hlslens.nvim
                ale = false     -- ALE support disabled
            }
        })

        -- Custom autocmd for better integration
        local scrollbar_group = vim.api.nvim_create_augroup("ScrollbarCustom", { clear = true })

        -- Hide scrollbar in specific windows
        vim.api.nvim_create_autocmd({"FileType", "BufEnter", "WinEnter"}, {
            group = scrollbar_group,
            callback = function()
                local ft = vim.bo.filetype
                local bt = vim.bo.buftype

                -- Additional conditions to hide scrollbar.
                if ft == "dashboard" or
                   ft == "alpha" or
                   ft == "NvimTree" or
                   bt == "terminal" or
                   bt == "nofile" then
                    pcall(require("scrollbar").clear)
                else
                    -- Show scrollbar for normal files.
                    vim.defer_fn(function()
                        pcall(require("scrollbar").show)
                    end, 100)
                end
            end
        })

        -- Refresh scrollbar when diagnostics change.
        vim.api.nvim_create_autocmd("DiagnosticChanged", {
            group = scrollbar_group,
            callback = function()
                pcall(require("scrollbar.handlers.diagnostic").handler)
            end
        })

        -- Integration with search highlighting.
        vim.api.nvim_create_autocmd({"CmdlineEnter", "CmdlineLeave"}, {
            group = scrollbar_group,
            pattern = {"/"}, -- search commands
            callback = function()
                vim.defer_fn(function()
                    pcall(require("scrollbar.handlers.search").handler)
                end, 100)
            end
        })
    end
}