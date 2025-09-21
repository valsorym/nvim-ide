-- ~/.config/nvim/lua/plugins/which-key.lua
-- Key bindings helper - popup with navigation menu.

return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
        local wk = require("which-key")

        wk.setup(
            {
                preset = "modern",
                delay = 100, -- faster popup
                expand = 1,
                notify = false, -- disable notifications for speed
                icons = {
                    mappings = false, -- disable icons in submenus
                    keys = {
                        Up = " ",
                        Down = " ",
                        Left = " ",
                        Right = " ",
                        C = "󰘴 ",
                        M = "󰘵 ",
                        S = "󰘶 ",
                        CR = "󰌑 ",
                        Esc = "󱊷 ",
                        ScrollWheelDown = "󱕐 ",
                        ScrollWheelUp = "󱕑 ",
                        NL = "󰌑 ",
                        BS = "↩ ",
                        Space = "󱁐 ",
                        Tab = "󰌒 "
                    }
                },
                win = {
                    no_overlap = true,
                    padding = {3, 3}, -- compact padding
                    title = true,
                    title_pos = "center",
                    zindex = 1000,
                    wo = {winblend = 10}
                },
                layout = {
                    width = {min = 20}, -- minimum menu width
                    spacing = 3 -- spacing between items
                },
                triggers = {
                    {"<leader>", mode = {"n", "v"}},
                    {"g", mode = {"n", "v"}},
                    {"]", mode = "n"},
                    {"[", mode = "n"},
                    {"z", mode = "n"} -- folds
                },
                spec = {
                    -- EXPLORER - Updated for new nvim-tree behavior
                    {"<leader>e", group = " Explorer"},
                    {"<leader>ee", desc = "• Toggle File Explorer"},
                    {"<leader>ef", desc = "• Find File in Explorer"},
                    {"<leader>ec", desc = "• Close File Explorer"},
                    {"<leader>er", desc = "• Refresh File Explorer"},
                    {"<leader>et", desc = "• Show Tabs List"},
                    {"<leader>eb", desc = "• Show Buffers List"},

                    -- FILES & SEARCH - Fixed section
                    {"<leader>f", group = " Find/Search"},
                    {"<leader>ff", desc = "• Find Files"},
                    {"<leader>fg", desc = "• Live Grep (search in files)"},
                    {"<leader>fb", desc = "• Find Buffers"},
                    {"<leader>fh", desc = "• Help Tags"},
                    {"<leader>fs", desc = "• Document Symbols (LSP)"},
                    {"<leader>fw", desc = "• Workspace Symbols (LSP)"},

                    -- YANK / CLIPBOARD (Normal mode)
                    {"<leader>y", group = " Yank/Clipboard", mode = "n"},
                    {"<leader>ya", desc = "• Yank entire buffer to clipboard", mode = "n"},
                    {"<leader>yy", desc = "• Yank selection to clipboard", mode = "n"},
                    {"<leader>yp", desc = "• Paste from clipboard", mode = "n"},

                    -- YANK / CLIPBOARD (Visual mode)
                    {"<leader>y", group = " Yank/Clipboard", mode = "v"},
                    {"<leader>yy", desc = "• Yank selection to clipboard", mode = "v"},
                    {"<leader>yp", desc = "• Paste from clipboard", mode = "v"},

                    -- BUFFERS - Updated for vim-way approach
                    {"<leader>b", group = " Buffers"},
                    {"<leader>bb", desc = "• List Buffers"},
                    {"<leader>bd", desc = "• Delete Buffer (keep window)"},
                    {"<leader>bD", desc = "• Force Delete Buffer"},
                    {"<leader>bn", desc = "• Next Buffer"},
                    {"<leader>bp", desc = "• Previous Buffer"},

                    -- TABS - Updated for proper tab usage (workspaces)
                    {"<leader>t", group = " Tabs/Terminal/Tools"},
                    {"<leader>tn", desc = "• New Tab (workspace)"},
                    {"<leader>tc", desc = "• Close Tab"},
                    {"<leader>to", desc = "• Close Other Tabs"},
                    {"<leader>tm", desc = "• Move Tab"},

                    -- Tab navigation
                    {"gt", desc = "• Next Tab", mode = "n"},
                    {"gT", desc = "• Previous Tab", mode = "n"},
                    {"<A-1>", desc = "• Go to Tab 1", mode = "n"},
                    {"<A-2>", desc = "• Go to Tab 2", mode = "n"},
                    {"<A-3>", desc = "• Go to Tab 3", mode = "n"},
                    {"<A-4>", desc = "• Go to Tab 4", mode = "n"},
                    {"<A-5>", desc = "• Go to Tab 5", mode = "n"},

                    -- WINDOW MANAGEMENT - New section for splits
                    {"<leader>s", group = " Splits/Windows"},
                    {"<leader>sv", desc = "• Vertical Split"},
                    {"<leader>sh", desc = "• Horizontal Split"},
                    {"<leader>se", desc = "• Equalize Splits"},
                    {"<leader>sc", desc = "• Close Current Window"},
                    {"<leader>so", desc = "• Close Other Windows"},

                    -- Window navigation
                    {"<C-h>", desc = "• Go to Left Window", mode = "n"},
                    {"<C-j>", desc = "• Go to Lower Window", mode = "n"},
                    {"<C-k>", desc = "• Go to Upper Window", mode = "n"},
                    {"<C-l>", desc = "• Go to Right Window", mode = "n"},

                    -- GIT
                    {"<leader>g", group = " Git"},
                    {"<leader>hs", desc = "• Stage Hunk"},
                    {"<leader>hr", desc = "• Reset Hunk"},
                    {"<leader>hp", desc = "• Preview Hunk"},
                    {"<leader>hb", desc = "• Blame Line"},
                    {"<leader>hd", desc = "• Diff This"},

                    -- LSP / CODE
                    {"<leader>c", group = " Code/LSP"},
                    {"<leader>ca", desc = "• Code Action"},
                    {"<leader>rn", desc = "• Rename Symbol"},
                    {"<leader>F", desc = "• Format Document"},

                    -- Go to mappings
                    {"g", group = " Go to..."},
                    {"gd", desc = "• Definition (new tab if different file)"},
                    {"gD", desc = "• Declaration"},
                    {"gi", desc = "• Implementation"},
                    {"gr", desc = "• References"},
                    {"K", desc = "• Hover Info"},

                    -- DIAGNOSTICS
                    {"<leader>x", group = " Diagnostics"},
                    {"<leader>xx", desc = "• Show Line Diagnostics"},
                    {"<leader>xl", desc = "• Open Diagnostic List"},
                    {"gl", desc = "• Show Line Diagnostics"},
                    {"]d", desc = "• Next Diagnostic"},
                    {"[d", desc = "• Previous Diagnostic"},

                    -- TERMINAL - Updated section
                    {"<leader>tf", desc = "• Float Terminal"},
                    {"<leader>th", desc = "• Horizontal Terminal"},
                    {"<leader>tv", desc = "• Vertical Terminal"},
                    {"<leader>tp", desc = "• Python Terminal"},
                    {"<leader>td", desc = "• Django Shell"},
                    {"<leader>tr", desc = "• Django Runserver"},
                    {"<leader>tn", desc = "• Node Terminal"},

                    -- TOOLS
                    {"<leader>m", desc = "• Mason"},
                    {"<leader>vs", desc = "• Select Python Venv"},
                    {"<leader>tb", desc = "• Toggle Git Blame"},

                    -- OPTIONS
                    {"<leader>h", desc = "• Clear Search Highlights"},

                    -- QUIT - Updated with safe exit logic
                    {"<leader>q", group = " Quit (Safe Exit)"},
                    {"<leader>qq", desc = "• Smart Quit (Buffer→Tab→Dashboard)"},
                    {"<leader>qa", desc = "• Emergency Exit (Close All)"},
                    {"<leader>qQ", desc = "• Force Quit Buffer"},
                    {"<leader>qA", desc = "• Force Exit All"},

                    -- FUNCTION KEYS
                    {"<F2>", desc = "• Save & Format"},
                    {"<F7>", desc = "• Code Inspector"},
                    {"<F9>", desc = "• Toggle File Explorer"},
                    {"<F10>", desc = "• Show Buffers List"},

                    -- LSP SYMBOLS
                    {"<leader>l", group = " LSP/Symbols"},
                    {"<leader>ls", desc = "• Document Symbols"},
                    {"<leader>lg", desc = "• Document Symbols (grouped)"},
                    {"<leader>lw", desc = "• Workspace Symbols"},

                    -- UI / THEMES
                    {"<leader>u", group = " UI/Themes"},
                    {"<leader>ut", desc = "• Theme Switcher"},
                    {"<leader>ub", desc = "• Toggle Background"},

                    -- BUFFER NAVIGATION - Quick access
                    {"<C-n>", desc = "• Next Buffer", mode = "n"},
                    {"<C-p>", desc = "• Previous Buffer", mode = "n"},
                    {"]b", desc = "• Next Buffer", mode = "n"},
                    {"[b", desc = "• Previous Buffer", mode = "n"},
                    {"<leader><leader>", desc = "• Quick Buffer Switcher"},
                }
            }
        )

        -- Faster key timeout for responsiveness
        vim.opt.timeoutlen = 300
    end
}