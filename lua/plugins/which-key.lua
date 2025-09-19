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
                    -- EXPLORER - New group for file management
                    {"<leader>e", group = " Explorer"},
                    {
                        "<leader>ee",
                        function()
                            vim.defer_fn(
                                function()
                                    _G.NvimTreeModal()
                                end,
                                100
                            )
                        end,
                        desc = "• Open File Explorer"
                    },
                    {"<leader>et", desc = "• Show Tabs List"},
                    {"<leader>eb", desc = "• Show Buffers List"},
                    -- FILES
                    {"<leader>f", group = " Files"},
                    {"<leader>ff", desc = "• Find Files"},
                    {"<leader>fr", desc = "• Recent Files"},
                    {"<leader>fs", desc = "• Save File"},
                    {"<leader>fn", desc = "• New File"},
                    -- YANK / CLIPBOARD (Normal mode)
                    {"<leader>y", group = " Yank/Clipboard", mode = "n"},
                    {"<leader>ya", desc = "• Yank entire buffer to clipboard", mode = "n"},
                    {"<leader>yy", desc = "• Yank selection to clipboard", mode = "n"},
                    {"<leader>yp", desc = "• Paste from clipboard", mode = "n"},
                    -- YANK / CLIPBOARD (Visual mode)
                    {"<leader>y", group = " Yank/Clipboard", mode = "v"},
                    {"<leader>yy", desc = "• Yank selection to clipboard", mode = "v"},
                    {"<leader>yp", desc = "• Paste from clipboard", mode = "v"},
                    -- SEARCH
                    {"<leader>s", group = " Search"},
                    {"<leader>sg", desc = "• Live Grep"},
                    {"<leader>sb", desc = "• Search Buffers"},
                    {"<leader>sh", desc = "• Help Tags"},
                    {"<leader>ss", desc = "• Document Symbols"},
                    {"<leader>sw", desc = "• Workspace Symbols"},
                    -- BUFFERS / TABS
                    {"<leader>b", group = " Buffers/Tabs"},
                    {"<leader>bb", desc = "• List Buffers"},
                    {"<leader>bd", desc = "• Delete Buffer"},
                    {"<leader>bn", desc = "• Next Buffer"},
                    {"<leader>bp", desc = "• Previous Buffer"},
                    {"<leader>tt", desc = "• Tabs List"},
                    {"<A-Left>", desc = "• Previous Tab", mode = "n"},
                    {"<A-Right>", desc = "• Next Tab", mode = "n"},
                    {"<A-h>", desc = "• Move Tab Left", mode = "n"},
                    {"<A-l>", desc = "• Move Tab Right", mode = "n"},
                    -- GIT
                    {"<leader>g", group = " Git"},
                    {"<leader>gs", desc = "• Stage Hunk"},
                    {"<leader>gr", desc = "• Reset Hunk"},
                    {"<leader>gp", desc = "• Preview Hunk"},
                    {"<leader>gb", desc = "• Blame Line"},
                    {"<leader>gd", desc = "• Diff This"},
                    -- LSP / CODE
                    {"<leader>c", group = " Code/LSP"},
                    {"<leader>ca", desc = "• Code Action"},
                    {"<leader>rn", desc = "• Rename Symbol"},
                    {"<leader>F", desc = "• Format Document"},
                    {"g", group = " Go to..."},
                    {"gd", desc = "• Definition"},
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
                    -- TERMINAL / TOOLS
                    {"<leader>t", group = " Terminal/Tools"},
                    {"<leader>tf", desc = "• Float Terminal"},
                    {"<leader>th", desc = "• Horizontal Terminal"},
                    {"<leader>tv", desc = "• Vertical Terminal"},
                    {"<leader>tb", desc = "• Toggle Git Blame"},
                    {"<leader>m", desc = "• Mason"},
                    {"<leader>v", desc = "• Select Python Venv"},
                    -- OPTIONS
                    {"<leader>o", group = " Options"},
                    {"<leader>oh", desc = "• Clear Highlights"},
                    -- QUIT / TABS
                    {"<leader>q", group = " Quit/Tabs"},
                    {"<leader>qq", desc = "• Close Current Tab"},
                    {"<leader>qa", desc = "• Close All Tabs & Exit"},
                    {"<leader>qQ", desc = "• Force Close Current Tab"},
                    {"<leader>qA", desc = "• Force Close All Tabs & Exit"},
                    -- FUNCTION KEYS - Updated with F10
                    {"<F2>", desc = "• Save & Format"},
                    {"<F5>", desc = "• Previous Tab"},
                    {"<F6>", desc = "• Next Tab"},
                    {"<F8>", desc = "• Show Tabs List"},
                    {"<F9>", desc = "• Open File Explorer"},
                    {"<F10>", desc = "• Show Buffers List"}
                }
            }
        )

        -- Faster key timeout for responsiveness.
        vim.opt.timeoutlen = 300
    end
}
