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
            cv = { icon = "", name = "Python Venv" },
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

        -- Base keymaps (English version) - ALL LEADER-BASED KEYMAPS
        local base_keymaps = {
            -- =================================================================
            -- TABS MANAGEMENT (<leader>t)
            -- =================================================================
            { "<leader>tn", function()
                local current_buf = vim.api.nvim_get_current_buf()
                local current_filetype = vim.bo[current_buf].filetype
                local current_name = vim.fn.bufname(current_buf)

                if current_filetype == "dashboard" or
                   (current_name == "" and not vim.bo[current_buf].modified) then
                    vim.cmd("enew")
                else
                    vim.cmd("tablast | tabnew")
                end
            end, description = "New Tab" },

            { "<leader>tq", function()
                require("config.keymaps").smart_tab_close()
            end, description = "Smart Close Tab" },

            { "<leader>tc", function()
                require("config.keymaps").close_saved_tabs()
            end, description = "Close All Saved Tabs" },

            { "<leader>tQ", function()
                require("config.keymaps").force_close_tab()
            end, description = "Force Close Tab" },

            { "<leader>tA", ":qa<CR>", description = "Close All & Exit" },
            { "<leader>tO", ":tabonly<CR>", description = "Close Other Tabs" },

            -- =================================================================
            -- WORKSPACE/SESSIONS (<leader>w)
            -- =================================================================
            { "<leader>ws", ":SessionSave<CR>", description = "Save Session" },
            { "<leader>wr", ":SessionRestore<CR>", description = "Restore Session" },
            { "<leader>wS", function()
                if package.loaded.persistence then
                    require("persistence").load()
                    vim.notify("Session restored", vim.log.levels.INFO)
                end
            end, description = "Restore Last Session" },
            { "<leader>wD", ":SessionDelete<CR>", description = "Delete Session" },
            { "<leader>wF", function()
                if _G.TelescopeSessions then
                    _G.TelescopeSessions()
                else
                    vim.notify("Sessions not available", vim.log.levels.WARN)
                end
            end, description = "Find Sessions" },
            { "<leader>ww", ":Telescope workspaces<CR>", description = "Find Workspaces" },
            { "<leader>wa", function()
                local name = vim.fn.input("Workspace name: ", vim.fn.fnamemodify(vim.fn.getcwd(), ":t"))
                if name ~= "" then
                    require("workspaces").add(vim.fn.getcwd(), name)
                end
            end, description = "Add Workspace" },

            -- =================================================================
            -- FIND/SEARCH/REPLACE (<leader>f)
            -- =================================================================
            { "<leader>ff", function()
                local cwd = vim.fn.getcwd()
                local ok, api = pcall(require, "nvim-tree.api")
                if ok and api.tree.is_visible() then
                    local root = api.tree.get_root()
                    if root and root.absolute_path then
                        cwd = root.absolute_path
                    end
                end
                require("telescope.builtin").find_files({cwd = cwd})
            end, description = "Find Files" },

            { "<leader>fg", function()
                local cwd = vim.fn.getcwd()
                local ok, api = pcall(require, "nvim-tree.api")
                if ok and api.tree.is_visible() then
                    local root = api.tree.get_root()
                    if root and root.absolute_path then
                        cwd = root.absolute_path
                    end
                end
                require("telescope.builtin").live_grep({cwd = cwd})
            end, description = "Live Grep" },

            { "<leader>fG", function()
                local cwd = vim.fn.getcwd()
                local ok, api = pcall(require, "nvim-tree.api")
                if ok and api.tree.is_visible() then
                    local root = api.tree.get_root()
                    if root and root.absolute_path then
                        cwd = root.absolute_path
                    end
                end
                require("telescope.builtin").live_grep({
                    cwd = cwd,
                    additional_args = function()
                        return {"--no-ignore", "--hidden", "--glob", "!.git/"}
                    end
                })
            end, description = "Live Grep (include ignored)" },

            { "<leader>fb", ":Telescope buffers<CR>", description = "Find Buffers" },
            { "<leader>fh", ":Telescope help_tags<CR>", description = "Help Tags" },
            { "<leader>fo", ":Telescope oldfiles<CR>", description = "Old Files" },
            { "<leader>fd", ":Telescope lsp_document_symbols<CR>", description = "Document Symbols" },
            { "<leader>fp", function()
                local path = vim.fn.expand("%:p")
                vim.fn.setreg("+", path)
                vim.notify("Copied: " .. path, vim.log.levels.INFO)
            end, description = "Copy File Path" },

            -- Find & Replace (handled by telescope-replace.lua plugin)
            { "<leader>fc", description = "Find & Replace", mode = { "n", "v" } },
            { "<leader>fC", description = "Find & Replace (include ignored)", mode = { "n" } },
            { "<leader>fx", description = "Replace current Word", mode = { "n" } },

            -- Flash.nvim
            { "<leader>fs", function()
                require("flash").jump()
            end, description = "Flash Jump", mode = { "n", "x", "o" } },
            { "<leader>fS", function()
                require("flash").treesitter()
            end, description = "Flash Treesitter", mode = { "n", "x", "o" } },
            { "<leader>fr", function()
                require("flash").remote()
            end, description = "Flash Remote", mode = { "o" } },
            { "<leader>fR", function()
                require("flash").treesitter_search()
            end, description = "Flash Search", mode = { "o", "x" } },

            -- =================================================================
            -- EXPLORER/FILES/BUFFERS (<leader>e)
            -- =================================================================
            { "<leader>ee", function()
                if _G.NvimTreeModal then
                    _G.NvimTreeModal()
                else
                    vim.cmd("NvimTreeToggle")
                end
            end, description = "File Explorer" },

            { "<leader>eh", function()
                if _G.NvimTreeHistory and _G.NvimTreeHistory.show_history then
                    _G.NvimTreeHistory.show_history()
                else
                    print("Project history not available")
                end
            end, description = "Project History" },

            { "<leader>et", function()
                if _G.TabsList and _G.TabsList.show_tabs_window then
                    _G.TabsList.show_tabs_window()
                else
                    print("TabsList not loaded")
                end
            end, description = "Show Tabs List" },

            { "<leader>eb", ":Telescope buffers<CR>", description = "Show Buffers" },
            { "<leader>ed", ":bd<CR>", description = "Delete Buffer" },
            { "<leader>en", ":bnext<CR>", description = "Next Buffer" },
            { "<leader>ep", ":bprevious<CR>", description = "Previous Buffer" },

            -- =================================================================
            -- CODE/LSP (<leader>c)
            -- =================================================================
            { "<leader>ca", vim.lsp.buf.code_action, description = "Code Action" },
            { "<leader>cr", vim.lsp.buf.rename, description = "Rename Symbol" },
            { "<leader>cf", function()
                vim.lsp.buf.format({ async = true })
            end, description = "Format Document" },

            -- Diagnostics
            { "<leader>cc", function()
                local diagnostic_opts = {
                    focusable = false,
                    close_events = {"BufLeave", "CursorMoved", "InsertEnter", "FocusLost"},
                    border = "rounded",
                    source = "always",
                    prefix = " ",
                    scope = "line"
                }
                vim.diagnostic.open_float(nil, diagnostic_opts)
            end, description = "Show Line Diagnostics" },

            { "<leader>cC", ":Trouble diagnostics toggle<CR>", description = "Workspace Diagnostics" },
            { "<leader>cl", ":Trouble loclist toggle<CR>", description = "Diagnostic List" },
            { "<leader>cq", ":Trouble qflist toggle<CR>", description = "Quickfix List" },

            -- Symbols
            { "<leader>cs", function()
                if _G.CodeInspector then
                    _G.CodeInspector()
                else
                    vim.cmd("Telescope lsp_document_symbols")
                end
            end, description = "Document Symbols" },

            { "<leader>cg", function()
                if _G.CodeInspectorGrouped then
                    _G.CodeInspectorGrouped()
                else
                    vim.notify("Code Inspector not loaded", vim.log.levels.WARN)
                end
            end, description = "Document Symbols (Grouped)" },

            { "<leader>cw", ":Telescope lsp_workspace_symbols<CR>", description = "Workspace Symbols" },

            -- Python tools
            { "<leader>ci", function()
                -- Python import sorting - handled by formatting.lua
                vim.notify("Use <leader>df for combined Python formatting", vim.log.levels.INFO)
            end, description = "Sort Python Imports" },

            { "<leader>cb", function()
                -- Python Black formatting - handled by formatting.lua
                vim.notify("Use <leader>df for combined Python formatting", vim.log.levels.INFO)
            end, description = "Format Python Code" },

            -- Python Virtual Environment
            { "<leader>cva", ":VenvActivate<CR>", description = "Activate Venv" },
            { "<leader>cvd", ":VenvDeactivate<CR>", description = "Deactivate Venv" },
            { "<leader>cvs", ":VenvStatus<CR>", description = "Venv Status" },
            { "<leader>cvf", ":VenvFind<CR>", description = "Find Venv" },
            { "<leader>cvc", ":VenvSelect<CR>", description = "Select Venv" },

            -- Linters and Tools
            { "<leader>cks", ":PythonToolsStatus<CR>", description = "Python Tools Status" },
            { "<leader>ckp", ":CreatePyprojectToml<CR>", description = "Create pyproject.toml" },
            { "<leader>ckr", ":CreatePyrightConfig<CR>", description = "Create pyrightconfig.json" },

            -- =================================================================
            -- SYSTEM/CONFIG/TOOLS (<leader>x)
            -- =================================================================
            { "<leader>xr", function()
                local current_file = vim.fn.expand("%:p")
                local config_dir = vim.fn.stdpath("config")

                if current_file:match("^" .. vim.pesc(config_dir)) then
                    local reload_path = current_file
                    if vim.fn.filereadable(reload_path) then
                        local ok, err = pcall(dofile, reload_path)
                        if ok then
                            vim.notify("Reloaded: " .. vim.fn.fnamemodify(reload_path, ":t"),
                                vim.log.levels.INFO)
                        else
                            vim.notify("Error: " .. tostring(err), vim.log.levels.ERROR)
                        end
                    end
                else
                    vim.cmd("source " .. config_dir .. "/init.lua")
                    vim.notify("Config reloaded", vim.log.levels.INFO)
                end
            end, description = "Reload Config" },

            { "<leader>xm", ":Mason<CR>", description = "Mason" },
            { "<leader>xh", ":nohlsearch<CR>", description = "Clear Highlights" },
            { "<leader>xu", ":UndotreeToggle<CR>", description = "Undotree" },
            { "<leader>xf", function()
                vim.g.format_on_save = not vim.g.format_on_save
                vim.notify("Format on save: " .. (vim.g.format_on_save and "ON" or "OFF"), vim.log.levels.INFO)
            end, description = "Toggle Format on Save" },

            -- Terminal
            { "<leader>xtf", ":ToggleTerm direction=float<CR>", description = "Float Terminal" },
            { "<leader>xth", ":ToggleTerm direction=horizontal<CR>", description = "Horizontal Terminal" },
            { "<leader>xtv", ":ToggleTerm direction=vertical size=80<CR>", description = "Vertical Terminal" },
            { "<leader>xtp", function()
                if _G._PYTHON_TOGGLE then
                    _G._PYTHON_TOGGLE()
                else
                    vim.cmd("TermExec cmd='python'")
                end
            end, description = "Python Terminal" },
            { "<leader>xtn", function()
                if _G._NODE_TOGGLE then
                    _G._NODE_TOGGLE()
                else
                    vim.cmd("TermExec cmd='node'")
                end
            end, description = "Node Terminal" },

            -- =================================================================
            -- GIT (<leader>g)
            -- =================================================================
            { "<leader>gs", function()
                if package.loaded.gitsigns then
                    require("gitsigns").stage_hunk()
                end
            end, description = "Stage Hunk", mode = { "n", "v" } },

            { "<leader>gr", function()
                if package.loaded.gitsigns then
                    require("gitsigns").reset_hunk()
                end
            end, description = "Reset Hunk", mode = { "n", "v" } },

            { "<leader>gp", function()
                if package.loaded.gitsigns then
                    require("gitsigns").preview_hunk()
                end
            end, description = "Preview Hunk" },

            { "<leader>gb", function()
                if package.loaded.gitsigns then
                    require("gitsigns").blame_line({full = true})
                end
            end, description = "Blame Line" },

            { "<leader>gd", function()
                if package.loaded.gitsigns then
                    require("gitsigns").diffthis()
                end
            end, description = "Diff This" },

            { "<leader>gt", function()
                if package.loaded.gitsigns then
                    require("gitsigns").toggle_current_line_blame()
                end
            end, description = "Toggle Blame" },

            -- =================================================================
            -- YANK/CLIPBOARD (<leader>y)
            -- =================================================================
            { "<leader>ya", "ggVG\"+y", description = "Yank All Buffer", mode = { "n" } },
            { "<leader>yy", "\"+y", description = "Yank Selection", mode = { "n", "v" } },
            { "<leader>yp", "\"+p", description = "Paste from Clipboard", mode = { "n", "v" } },

            -- =================================================================
            -- UI/THEMES (<leader>u)
            -- =================================================================
            { "<leader>ut", ":ThemeSwitcher<CR>", description = "Theme Switcher" },
            { "<leader>us", ":ThemeSwitcherPermanent<CR>", description = "Set Permanent Theme" },
            { "<leader>ui", ":ThemeInfo<CR>", description = "Theme Info" },
            { "<leader>uI", ":IBLToggle<CR>", description = "Toggle Indent Guides" },

            -- =================================================================
            -- DOCUMENT/FORMATTING (<leader>d)
            -- =================================================================
            { "<leader>df", function()
                -- This is handled by formatting.lua plugin with combined Python formatting
                local ft = vim.bo.filetype
                if ft == "python" then
                    vim.notify("Python formatting handled by formatting.lua", vim.log.levels.INFO)
                else
                    vim.lsp.buf.format({ async = true })
                end
            end, description = "Format Document" },

            { "<leader>dr", function()
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
            end, description = "Toggle Rendering (Markdown/RST)" },

            -- Trailing spaces
            { "<leader>dt", description = "Toggle Trailing Spaces" },
            { "<leader>dx", description = "Clean Trailing Spaces" },

            -- Spaces/Tabs
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

            -- ColorColumn
            { "<leader>dc0", function()
                if vim.wo.colorcolumn == "" then
                    vim.wo.colorcolumn = "79"
                    print("ColorColumn - ON (79)")
                else
                    vim.wo.colorcolumn = ""
                    print("ColorColumn - OFF")
                end
            end, description = "Toggle ColorColumn" },

            { "<leader>dc1", function()
                vim.wo.colorcolumn = "79"
                print("ColorColumn: 79")
            end, description = "ColorColumn - 79 symbols" },

            { "<leader>dc2", function()
                vim.wo.colorcolumn = "120"
                print("ColorColumn: 120")
            end, description = "ColorColumn - 120 symbols" },

            -- =================================================================
            -- AERIAL (<leader>a)
            -- =================================================================
            { "<leader>aa", ":AerialToggle<CR>", description = "Toggle Aerial Outline" },
            { "<leader>aA", ":AerialNavToggle<CR>", description = "Toggle Aerial Nav" },
            { "<leader>af", ":Telescope aerial<CR>", description = "Find Symbols (Aerial)" },

            -- =================================================================
            -- SEARCH/TODO (<leader>s)
            -- =================================================================
            { "<leader>st", ":TodoTelescope<CR>", description = "Find TODO Comments" },
            { "<leader>sT", ":TodoTelescope keywords=TODO,FIX,FIXME<CR>", description = "Find TODO/FIX" },
        }

        -- Static keymaps (non-leader based).
        local static_keymaps = {
            -- LSP Navigation
            { "gd", vim.lsp.buf.definition, description = "Go to Definition" },
            { "gD", vim.lsp.buf.declaration, description = "Go to Declaration" },
            { "gi", vim.lsp.buf.implementation, description = "Go to Implementation" },
            { "gr", vim.lsp.buf.references, description = "Go to References" },
            { "K", vim.lsp.buf.hover, description = "Hover Info" },

            -- Function keys
            { "<F2>", description = "Save & Format" },
            { "<F5>", description = "Previous Tab" },
            { "<F6>", description = "Next Tab" },
            { "<F7>", description = "Code Inspector" },
            { "<F8>", description = "Tabs List" },
            { "<F9>", description = "File Explorer" },
            { "<F10>", description = "Buffers List" },
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
                        local all_keymaps = generate_keymaps()
                        local has_matches = false
                        for _, keymap in ipairs(all_keymaps) do
                            local lhs = keymap[1] or ""
                            if lhs:match("^<leader>" .. vim.pesc(key_pressed)) then
                                has_matches = true
                                break
                            end
                        end

                        if has_matches then
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
                            vim.cmd('echohl WarningMsg | echom "❌ Unknown leader command: <leader>' ..
                                    key_pressed .. '" | echohl None')
                        end
                    end)
                    return
                end
            end

            vim.cmd('echohl ErrorMsg | echom "❌ Wrong hotkey: <leader>' ..
                    key_pressed .. '" | echohl None')
        end

        vim.keymap.set("n", "<Space>", show_leader_menu, { noremap = true, silent = true, desc = "Show Leader Menu" })

        require("legendary").setup({
            extensions = {
                lazy_nvim = true,
                which_key = false,
            },
            select_prompt = "  Legendary ",
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