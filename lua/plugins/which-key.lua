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
                delay = 100,
                expand = 1,
                notify = false,
                icons = {
                    mappings = false,
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
                    padding = {3, 3},
                    title = true,
                    title_pos = "center",
                    zindex = 1000,
                    wo = {winblend = 10}
                },
                layout = {
                    width = {min = 20},
                    spacing = 3
                },
                triggers = {
                    {"<leader>", mode = {"n", "v"}},
                    {"g", mode = {"n", "v"}},
                    {"]", mode = "n"},
                    {"[", mode = "n"},
                    {"z", mode = "n"}
                },
                spec = {
                    -- EXPLORER
                    {"<leader>e", group = " Explorer"},
                    {
                        "<leader>ee",
                        function()
                            if _G.NvimTreeModal then
                                vim.defer_fn(function()
                                    _G.NvimTreeModal()
                                end, 100)
                            else
                                -- Fallback to direct API call
                                local api = require("nvim-tree.api")
                                if api.tree.is_visible() then
                                    api.tree.close()
                                else
                                    api.tree.open({
                                        current_window = false,
                                        find_file = false,
                                        update_root = false
                                    })
                                end
                            end
                        end,
                        desc = "· Open File Explorer"
                    },
                    {
                        "<leader>eh",
                        function()
                            if _G.NvimTreeHistory and _G.NvimTreeHistory.show_history then
                                _G.NvimTreeHistory.show_history()
                            else
                                print("Project history not available")
                            end
                        end,
                        desc = "· Project History"
                    },
                    {
                        "<leader>et",
                        function()
                            if _G.TabsList and _G.TabsList.show_tabs_window then
                                _G.TabsList.show_tabs_window()
                            else
                                print("TabsList functionality not loaded yet")
                            end
                        end,
                        desc = "· Show Tabs List"
                    },
                    {"<leader>eb", desc = "· Show Buffers List"},

                    -- FIND / SEARCH
                    {"<leader>f", group = " Find/Search"},
                    {"<leader>ff", desc = "· Find Files"},
                    {"<leader>fg", desc = "· Live Grep (search in files)"},
                    {"<leader>fb", desc = "· Find Buffers"},
                    {"<leader>fh", desc = "· Help Tags"},
                    {"<leader>fs", desc = "· Document Symbols (LSP)"},
                    {"<leader>fw", desc = "· Workspace Symbols (LSP)"},

                    -- YANK / CLIPBOARD (Normal)
                    {"<leader>y", group = " Yank/Clipboard", mode = "n"},
                    {"<leader>ya", desc = "· Yank entire buffer", mode = "n"},
                    {"<leader>yy", desc = "· Yank selection", mode = "n"},
                    {"<leader>yp", desc = "· Paste from clipboard", mode = "n"},

                    -- YANK / CLIPBOARD (Visual)
                    {"<leader>y", group = " Yank/Clipboard", mode = "v"},
                    {"<leader>yy", desc = "· Yank selection", mode = "v"},
                    {"<leader>yp", desc = "· Paste from clipboard", mode = "v"},

                    -- BUFFERS / TABS
                    {"<leader>b", group = " Buffers/Tabs"},
                    {"<leader>bb", desc = "· List Buffers"},
                    {"<leader>bd", desc = "· Delete Buffer"},
                    {"<leader>bn", desc = "· Next Buffer"},
                    {"<leader>bp", desc = "· Previous Buffer"},
                    -- {"<leader>tt", desc = "· Tabs List"},
                    {"<A-Left>", desc = "· Previous Tab", mode = "n"},
                    {"<A-Right>", desc = "· Next Tab", mode = "n"},
                    {"<A-h>", desc = "· Move Tab Left", mode = "n"},
                    {"<A-l>", desc = "· Move Tab Right", mode = "n"},

                    -- GIT
                    {"<leader>g", group = " Git"},
                    {"<leader>gs", desc = "· Stage Hunk"},
                    {"<leader>gr", desc = "· Reset Hunk"},
                    {"<leader>gp", desc = "· Preview Hunk"},
                    {"<leader>gb", desc = "· Blame Line"},
                    {"<leader>gd", desc = "· Diff This"},

                    -- CODE / LSP
                    {"<leader>c", group = " Code/LSP"},
                    {"<leader>ca", desc = "· Code Action"},
                    {"<leader>rn", desc = "· Rename Symbol"},
                    {"<leader>F", desc = "· Format Document"},
                    {"g", group = " Go to..."},
                    {"gd", desc = "· Definition"},
                    {"gD", desc = "· Declaration"},
                    {"gi", desc = "· Implementation"},
                    {"gr", desc = "· References"},
                    {"K", desc = "· Hover Info"},

                    -- Linters.
                    {"<leader>k", group = " Linters"},
                    -- {"<leader>km", "<cmd>ToggleMyPy<cr>",
                    --     desc = "· Toggle MyPy"},
                    {"<leader>kd", "<cmd>ToggleDjlint<cr>",
                        desc = "· Toggle djlint (Django)"},
                    {"<leader>kc", "<cmd>ToggleCodespell<cr>",
                        desc = "· Toggle Codespell"},
                    {"<leader>ke", "<cmd>ToggleESLint<cr>",
                        desc = "· Toggle ESLint"},
                    {"<leader>kf", "<cmd>ToggleFlake8<cr>",
                        desc = "· Toggle Flake8"},

                    -- Diagnostics
                    {"<leader>x", group = " Diagnostics"},
                    {"<leader>xx", desc = "· Show Line Diagnostics"},
                    {"<leader>xl", desc = "· Open Diagnostic List"},
                    {"gl", desc = "· Show Line Diagnostics"},
                    {"]d", desc = "· Next Diagnostic"},
                    {"[d", desc = "· Previous Diagnostic"},

                    -- Options.
                    {"<leader>h", desc = "· Clear Search Highlights"},

                    -- Quit / Tabs.
                    {"<leader>q", group = " Quit/Sessions"},  -- expand an existing group
                    {"<leader>qs", desc = "· Restore Session"},
                    {"<leader>ql", desc = "· Restore Last Session"},
                    {"<leader>qd", desc = "· Don't Save Session"},
                    {"<leader>qq", desc = "· Smart Close Current Tab"},
                    {"<leader>qa", desc = "· Close All Tabs & Exit"},
                    {"<leader>qQ", desc = "· Force Close Current Tab"},
                    {"<leader>qA", desc = "· Force Close All Tabs & Exit"},

                    -- Function keys.
                    {"<F2>", desc = "· Save & Format"},
                    {"<F5>", desc = "· Previous Tab"},
                    {"<F6>", desc = "· Next Tab"},
                    {"<F7>", desc = "· Show Document Symbols"},
                    {"<F8>", desc = "· Show Tabs List"},
                    {"<F9>", desc = "· Open File Explorer"},
                    {"<F10>", desc = "· Show Buffers List"},

                    -- UI / Themes.
                    {"<leader>u", group = " UI/Themes"},
                    {"<leader>ut", desc = "· Theme Switcher"},
                    {"<leader>ub", desc = "· Toggle Background"},
                    {
                        "<leader>uI",
                        "<cmd>IBLToggle<cr>",
                        desc = "· Toggle Indent Guides"
                    },
                    {"<leader>uG", function()
                        if vim.wo.colorcolumn == "" then
                            vim.wo.colorcolumn = "79"
                            print("ColorColumn: ON")
                        else
                            vim.wo.colorcolumn = ""
                            print("ColorColumn: OFF")
                        end
                    end, desc = "· Toggle ColorColumn"},
                    {"<leader>us", desc = "· Set Permanent Theme"},
                    {"<leader>ug", desc = "· Toggle Indent Guides"},
                    {"<leader>uc", desc = "· Toggle ColorColumn"},
                    {"<leader>ui", desc = "· Show Indent Info"},
                    {"<leader>ut2", desc = "· Tabs → Spaces"},
                    {"<leader>us2", desc = "· Spaces → Tabs"},
                    {"<leader>u2", desc = "· Set 2 Spaces"},
                    {"<leader>u4", desc = "· Set 4 Spaces"},

                    -- LSP / Symbols.
                    {"<leader>l", group = " LSP/Symbols"},
                    {"<leader>ls", desc = "· Document Symbols (modal)"},

                    -- Flash navigation.
                    {"<leader>s", group = " Flash Navigation"},
                    {"s", desc = "· Flash Jump", mode = {"n", "x", "o"}},
                    {"S", desc = "· Flash Treesitter", mode = {"n", "x", "o"}},

                    -- Terminal / Tools.
                    {"<leader>t", group = " Terminal/Tools"},
                    {"<leader>tf", desc = "· Float Terminal"},
                    {"<leader>th", desc = "· Horizontal Terminal"},
                    {"<leader>tv", desc = "· Vertical Terminal"},
                    {"<leader>tb", desc = "· Toggle Git Blame"},
                    {"<leader>tn", desc = "· New Tab"},
                    {"<leader>tp", desc = "· Python Terminal"},
                    {"<leader>td", desc = "· Django Shell"},
                    {"<leader>tr", desc = "· Django Runserver"},
                    {"<leader>tN", desc = "· Node Terminal"},
                    {"<leader>m", desc = "· Mason"},
                    {"<leader>vs", desc = "· Select Python Venv"},
                    {"<leader>R", desc = "· Reload Vim Config"},

                    -- Mason.
                    {"<leader>m", desc = "· Mason"},
                    {"<leader>vs", desc = "· Select Python Venv"},
                }
            }
        )

        -- Faster key timeout for responsiveness.
        vim.opt.timeoutlen = 300
    end
}
