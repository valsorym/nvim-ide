-- ~/.config/nvim/lua/plugins/scroll.lua
-- Minimal scrollbar for visual file size indication.

return {
    "petertriho/nvim-scrollbar",
    config = function()
        local colors = require("catppuccin.palettes").get_palette("mocha")

        require("scrollbar").setup({
            -- Show scrollbar only when needed
            show = true,
            show_in_active_only = false,
            set_highlights = true,
            folds = 1000, -- handle large files
            max_lines = false, -- show for any file size
            hide_if_all_visible = true, -- hide if entire file is visible
            throttle_ms = 100,

            -- Handle configuration
            handle = {
                text = " ",
                blend = 30, -- transparency
                color = colors.surface0,
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
                    color = colors.lavender,
                    color_nr = nil,
                    highlight = "Normal"
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
                "toggleterm",
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

        -- Custom autocmd for better integration with error handling
        local scrollbar_group = vim.api.nvim_create_augroup("ScrollbarCustom", { clear = true })

        -- Safe scrollbar operations with error handling
        local function safe_scrollbar_operation(operation)
            vim.schedule(function()
                local buf = vim.api.nvim_get_current_buf()
                local lines = vim.api.nvim_buf_line_count(buf)

                -- Only operate on valid buffers with content
                if vim.api.nvim_buf_is_valid(buf) and lines > 0 then
                    pcall(operation)
                end
            end)
        end

        -- Hide scrollbar in specific windows
        vim.api.nvim_create_autocmd({"FileType", "BufEnter", "WinEnter"}, {
            group = scrollbar_group,
            callback = function()
                vim.defer_fn(function()
                    local ft = vim.bo.filetype
                    local bt = vim.bo.buftype

                    -- Additional conditions to hide scrollbar
                    if ft == "dashboard" or
                    ft == "alpha" or
                    ft == "NvimTree" or
                    ft == "copilot-chat" or
                    ft == "copilot" or
                    bt == "terminal" or
                    bt == "nofile" then
                        safe_scrollbar_operation(function()
                            require("scrollbar").clear()
                        end)
                    else
                        -- Show scrollbar for normal files
                        safe_scrollbar_operation(function()
                            require("scrollbar").show()
                        end)
                    end
                end, 150) -- Increased delay for stability
            end
        })

        -- Refresh scrollbar when diagnostics change
        vim.api.nvim_create_autocmd("DiagnosticChanged", {
            group = scrollbar_group,
            callback = function()
                safe_scrollbar_operation(function()
                    require("scrollbar.handlers.diagnostic").handler()
                end)
            end
        })

        -- Integration with search highlighting
        vim.api.nvim_create_autocmd({"CmdlineEnter", "CmdlineLeave"}, {
            group = scrollbar_group,
            pattern = {"/"}, -- search commands
            callback = function()
                safe_scrollbar_operation(function()
                    require("scrollbar.handlers.search").handler()
                end)
            end
        })
    end
}