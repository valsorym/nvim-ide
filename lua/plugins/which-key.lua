-- ~/.config/nvim/lua/plugins/which-key.lua
-- Key bindings helper - clean reorganized structure

return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
        local wk = require("which-key")

        wk.setup({
            preset = "modern",
            delay = 100,
            expand = 1,
            notify = false,
            replace = {
                key = {
                    { "<Space>", "SPC" },
                },
            },
            icons = {
                breadcrumb = "»",
                separator = "➜",
                group = "+",
                ellipsis = "…",
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
                    BS = " ",
                    Space = "󱁐 ",
                    Tab = "󰌒 ",
                },
                rules = {
                    { pattern = "close", icon = "󱊷 " },
                    { pattern = "back", icon = " " },
                },
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
            plugins = {
                marks = false,
                registers = false,
                spelling = {
                    enabled = false,
                },
                presets = {
                    operators = false,
                    motions = false,
                    text_objects = false,
                    windows = false,
                    nav = false,
                    z = false,
                    g = false,
                },
            },
            spec = {
                -- WORKSPACE / SESSIONS
                {"<leader>w", group = " Workspaces"},
                {"<leader>ws", desc = "Save Session"},
                {"<leader>wr", desc = "Restore Session"},
                {"<leader>wS", desc = "Restore Last Session"},
                {"<leader>wD", desc = "Don't Save Session"},
                {"<leader>wF", desc = "Find Sessions"},
                {"<leader>ww", desc = "Find Workspaces"},
                {"<leader>wa", desc = "Add Workspace"},
                {"<leader>wq", desc = "Smart Close Tab"},
                {"<leader>wQ", desc = "Force Close Tab"},
                {"<leader>wA", desc = "Close All & Exit"},

                -- FIND / SEARCH / FLASH
                {"<leader>f", group = " Find/Search"},
                {"<leader>ff", desc = "Find Files"},
                {"<leader>fg", desc = "Live Grep"},
                {"<leader>fb", desc = "Find Buffers"},
                {"<leader>fh", desc = "Help Tags"},
                {"<leader>fo", desc = "Old Files"},
                {"<leader>fd", desc = "Document Symbols"},
                {"<leader>fw", desc = "Workspace Symbols"},
                {"<leader>fs", desc = "Flash Jump",
                    mode = {"n", "x", "o"}},
                {"<leader>fS", desc = "Flash Treesitter",
                    mode = {"n", "x", "o"}},
                {"<leader>fr", desc = "Flash Remote", mode = "o"},
                {"<leader>fR", desc = "Flash Search",
                    mode = {"o", "x"}},

                -- EXPLORER / TREE / BUFFERS
                {"<leader>e", group = " Explorer/Buffers"},
                {
                    "<leader>ee",
                    function()
                        if _G.NvimTreeModal then
                            vim.defer_fn(function()
                                _G.NvimTreeModal()
                            end, 100)
                        else
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
                    desc = "Open File Explorer"
                },
                {
                    "<leader>eh",
                    function()
                        if _G.NvimTreeHistory and
                            _G.NvimTreeHistory.show_history then
                            _G.NvimTreeHistory.show_history()
                        else
                            print("Project history not available")
                        end
                    end,
                    desc = "Project History"
                },
                {
                    "<leader>et",
                    function()
                        if _G.TabsList and
                            _G.TabsList.show_tabs_window then
                            _G.TabsList.show_tabs_window()
                        else
                            print("TabsList functionality not loaded")
                        end
                    end,
                    desc = "Show Tabs List"
                },
                {"<leader>eb", desc = "Show Buffers"},
                {"<leader>ed", desc = "Delete Buffer"},
                {"<leader>en", desc = "Next Buffer"},
                {"<leader>ep", desc = "Previous Buffer"},
                {"<leader>eT", desc = "New Tab"},

                -- CODE / LSP / DIAGNOSTICS
                {"<leader>c", group = " Code/LSP"},
                {"<leader>ca", desc = "Code Action"},
                {"<leader>cr", desc = "Rename Symbol"},
                {"<leader>cf", desc = "Format Document"},
                {"<leader>ci", desc = "Sort Imports"},
                {"<leader>cv", desc = "Select Venv"},

                -- Diagnostics
                {"<leader>cc", desc = "Show Line Diagnostics"},
                {"<leader>cC", desc = "Workspace Diagnostics"},
                {"<leader>cl", desc = "Diagnostic List"},
                {"<leader>cq", desc = "Quickfix List"},
                {"<leader>cT", desc = "Toggle WS/Buf"},
                {"<leader>cS", desc = "Diagnostic Summary"},

                -- Symbols
                {"<leader>cs", desc = "Document Symbols"},
                {"<leader>cg", desc = "Symbols (Grouped)"},
                {"<leader>cw", desc = "Workspace Symbols"},

                -- Linters
                {"<leader>ck", group = " Linters"},
                {"<leader>ckd", "<cmd>ToggleDjlint<cr>",
                    desc = "Toggle djlint"},
                {"<leader>ckc", "<cmd>ToggleCodespell<cr>",
                    desc = "Toggle Codespell"},
                {"<leader>cke", "<cmd>ToggleESLint<cr>",
                    desc = "Toggle ESLint"},
                {"<leader>ckf", "<cmd>ToggleFlake8<cr>",
                    desc = "Toggle Flake8"},
                {"<leader>cks", "<cmd>PythonToolsStatus<cr>",
                    desc = "Python Tools Status"},
                {"<leader>ckp", "<cmd>CreatePyprojectToml<cr>",
                    desc = "Create pyproject.toml"},

                -- SYSTEM / CONFIG / TOOLS
                {"<leader>x", group = " System/Tools"},
                {"<leader>xr", desc = "Reload Config"},
                {"<leader>xm", desc = "Mason"},
                {"<leader>xh", desc = "Clear Highlights"},
                {"<leader>xu", desc = "Undotree"},

                -- Terminal
                {"<leader>xt", group = " Terminal"},
                {"<leader>xtf", desc = "Float Terminal"},
                {"<leader>xth", desc = "Horizontal Terminal"},
                {"<leader>xtv", desc = "Vertical Terminal"},
                {"<leader>xtp", desc = "Python Terminal"},
                {"<leader>xtd", desc = "Django Shell"},
                {"<leader>xtr", desc = "Django Runserver"},
                {"<leader>xtn", desc = "Node Terminal"},

                -- GIT
                {"<leader>g", group = " Git"},
                {"<leader>gs", desc = "Stage Hunk"},
                {"<leader>gr", desc = "Reset Hunk"},
                {"<leader>gp", desc = "Preview Hunk"},
                {"<leader>gb", desc = "Blame Line"},
                {"<leader>gd", desc = "Diff This"},
                {"<leader>gt", desc = "Toggle Blame"},

                -- YANK / CLIPBOARD
                {"<leader>y", group = " Yank/Clipboard", mode = "n"},
                {"<leader>ya", desc = "Yank All Buffer", mode = "n"},
                {"<leader>yy", desc = "Yank Selection", mode = "n"},
                {"<leader>yp", desc = "Paste from Clipboard", mode = "n"},

                {"<leader>y", group = " Yank/Clipboard", mode = "v"},
                {"<leader>yy", desc = "Yank Selection", mode = "v"},
                {"<leader>yp", desc = "Paste from Clipboard", mode = "v"},

                -- UI / THEMES
                {"<leader>u", group = " UI/Themes"},
                {"<leader>ut", desc = "Theme Switcher"},
                {"<leader>us", desc = "Set Permanent Theme"},
                {"<leader>ub", desc = "Toggle Background"},
                {"<leader>ui", desc = "Theme Info"},
                {"<leader>uI", "<cmd>IBLToggle<cr>",
                    desc = "Toggle Indent Guides"},

                -- TAB NAVIGATION
                {"<A-Left>", desc = "Previous Tab", mode = "n"},
                {"<A-Right>", desc = "Next Tab", mode = "n"},
                {"<A-h>", desc = "Move Tab Left", mode = "n"},
                {"<A-l>", desc = "Move Tab Right", mode = "n"},
                {"<A-1>", desc = "Go to Tab 1", mode = "n"},
                {"<A-2>", desc = "Go to Tab 2", mode = "n"},
                {"<A-3>", desc = "Go to Tab 3", mode = "n"},
                {"<A-4>", desc = "Go to Tab 4", mode = "n"},
                {"<A-5>", desc = "Go to Tab 5", mode = "n"},
                {"<A-6>", desc = "Go to Tab 6", mode = "n"},
                {"<A-7>", desc = "Go to Tab 7", mode = "n"},
                {"<A-8>", desc = "Go to Tab 8", mode = "n"},
                {"<A-9>", desc = "Go to Tab 9", mode = "n"},

                -- GO TO MAPPINGS
                {"g", group = " Go to"},
                {"gd", desc = "Definition"},
                {"gD", desc = "Declaration"},
                {"gi", desc = "Implementation"},
                {"gr", desc = "References"},
                {"K", desc = "Hover Info"},
                {"gl", desc = "Line Diagnostics"},

                -- BRACKET NAVIGATION
                {"]", group = " Next"},
                {"]d", desc = "Next Diagnostic"},
                {"]c", desc = "Next Git Hunk"},

                {"[", group = " Previous"},
                {"[d", desc = "Previous Diagnostic"},
                {"[c", desc = "Previous Git Hunk"},

                -- FUNCTION KEYS
                {"<F2>", desc = "Save & Format"},
                {"<F5>", desc = "Previous Tab"},
                {"<F6>", desc = "Next Tab"},
                {"<F7>", desc = "Document Symbols"},
                {"<F8>", desc = "Tabs List"},
                {"<F9>", desc = "File Explorer"},
                {"<F10>", desc = "Buffers List"},

                -- DOCUMENT
                {"<leader>d", group = " Document"},
                {"<leader>df", desc = "Format Document"},
                {"<leader>dt", desc = "Toggle Trailing Spaces"},

                -- Spaces/Indentation
                {"<leader>ds", group = " Spaces/Indent"},
                {"<leader>dsi", desc = "Indent Info"},
                {"<leader>dst", function()
                    if vim.bo.expandtab then
                        vim.opt_local.expandtab = false
                        vim.opt_local.tabstop = 4
                        vim.opt_local.shiftwidth = 4
                        vim.opt_local.softtabstop = 0
                        print("Switched to TABS (4 width)")
                    else
                        vim.opt_local.expandtab = true
                        vim.opt_local.tabstop = 4
                        vim.opt_local.shiftwidth = 4
                        vim.opt_local.softtabstop = 4
                        print("Switched to SPACES (4 width)")
                    end
                end, desc = "Toggle Tabs ↔ Spaces"},
                {"<leader>ds2", function()
                    vim.opt_local.expandtab = true
                    vim.opt_local.tabstop = 2
                    vim.opt_local.shiftwidth = 2
                    vim.opt_local.softtabstop = 2
                    print("Set to 2 spaces")
                end, desc = "Set 2 Spaces"},
                {"<leader>ds4", function()
                    vim.opt_local.expandtab = true
                    vim.opt_local.tabstop = 4
                    vim.opt_local.shiftwidth = 4
                    vim.opt_local.softtabstop = 4
                    print("Set to 4 spaces")
                end, desc = "Set 4 Spaces"},
                {"<leader>dst2", desc = "Tabs → Spaces"},
                {"<leader>dss2", desc = "Spaces → Tabs"},

                -- ColorColumn
                {"<leader>dc", group = " ColorColumn"},
                {"<leader>dc1", function()
                    vim.wo.colorcolumn = "79"
                    print("ColorColumn: 79")
                end, desc = "79 symbols"},
                {"<leader>dc2", function()
                    vim.wo.colorcolumn = "120"
                    print("ColorColumn: 120")
                end, desc = "120 symbols"},
                {"<leader>dc0", function()
                    if vim.wo.colorcolumn == "" then
                        vim.wo.colorcolumn = "79"
                        print("ColorColumn: ON (79)")
                    else
                        vim.wo.colorcolumn = ""
                        print("ColorColumn: OFF")
                    end
                end, desc = "Toggle Show/Hide"},

                -- TAB NAVIGATION (Alt keys)
                {"<A-Left>", desc = "Previous Tab", mode = "n"},
                {"<A-Right>", desc = "Next Tab", mode = "n"},

                -- FOLDING
                {"z", group = " Fold"},
                {"zR", desc = "Open All Folds"},
                {"zM", desc = "Close All Folds"},
                {"zr", desc = "Open Folds (Except Kinds)"},
                {"zm", desc = "Close Folds With"},
                {"zp", desc = "Peek Fold/Hover"},
                {"za", desc = "Toggle Fold"},
                {"zA", desc = "Toggle Fold (Recursive)"},
                {"zo", desc = "Open Fold"},
                {"zc", desc = "Close Fold"},

                -- COMMENT PLUGIN
                {"gc", group = " Comment", mode = {"n", "v"}},
                {"gcc", desc = "Toggle line comment", mode = "n"},
                {"gbc", desc = "Toggle block comment", mode = "n"},
                {"gc", desc = "Toggle comment", mode = {"v", "x"}},
                {"gb", desc = "Toggle block comment",
                    mode = {"v", "x"}},
                {"gcO", desc = "Comment line above", mode = "n"},
                {"gco", desc = "Comment line below", mode = "n"},
                {"gcA", desc = "Comment end of line", mode = "n"},

                -- GO TO MAPPINGS
                {"g", group = " Go to"},
                {"gg", desc = "Go to first line", mode = "n"},

                -- TODO COMMENTS
                {"]t", desc = "Next TODO", mode = "n"},
                {"[t", desc = "Previous TODO", mode = "n"},

                -- AERIAL
                {"<leader>a", group = " Aerial"},
                {"<leader>aa", desc = "Toggle Aerial outline",
                    mode = "n"},
                {"<leader>aA", desc = "Toggle Aerial nav", mode = "n"},
                {"<leader>af", desc = "Find symbols (Aerial)",
                    mode = "n"},

                -- SEARCH
                {"<leader>s", group = " Search"},
                {"<leader>st", desc = "Find TODO comments"},
                {"<leader>sT", desc = "Find TODO/FIX"},

            }
        })

        -- Dynamic layout indicator for which-key
        local function get_keyboard_layout()
            -- Try to detect current layout by checking a test character
            local test_char = vim.fn.nr2char(vim.fn.getchar(0))

            -- If we got a Ukrainian character, we're on Ukrainian layout
            local ua_chars = "йцукенгшщзхїфівапролджєячсмитьбю"
            if test_char and ua_chars:find(test_char, 1, true) then
                return " 🇺🇦 UA"
            end

            return ""
        end

        -- Add layout indicator to which-key window title
        local original_show = require("which-key.view").show
        require("which-key.view").show = function(...)
            local result = original_show(...)

            -- Add layout indicator to window title
            vim.defer_fn(function()
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    if vim.bo[buf].filetype == "WhichKey" then
                        local config = vim.api.nvim_win_get_config(win)
                        if config.title then
                            -- Check if we're on Ukrainian layout
                            local layout_indicator = " 🇺🇦"
                            if not config.title[1][1]:find("🇺🇦") then
                                -- Add indicator to title
                                config.title = {
                                    {config.title[1][1] .. layout_indicator,
                                     config.title[1][2] or ""}
                                }
                                pcall(vim.api.nvim_win_set_config, win, config)
                            end
                        end
                    end
                end
            end, 10)

            return result
        end

        -- Force which-key to re-register on buffer change.
        vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
            callback = function()
                -- Re-check leader key mapping.
                local leader_map = vim.fn.maparg("<Space>", "n", false, true)
                if leader_map == "" or leader_map.rhs ~= "<Nop>" then
                    -- Leader key is broken, reset it.
                    vim.keymap.set("n", "<Space>", "<Nop>",
                        {noremap = true, silent = true})
                end
            end,
            desc = "Ensure leader key stays unmapped"
        })

        -- Faster key timeout for responsiveness
        vim.opt.timeoutlen = 300
    end
}