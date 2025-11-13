-- ~/.config/nvim/lua/plugins/legendary.lua
-- Centralized command palette with layout-aware keymaps and Telescope UI.

return {
    "mrjones2014/legendary.nvim",
    priority = 10000,
    lazy = false,
    dependencies = {
        "kkharji/sqlite.lua",
        "nvim-telescope/telescope.nvim",
    },
    keys = {
        {
            "<leader><leader>",
            function()
                require("legendary").find()
            end,
            mode = { "n", "v" },
            desc = "🔍 Search All Commands"
        },
        {
            "<C-p>",
            function()
                require("legendary").find({
                    filters = { require("legendary.filters").keymaps() }
                })
            end,
            mode = { "n", "v" },
            desc = "⌨️  Search Keymaps"
        },
        {
            "<leader>:",
            function()
                require("legendary").find({
                    filters = { require("legendary.filters").commands() }
                })
            end,
            mode = { "n" },
            desc = "📝 Search Commands"
        },
        {
            "<leader>?",
            function()
                local function get_current_layout()
                    if _G.get_current_layout then
                        return _G.get_current_layout()
                    end
                    if _G.LangmapHelper and _G.LangmapHelper.current_layout then
                        return _G.LangmapHelper.current_layout
                    end
                    return "en"
                end

                local layout = get_current_layout()
                local en_to_ua = _G.LangmapHelper and _G.LangmapHelper.en_to_ua or {}

                local groups = {
                    { key = "t", icon = "", name = "Tabs", desc = "Tab management" },
                    { key = "w", icon = "", name = "Workspaces", desc = "Sessions & workspaces" },
                    { key = "f", icon = "", name = "Find/Search", desc = "File and text search" },
                    { key = "e", icon = "", name = "Explorer", desc = "Files & buffers" },
                    { key = "c", icon = "", name = "Code/LSP", desc = "LSP operations" },
                    { key = "x", icon = "", name = "System", desc = "Config & tools" },
                    { key = "g", icon = "", name = "Git", desc = "Git operations" },
                    { key = "y", icon = "", name = "Yank", desc = "Clipboard" },
                    { key = "u", icon = "", name = "UI/Themes", desc = "Themes & colors" },
                    { key = "d", icon = "", name = "Document", desc = "Formatting" },
                    { key = "a", icon = "", name = "Aerial", desc = "Code outline" },
                    { key = "s", icon = "", name = "Search", desc = "Advanced search" },
                }

                vim.ui.select(groups, {
                    prompt = " Select Group:",
                    format_item = function(item)
                        local display_key = item.key
                        if layout == "ua" and en_to_ua[item.key] then
                            display_key = en_to_ua[item.key]
                        end
                        return string.format("%s %s • %s - %s",
                            item.icon, display_key, item.name, item.desc)
                    end,
                }, function(choice)
                    if not choice then return end

                    local search_key = choice.key
                    if layout == "ua" and en_to_ua[choice.key] then
                        search_key = en_to_ua[choice.key]
                    end

                    vim.defer_fn(function()
                        require("legendary").find({
                            filters = {
                                function(item)
                                    if item.kind ~= "legendary.keymaps" then
                                        return false
                                    end
                                    local key = item.keys or item.key or ""
                                    return key:match("^<leader>" .. vim.pesc(search_key))
                                end
                            }
                        })
                    end, 50)
                end)
            end,
            mode = { "n", "v" },
            desc = "📂 Browse by Groups"
        },
    },
    config = function()
        -- Configure Telescope UI for legendary.
        require("telescope").setup({
            extensions = {},
            defaults = {
                get_selection_window = function()
                    local wins = vim.api.nvim_list_wins()
                    table.insert(wins, 1, vim.api.nvim_get_current_win())
                    for _, win in ipairs(wins) do
                        local buf = vim.api.nvim_win_get_buf(win)
                        if vim.bo[buf].buftype == "" then
                            return win
                        end
                    end
                    return 0
                end,
            },
        })

        -- Setup vim.ui.select to use Telescope dropdown.
        vim.ui.select = function(items, opts, on_choice)
            local pickers = require("telescope.pickers")
            local finders = require("telescope.finders")
            local actions = require("telescope.actions")
            local action_state = require("telescope.actions.state")
            local conf = require("telescope.config").values
            local themes = require("telescope.themes")

            opts = opts or {}

            pickers.new(themes.get_dropdown({
                layout_config = {
                    width = 0.7,
                    height = 0.5,
                },
                borderchars = {
                    prompt = { "─", "│", " ", "│", "╭", "╮", "│", "│" },
                    results = { "─", "│", "─", "│", "├", "┤", "╯", "╰" },
                    preview = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
                },
            }), {
                prompt_title = opts.prompt or "Select",
                finder = finders.new_table({
                    results = items,
                    entry_maker = function(item)
                        local display = opts.format_item and opts.format_item(item) or tostring(item)
                        return {
                            value = item,
                            display = display,
                            ordinal = display,
                        }
                    end,
                }),
                sorter = conf.generic_sorter(opts),
                attach_mappings = function(prompt_bufnr)
                    actions.select_default:replace(function()
                        local selection = action_state.get_selected_entry()
                        actions.close(prompt_bufnr)
                        if selection then
                            on_choice(selection.value, selection.index)
                        else
                            on_choice(nil, nil)
                        end
                    end)
                    return true
                end,
            }):find()
        end

        -- Helper to get current layout.
        local function get_current_layout()
            if _G.LangmapHelper and _G.LangmapHelper.current_layout then
                return _G.LangmapHelper.current_layout
            end
            return "en"
        end

        -- Make it globally available.
        _G.get_current_layout = get_current_layout

        -- Helper to translate keys.
        local function translate_key(key, en_to_ua)
            return key:gsub(".", function(char)
                return en_to_ua[char] or char
            end)
        end

        -- Group definitions matching which-key.
        local group_info = {
            t = { icon = "", name = "Tabs" },
            w = { icon = "", name = "Workspaces" },
            f = { icon = "", name = "Find/Search" },
            e = { icon = "", name = "Explorer" },
            c = { icon = "", name = "Code/LSP" },
            ck = { icon = "", name = "Linters" },
            x = { icon = "", name = "System" },
            xt = { icon = "", name = "Terminal" },
            g = { icon = "", name = "Git" },
            y = { icon = "", name = "Yank" },
            u = { icon = "", name = "UI/Themes" },
            d = { icon = "", name = "Document" },
            ds = { icon = "", name = "Spaces" },
            dc = { icon = "", name = "ColorColumn" },
            a = { icon = "", name = "Aerial" },
            s = { icon = "", name = "Search" },
        }

        -- Base keymaps (English version).
        local base_keymaps = {
            -- TABS
            { "<leader>tq", ":SmartCloseTab<CR>", description = "Smart Close Tab" },
            { "<leader>tc", ":CloseSavedTabs<CR>", description = "Close All Saved Tabs" },
            { "<leader>tQ", ":ForceCloseTab<CR>", description = "Force Close Tab" },
            { "<leader>tA", ":qa<CR>", description = "Close All & Exit" },
            { "<leader>tn", ":tabnew<CR>", description = "New Tab" },
            { "<leader>to", ":tabonly<CR>", description = "Close Other Tabs" },

            -- WORKSPACE
            { "<leader>ws", ":SessionSave<CR>", description = "Save Session" },
            { "<leader>wr", ":SessionRestore<CR>", description = "Restore Session" },
            { "<leader>wS", ":SessionRestoreLast<CR>", description = "Restore Last Session" },
            { "<leader>wD", ":SessionDontSave<CR>", description = "Don't Save Session" },
            { "<leader>wF", ":Telescope sessions<CR>", description = "Find Sessions" },
            { "<leader>ww", ":Telescope workspaces<CR>", description = "Find Workspaces" },
            { "<leader>wa", ":WorkspaceAdd<CR>", description = "Add Workspace" },

            -- FIND
            { "<leader>ff", ":Telescope find_files<CR>", description = "Find Files", mode = { "n" } },
            -- { "<leader>fg", ":Telescope live_grep<CR>", description = "Live Grep", mode = { "n" } },
            -- { "<leader>fG", description = "Live Grep (include ignored)", mode = { "n" } },
            { "<leader>fb", ":Telescope buffers<CR>", description = "Find Buffers", mode = { "n" } },
            { "<leader>fh", ":Telescope help_tags<CR>", description = "Help Tags", mode = { "n" } },
            { "<leader>fo", ":Telescope oldfiles<CR>", description = "Old Files", mode = { "n" } },
            { "<leader>fd", ":Telescope lsp_document_symbols<CR>", description = "Document Symbols", mode = { "n" } },
            { "<leader>fw", ":Telescope lsp_workspace_symbols<CR>", description = "Workspace Symbols", mode = { "n" } },

            { "<leader>fc", description = "Find & Replace", mode = { "n", "v" } },
            { "<leader>fC", description = "Find & Replace (include ignored)", mode = { "n" } },
            { "<leader>fx", description = "Replace current Word", mode = { "n" } },

            -- EXPLORER
            {
                "<leader>ee",
                function()
                    if _G.NvimTreeModal then
                        vim.defer_fn(function() _G.NvimTreeModal() end, 100)
                    else
                        local api = require("nvim-tree.api")
                        if api.tree.is_visible() then
                            api.tree.close()
                        else
                            api.tree.open({ current_window = false, find_file = false, update_root = false })
                        end
                    end
                end,
                description = "Open File Explorer"
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
                description = "Project History"
            },
            {
                "<leader>et",
                function()
                    if _G.TabsList and _G.TabsList.show_tabs_window then
                        _G.TabsList.show_tabs_window()
                    else
                        print("TabsList functionality not loaded")
                    end
                end,
                description = "Show Tabs List"
            },
            { "<leader>eb", ":Telescope buffers<CR>", description = "Show Buffers" },
            { "<leader>ed", ":bd<CR>", description = "Delete Buffer" },
            { "<leader>en", ":bnext<CR>", description = "Next Buffer" },
            { "<leader>ep", ":bprevious<CR>", description = "Previous Buffer" },
            { "<leader>eT", ":tabnew<CR>", description = "New Tab" },

            -- CODE
            { "<leader>ca", vim.lsp.buf.code_action, description = "Code Action" },
            { "<leader>cr", vim.lsp.buf.rename, description = "Rename Symbol" },
            { "<leader>cf", function() vim.lsp.buf.format({ async = true }) end, description = "Format Document" },
            { "<leader>ci", ":OrganizeImports<CR>", description = "Sort Imports" },
            { "<leader>cc", vim.diagnostic.open_float, description = "Show Line Diagnostics" },
            { "<leader>cC", ":Telescope diagnostics<CR>", description = "Workspace Diagnostics" },
            { "<leader>cl", ":lopen<CR>", description = "Diagnostic List" },
            { "<leader>cq", ":copen<CR>", description = "Quickfix List" },
            { "<leader>cT", ":ToggleDiagnostics<CR>", description = "Toggle WS/Buf" },
            { "<leader>cS", ":DiagnosticSummary<CR>", description = "Diagnostic Summary" },
            { "<leader>cs", ":Telescope lsp_document_symbols<CR>", description = "Document Symbols" },
            { "<leader>cg", ":SymbolsOutline<CR>", description = "Symbols (Grouped)" },
            { "<leader>cw", ":Telescope lsp_workspace_symbols<CR>", description = "Workspace Symbols" },

            -- PYTHON VENV
            { "<leader>cva", ":VenvActivate<CR>", description = "Activate Venv" },
            { "<leader>cvd", ":VenvDeactivate<CR>", description = "Deactivate Venv" },
            { "<leader>cvs", ":VenvStatus<CR>", description = "Venv Status" },
            { "<leader>cvf", ":VenvFind<CR>", description = "Find Venv" },
            { "<leader>cvc", ":VenvSelect<CR>", description = "Select Venv" },

            -- LINTERS
            { "<leader>ckd", "<cmd>ToggleDjlint<cr>", description = "Toggle djlint" },
            { "<leader>ckc", "<cmd>ToggleCodespell<cr>", description = "Toggle Codespell" },
            { "<leader>cke", "<cmd>ToggleESLint<cr>", description = "Toggle ESLint" },
            { "<leader>ckf", "<cmd>ToggleFlake8<cr>", description = "Toggle Flake8" },
            { "<leader>cks", "<cmd>PythonToolsStatus<cr>", description = "Python Tools Status" },
            { "<leader>ckp", "<cmd>CreatePyprojectToml<cr>", description = "Create pyproject.toml" },

            -- SYSTEM
            { "<leader>xr", ":source $MYVIMRC<CR>", description = "Reload Config" },
            { "<leader>xm", ":Mason<CR>", description = "Mason" },
            { "<leader>xh", ":nohl<CR>", description = "Clear Highlights" },
            { "<leader>xu", ":UndotreeToggle<CR>", description = "Undotree" },

            -- TERMINAL
            { "<leader>xtf", ":ToggleTerm direction=float<CR>", description = "Float Terminal" },
            { "<leader>xth", ":ToggleTerm direction=horizontal<CR>", description = "Horizontal Terminal" },
            { "<leader>xtv", ":ToggleTerm direction=vertical<CR>", description = "Vertical Terminal" },
            { "<leader>xtp", ":TermExec cmd='python'<CR>", description = "Python Terminal" },
            { "<leader>xtd", ":TermExec cmd='python manage.py shell'<CR>", description = "Django Shell" },
            { "<leader>xtr", ":TermExec cmd='python manage.py runserver'<CR>", description = "Django Runserver" },
            { "<leader>xtn", ":TermExec cmd='node'<CR>", description = "Node Terminal" },

            -- GIT
            { "<leader>gs", ":Gitsigns stage_hunk<CR>", description = "Stage Hunk", mode = { "n", "v" } },
            { "<leader>gr", ":Gitsigns reset_hunk<CR>", description = "Reset Hunk", mode = { "n", "v" } },
            { "<leader>gp", ":Gitsigns preview_hunk<CR>", description = "Preview Hunk" },
            { "<leader>gb", ":Gitsigns blame_line<CR>", description = "Blame Line" },
            { "<leader>gd", ":Gitsigns diffthis<CR>", description = "Diff This" },
            { "<leader>gt", ":Gitsigns toggle_current_line_blame<CR>", description = "Toggle Blame" },

            -- YANK
            { "<leader>ya", ":%y+<CR>", description = "Yank All Buffer", mode = { "n" } },
            { "<leader>yy", '"+y', description = "Yank Selection", mode = { "n", "v" } },
            { "<leader>yp", '"+p', description = "Paste from Clipboard", mode = { "n", "v" } },

            -- UI
            { "<leader>ut", ":Telescope colorscheme<CR>", description = "Theme Switcher" },
            { "<leader>us", ":SetPermanentTheme<CR>", description = "Set Permanent Theme" },
            { "<leader>ub", ":ToggleBackground<CR>", description = "Toggle Background" },
            { "<leader>ui", ":ThemeInfo<CR>", description = "Theme Info" },
            { "<leader>uI", "<cmd>IBLToggle<cr>", description = "Toggle Indent Guides" },

            -- DOCUMENT
            { "<leader>df", function() vim.lsp.buf.format({ async = true }) end, description = "Format Document" },
            { "<leader>dt", ":ToggleTrailingSpaces<CR>", description = "Toggle Trailing Spaces" },
            { "<leader>dsi", ":IndentInfo<CR>", description = "Indent Info" },
            {
                "<leader>dr",
                function()
                    local ft = vim.bo.filetype
                    if ft == "markdown" then
                        require("render-markdown").toggle()
                    elseif ft == "rst" or ft == "restructuredtext" then
                        if _G.rst_render_toggle then
                            _G.rst_render_toggle()
                        else
                            vim.notify("RST renderer not loaded", vim.log.levels.WARN)
                        end
                    else
                        vim.notify("No renderer available for ." .. ft, vim.log.levels.WARN)
                    end
                end,
                description = "Toggle Rendering (Markdown/RST)"
            },
            { "<leader>dst", function()
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
            end, description = "Toggle Tabs ↔ Spaces" },
            { "<leader>ds2", function()
                vim.opt_local.expandtab = true
                vim.opt_local.tabstop = 2
                vim.opt_local.shiftwidth = 2
                vim.opt_local.softtabstop = 2
                print("Set to 2 spaces")
            end, description = "Set 2 Spaces" },
            { "<leader>ds4", function()
                vim.opt_local.expandtab = true
                vim.opt_local.tabstop = 4
                vim.opt_local.shiftwidth = 4
                vim.opt_local.softtabstop = 4
                print("Set to 4 spaces")
            end, description = "Set 4 Spaces" },
            { "<leader>dst2", ":Retab<CR>", description = "Tabs → Spaces" },
            { "<leader>dss2", ":RetabReverse<CR>", description = "Spaces → Tabs" },
            { "<leader>dc1", function()
                vim.wo.colorcolumn = "79"
                print("ColorColumn: 79")
            end, description = "ColorColumn: 79 symbols" },
            { "<leader>dc2", function()
                vim.wo.colorcolumn = "120"
                print("ColorColumn: 120")
            end, description = "ColorColumn: 120 symbols" },
            { "<leader>dc0", function()
                if vim.wo.colorcolumn == "" then
                    vim.wo.colorcolumn = "79"
                    print("ColorColumn: ON (79)")
                else
                    vim.wo.colorcolumn = ""
                    print("ColorColumn: OFF")
                end
            end, description = "ColorColumn: Toggle Show/Hide" },

            -- AERIAL
            { "<leader>aa", ":AerialToggle<CR>", description = "Toggle Aerial outline", mode = { "n" } },
            { "<leader>aA", ":AerialNavToggle<CR>", description = "Toggle Aerial nav", mode = { "n" } },
            { "<leader>af", ":Telescope aerial<CR>", description = "Find symbols (Aerial)", mode = { "n" } },

            -- SEARCH
            { "<leader>st", ":TodoTelescope<CR>", description = "Find TODO comments" },
            { "<leader>sT", ":TodoTelescope keywords=TODO,FIX<CR>", description = "Find TODO/FIX" },
        }

        -- Static keymaps.
        local static_keymaps = {
            { "<A-Left>", ":tabprevious<CR>", description = "Previous Tab", mode = { "n" } },
            { "<A-Right>", ":tabnext<CR>", description = "Next Tab", mode = { "n" } },
            { "<A-h>", ":tabmove -1<CR>", description = "Move Tab Left", mode = { "n" } },
            { "<A-l>", ":tabmove +1<CR>", description = "Move Tab Right", mode = { "n" } },
            { "<A-1>", "1gt", description = "Go to Tab 1", mode = { "n" } },
            { "<A-2>", "2gt", description = "Go to Tab 2", mode = { "n" } },
            { "<A-3>", "3gt", description = "Go to Tab 3", mode = { "n" } },
            { "<A-4>", "4gt", description = "Go to Tab 4", mode = { "n" } },
            { "<A-5>", "5gt", description = "Go to Tab 5", mode = { "n" } },
            { "<A-6>", "6gt", description = "Go to Tab 6", mode = { "n" } },
            { "<A-7>", "7gt", description = "Go to Tab 7", mode = { "n" } },
            { "<A-8>", "8gt", description = "Go to Tab 8", mode = { "n" } },
            { "<A-9>", "9gt", description = "Go to Tab 9", mode = { "n" } },
            { "gd", vim.lsp.buf.definition, description = "Go to Definition" },
            { "gD", vim.lsp.buf.declaration, description = "Go to Declaration" },
            { "gi", vim.lsp.buf.implementation, description = "Go to Implementation" },
            { "gr", vim.lsp.buf.references, description = "Go to References" },
            { "K", vim.lsp.buf.hover, description = "Hover Info" },
            { "gl", vim.diagnostic.open_float, description = "Line Diagnostics" },
            { "]d", vim.diagnostic.goto_next, description = "Next Diagnostic" },
            { "[d", vim.diagnostic.goto_prev, description = "Previous Diagnostic" },
            { "]c", ":Gitsigns next_hunk<CR>", description = "Next Git Hunk" },
            { "[c", ":Gitsigns prev_hunk<CR>", description = "Previous Git Hunk" },
            { "]t", function() require("todo-comments").jump_next() end, description = "Next TODO" },
            { "[t", function() require("todo-comments").jump_prev() end, description = "Previous TODO" },
            { "<F2>", ":w | lua vim.lsp.buf.format()<CR>", description = "Save & Format" },
            { "<F5>", ":tabprevious<CR>", description = "Previous Tab" },
            { "<F6>", ":tabnext<CR>", description = "Next Tab" },
            { "<F7>", ":Telescope lsp_document_symbols<CR>", description = "Document Symbols" },
            { "<F8>", ":Telescope tabs<CR>", description = "Tabs List" },
            { "<F9>", ":NvimTreeToggle<CR>", description = "File Explorer" },
            { "<F10>", ":Telescope buffers<CR>", description = "Buffers List" },
        }

        -- Generate keymaps.
        local function generate_keymaps()
            local layout = get_current_layout()
            local all_keymaps = vim.deepcopy(static_keymaps)

            if layout == "ua" and _G.LangmapHelper and _G.LangmapHelper.en_to_ua then
                local en_to_ua = _G.LangmapHelper.en_to_ua
                for _, keymap in ipairs(base_keymaps) do
                    local translated = vim.deepcopy(keymap)
                    local key = translated[1]
                    local after_leader = key:gsub("^<leader>", "")
                    local translated_keys = translate_key(after_leader, en_to_ua)
                    translated[1] = "<leader>" .. translated_keys
                    table.insert(all_keymaps, translated)
                end
            else
                for _, keymap in ipairs(base_keymaps) do
                    table.insert(all_keymaps, keymap)
                end
            end

            return all_keymaps
        end

        -- Popup menu.
        local function show_leader_menu()
            if vim.v.count > 0 then return end

            local layout = get_current_layout()
            local en_to_ua = _G.LangmapHelper and _G.LangmapHelper.en_to_ua or {}

            local groups = {}
            for key, info in pairs(group_info) do
                if #key == 1 then
                    local display_key = key
                    if layout == "ua" and en_to_ua[key] then
                        display_key = en_to_ua[key]
                    end
                    table.insert(groups, {
                        key = display_key,
                        icon = info.icon,
                        name = info.name,
                        original_key = key
                    })
                end
            end

            table.sort(groups, function(a, b) return a.original_key < b.original_key end)

            local lines = {}
            local layout_indicator = layout == "ua" and "🇺🇦 Ukrainian" or "🇬🇧 English"
            table.insert(lines, string.format("╭─ Leader Menu [%s] ─╮", layout_indicator))

            for _, group in ipairs(groups) do
                table.insert(lines, string.format("│ %s %s → %s", group.icon, group.key, group.name))
            end

            table.insert(lines, "├─────────────────────┤")
            table.insert(lines, "│ ? - Browse by group  │")
            table.insert(lines, "│ Esc - Close          │")
            table.insert(lines, "╰─────────────────────╯")

            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

            local width = 50
            local height = #lines
            local win = vim.api.nvim_open_win(buf, true, {
                relative = "cursor",
                width = width,
                height = height,
                row = 1,
                col = 0,
                style = "minimal",
                border = "rounded",
            })

            vim.api.nvim_buf_set_option(buf, "modifiable", false)
            vim.api.nvim_win_set_option(win, "winblend", 10)

            local ok, char = pcall(vim.fn.getchar)

            pcall(vim.api.nvim_win_close, win, true)

            if not ok or char == 27 then return end

            if char == string.byte("?") then
                vim.schedule(function()
                    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<leader>?", true, false, true), "m", false)
                end)
                return
            end

            local key_pressed = type(char) == "number" and vim.fn.nr2char(char) or char

            for _, group in ipairs(groups) do
                if key_pressed == group.key then
                    vim.schedule(function()
                        -- We receive all keys (including translated ones).
                        local all_keymaps = generate_keymaps()

                        -- Check if there are commands for this group.
                        local has_matches = false
                        for _, keymap in ipairs(all_keymaps) do
                            local lhs = keymap[1] or ""
                            if lhs:match("^<leader>" .. vim.pesc(key_pressed)) then
                                has_matches = true
                                break
                            end
                        end

                        if has_matches then
                            -- If there is a match, open Legendary with a filter.
                            require("legendary").find({
                                filters = {
                                    function(item)
                                        if not item.keys and not item.key then return false end
                                        local itemkey = item.keys or item.key or ""
                                        return itemkey:match("^<leader>" .. vim.pesc(key_pressed))
                                    end,
                                },
                            })
                        else
                            -- If there are no matches, we simply show the message below.
                            vim.cmd('echohl WarningMsg | echom "❌ Unknown leader command: <leader>' ..
                                    key_pressed .. '" | echohl None')
                        end
                    end)
                    return
                end
            end

            -- If the group is not found at all.
            vim.cmd('echohl ErrorMsg | echom "❌ Wrong hotkey: <leader>' ..
                    key_pressed .. '" | echohl None')
        end

        vim.keymap.set("n", "<Space>", show_leader_menu, { noremap = true, silent = true, desc = "Show Leader Menu" })

        require("legendary").setup({
            extensions = {
                lazy_nvim = true,
                which_key = false,
            },
            select_prompt = "  Legendary ",
            include_builtin = false,
            include_legendary_cmds = true,
            keymaps = generate_keymaps(),
            commands = {},
            autocmds = {},
            col_separator_char = "│",
        })

        vim.api.nvim_create_autocmd("User", {
            pattern = "LayoutChanged",
            callback = function()
                vim.schedule(function()
                    require("legendary").setup({ keymaps = generate_keymaps() })
                    local layout = get_current_layout()
                    vim.notify("🎹 Legendary: " .. (layout == "ua" and "🇺🇦" or "🇬🇧"), vim.log.levels.INFO)
                end)
            end,
            desc = "Update legendary keymaps on layout change"
        })

        vim.opt.timeout = true
        vim.opt.timeoutlen = 1000
    end
}