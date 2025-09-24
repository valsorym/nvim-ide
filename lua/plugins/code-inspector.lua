-- ~/.config/nvim/lua/plugins/code-inspector.lua
-- Flat (Nerd Fonts) icons, column layout, caching, grouping.

return {
    "nvim-telescope/telescope.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        local telescope = require("telescope")
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        local previewers = require("telescope.previewers")
        local themes = require("telescope.themes")
        local entry_display = require("telescope.pickers.entry_display")

        -- Stable priority for kinds.
        local priority = {
            Class = 1, Interface = 2, Struct = 3, Enum = 4, Module = 5,
            Constructor = 6, Method = 7, Function = 8, Property = 9,
            Field = 10, Variable = 11, Constant = 12, Event = 13,
            Operator = 14, TypeParameter = 15, String = 16, Number = 17,
            Boolean = 18, Array = 19, Object = 20, Key = 21, Null = 22,
            EnumMember = 23,
        }

        -- Flat Nerd Fonts (Codicons) icons. No emoji.
        -- Make sure a Nerd Font is enabled in your terminal/GUI.
        local nf = {
            Class = "",        -- cod-symbol-class
            Interface = "",    -- cod-symbol-interface
            Struct = "",       -- cod-symbol-structure
            Enum = "",         -- cod-symbol-enum
            Module = "",       -- cod-symbol-namespace/module
            Constructor = "",  -- cod-symbol-constructor
            Method = "",       -- cod-symbol-method
            Function = "󰊕",     -- md-function
            Property = "",     -- cod-symbol-property
            Field = "",        -- cod-symbol-field
            Variable = "",     -- cod-symbol-variable
            Constant = "",     -- cod-symbol-constant
            Event = "",        -- cod-symbol-event
            Operator = "",     -- cod-symbol-operator
            TypeParameter = "", -- cod-symbol-type-parameter
            String = "",       -- cod-symbol-string
            Number = "",       -- cod-symbol-number
            Boolean = "",      -- cod-symbol-boolean
            Array = "",        -- cod-symbol-array
            Object = "",       -- cod-symbol-object
            Key = "",          -- cod-symbol-key
            Null = "",         -- cod-symbol-null
            EnumMember = "",   -- cod-symbol-enum-member
        }

        -- Small cache per buffer to avoid repeated LSP calls.
        local cache = {} -- [bufnr] = {tick=..., items=...}

        local function kind_name(k)
            local map = vim.lsp.protocol.SymbolKind
            return map and map[k] or "Unknown"
        end

        local function pos_from_symbol(sym)
            -- Works for both DocumentSymbol and SymbolInformation.
            if sym.location and sym.location.range then
                local r = sym.location.range
                return r.start.line + 1, r.start.character
            end
            local r = sym.selectionRange or sym.range
            if r and r.start then
                return r.start.line + 1, r.start.character
            end
            return 1, 0
        end

        local function flatten(symbols, parent, level, out)
            level = level or 0
            out = out or {}
            for _, s in ipairs(symbols or {}) do
                local kname = kind_name(s.kind)
                local name = s.name or "<unknown>"
                local disp = (parent and level > 0)
                    and (parent .. "." .. name) or name
                local line, col = pos_from_symbol(s)
                table.insert(out, {
                    name = disp, kind = kname, line = line,
                    col = col, level = level, raw = s,
                })
                if s.children then
                    flatten(s.children, s.name, level + 1, out)
                end
            end
            return out
        end

        local function sort_symbols(items)
            table.sort(items, function(a, b)
                local pa = priority[a.kind] or 99
                local pb = priority[b.kind] or 99
                if pa ~= pb then return pa < pb end
                if a.level ~= b.level then return a.level < b.level end
                if a.line ~= b.line then return a.line < b.line end
                return a.name < b.name
            end)
            return items
        end

        local function groups_for(items)
            local g, order = {}, {}
            for _, it in ipairs(items) do
                if not g[it.kind] then
                    g[it.kind] = {}
                    table.insert(order, it.kind)
                end
                table.insert(g[it.kind], it)
            end
            table.sort(order, function(a, b)
                local pa = priority[a] or 99
                local pb = priority[b] or 99
                return pa < pb
            end)
            return g, order
        end

        local function get_symbols()
            local bufnr = vim.api.nvim_get_current_buf()
            local tick = vim.b.changedtick or 0
            local c = cache[bufnr]
            if c and c.tick == tick then
                return c.items
            end

            local params = {
                textDocument = vim.lsp.util.make_text_document_params(),
            }
            local result = {}
            local ok_any = false
            local res = vim.lsp.buf_request_sync(
                bufnr, "textDocument/documentSymbol", params, 1500
            )
            if not res then return {} end

            for _, r in pairs(res) do
                if r and r.result then
                    ok_any = true
                    if #r.result > 0 then
                        -- Could be DocumentSymbol[] or SymbolInformation[].
                        if r.result[1].range or r.result[1].children then
                            flatten(r.result, nil, 0, result)
                        else
                            -- SymbolInformation[]: wrap and reuse.
                            local tmp = {}
                            for _, s in ipairs(r.result) do
                                table.insert(tmp, {
                                    name = s.name,
                                    kind = kind_name(s.kind),
                                    location = s.location,
                                })
                            end
                            flatten(tmp, nil, 0, result)
                        end
                    end
                end
            end
            if not ok_any then return {} end

            sort_symbols(result)
            cache[bufnr] = {tick = tick, items = result}
            return result
        end

        -- Column layout: [icon] [kind:12] [indent+name]
        local displayer = entry_display.create({
            separator = " ",
            items = {
                {width = 2},
                {width = 12},
                {remaining = true},
            },
        })

        local function indent_str(level)
            return string.rep("  ", math.max(0, level))
        end

        local function make_entry(item)
            local icon = nf[item.kind] or "•"
            local name = indent_str(item.level) .. item.name
            return {
                value = item,
                ordinal = item.name .. " " .. item.kind,
                display = function()
                    return displayer({icon, item.kind, name})
                end,
                filename = vim.api.nvim_buf_get_name(0),
                lnum = item.line,
                col = item.col,
                kind = item.kind,
            }
        end

        local function make_grouped_entries(items)
            local entries = {}
            local g, order = groups_for(items)
            for _, kind in ipairs(order) do
                local list = g[kind]
                if #list > 0 then
                    local icon = nf[kind] or "•"
                    local header = ("— %s %s (%d) —"):format(icon, kind, #list)
                    table.insert(entries, {
                        value = nil, ordinal = "",
                        is_header = true, display = header,
                    })
                    for _, it in ipairs(list) do
                        table.insert(entries, make_entry(it))
                    end
                    table.insert(entries, {
                        value = nil, ordinal = "",
                        is_spacer = true, display = "",
                    })
                end
            end
            return entries
        end

        local function open_picker(opts)
            opts = opts or {}
            local items = get_symbols()
            if #items == 0 then
                vim.notify("Code Inspector: no symbols",
                    vim.log.levels.INFO)
                return
            end

            local grouped = opts.grouped or false
            local results = grouped and make_grouped_entries(items)
                or vim.tbl_map(make_entry, items)

            local filename = vim.fn.expand("%:t")
            local filetype = vim.bo.filetype

            pickers.new(opts, {
                prompt_title = (" Code Inspector - %s "):format(filename),
                results_title = (" %s Symbols (%d) "):format(
                    filetype:upper(), #items
                ),
                finder = finders.new_table({
                    results = results,
                    entry_maker = function(e) return e end,
                }),
                sorter = conf.generic_sorter({}),
                previewer = previewers.vim_buffer_cat.new({
                    get_buffer_by_name = function(_, e)
                        return e.filename
                    end,
                    define_preview = function(self, entry, _)
                        if not entry or not entry.value then return end
                        conf.buffer_previewer_maker(
                            entry.filename, self.state.bufnr, {
                                bufname = self.state.bufname,
                                winid = self.state.winid,
                                callback = function(bufnr)
                                    vim.api.nvim_buf_add_highlight(
                                        bufnr, -1,
                                        "TelescopePreviewLine",
                                        entry.lnum - 1, 0, -1
                                    )
                                    pcall(vim.api.nvim_win_set_cursor,
                                        self.state.winid,
                                        {entry.lnum, entry.col})
                                end,
                            }
                        )
                    end,
                }),
                attach_mappings = function(prompt_bufnr, map)
                    local function smart_move(next_fn)
                        next_fn(prompt_bufnr)
                        local sel = action_state.get_selected_entry()
                        while sel and (sel.is_header or sel.is_spacer) do
                            next_fn(prompt_bufnr)
                            sel = action_state.get_selected_entry()
                        end
                    end

                    local function jump_to(sel)
                        if not sel or not sel.value then return end
                        actions.close(prompt_bufnr)
                        vim.api.nvim_win_set_cursor(0,
                            {sel.lnum, sel.col})
                        vim.cmd("normal! zz")
                    end

                    map("i", "<CR>", function()
                        jump_to(action_state.get_selected_entry())
                    end)
                    map("n", "<CR>", function()
                        jump_to(action_state.get_selected_entry())
                    end)

                    map("i", "<C-j>", function()
                        smart_move(actions.move_selection_next)
                    end)
                    map("i", "<C-k>", function()
                        smart_move(actions.move_selection_previous)
                    end)
                    map("n", "j", function()
                        smart_move(actions.move_selection_next)
                    end)
                    map("n", "k", function()
                        smart_move(actions.move_selection_previous)
                    end)

                    map("i", "<C-g>", function()
                        actions.close(prompt_bufnr)
                        open_picker({grouped = not grouped})
                    end)

                    -- Quick kind filters: start a new query.
                    local function inject(q)
                        local keys = vim.api.nvim_replace_termcodes(
                            "<C-u>" .. q .. " ", true, false, true
                        )
                        vim.fn.feedkeys(keys, "n")
                    end
                    map("i", "<C-c>", function() inject("Class") end)
                    map("i", "<C-f>", function() inject("Function") end)
                    map("i", "<C-m>", function() inject("Method") end)
                    map("i", "<C-v>", function() inject("Variable") end)

                    return true
                end,
            }):find()
        end

        local function show_simple() open_picker({grouped = false}) end
        local function show_grouped() open_picker({grouped = true}) end
        local function show_workspace()
            local clients = vim.lsp.get_clients({bufnr = 0})
            if #clients == 0 then
                vim.notify("Workspace: no LSP client",
                    vim.log.levels.WARN)
                return
            end
            require("telescope.builtin").lsp_workspace_symbols(
                themes.get_dropdown({
                    winblend = 10, previewer = true,
                    layout_config = {width = 0.9, height = 0.8},
                    prompt_title = " Workspace Inspector ",
                    results_title = " All Symbols ",
                })
            )
        end

        -- Public API / mappings.
        _G.CodeInspector = show_simple
        _G.CodeInspectorGrouped = show_grouped
        _G.WorkspaceInspector = show_workspace

        vim.keymap.set("n", "<F7>", show_simple,
            {desc = "Code Inspector", silent = true})
        vim.keymap.set("n", "<leader>ls", show_simple,
            {desc = "Document symbols", silent = true})
        vim.keymap.set("n", "<leader>lg", show_grouped,
            {desc = "Document symbols (grouped)", silent = true})

        vim.api.nvim_create_user_command("CodeInspector",
            show_simple, {desc = "Open Code Inspector"})
        vim.api.nvim_create_user_command("CodeInspectorGrouped",
            show_grouped, {desc = "Open Code Inspector (grouped)"})
    end,
}
