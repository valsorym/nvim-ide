-- ~/.config/nvim/lua/plugins/code-inspector.lua
-- Enhanced Code Inspector with custom sorting, grouping, and preview

return {
    "nvim-telescope/telescope.nvim",
    dependencies = {"nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons"},
    config = function()
        local telescope = require("telescope")
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        local previewers = require("telescope.previewers")
        local themes = require("telescope.themes")

        -- Symbol priority for sorting
        local symbol_priority = {
            Class = 1,
            Interface = 2,
            Struct = 3,
            Enum = 4,
            Module = 5,
            Constructor = 6,
            Method = 7,
            Function = 8,
            Property = 9,
            Field = 10,
            Variable = 11,
            Constant = 12,
            Event = 13,
            Operator = 14,
            TypeParameter = 15,
            String = 16,
            Number = 17,
            Boolean = 18,
            Array = 19,
            Object = 20,
            Key = 21,
            Null = 22,
            EnumMember = 23,
        }

        -- Icons for symbol types
        local symbol_icons = {
            Class = "🏛️",
            Method = "⚙️",
            Function = "ƒ",
            Constructor = "🔨",
            Field = "🏷️",
            Variable = "📊",
            Interface = "🔌",
            Module = "📦",
            Property = "🔧",
            Enum = "🔢",
            Constant = "🔒",
            Struct = "🏗️",
            Event = "⚡",
            Operator = "⊕",
            TypeParameter = "T",
            String = "📝",
            Number = "#",
            Boolean = "✓",
            Array = "[]",
            Object = "{}",
            Key = "🔑",
            Null = "∅",
            EnumMember = "🔸",
        }

        -- Colors for symbol types
        local symbol_colors = {
            Class = "#f9e2af",      -- yellow
            Method = "#a6e3a1",     -- green
            Function = "#89b4fa",   -- blue
            Constructor = "#f38ba8", -- red
            Field = "#fab387",      -- orange
            Variable = "#cba6f7",   -- purple
            Interface = "#94e2d5",  -- teal
            Module = "#f2cdcd",     -- rosewater
            Property = "#eba0ac",   -- maroon
            Enum = "#f9e2af",       -- yellow
            Constant = "#f38ba8",   -- red
        }

        -- Function to get document symbols from LSP
        local function get_document_symbols()
            local bufnr = vim.api.nvim_get_current_buf()
            local clients = vim.lsp.get_clients({bufnr = bufnr})

            if #clients == 0 then
                return nil, "No LSP client attached"
            end

            local params = {textDocument = vim.lsp.util.make_text_document_params()}
            local results = vim.lsp.buf_request_sync(bufnr, "textDocument/documentSymbol", params, 2000)

            if not results then
                return nil, "LSP request timeout"
            end

            for _, result in pairs(results) do
                if result.result then
                    return result.result, nil
                end
            end

            return nil, "No symbols found"
        end

        -- Function to flatten nested symbols
        local function flatten_symbols(symbols, parent_name, level)
            level = level or 0
            local flattened = {}

            for _, symbol in ipairs(symbols or {}) do
                local kind_name = vim.lsp.protocol.SymbolKind[symbol.kind] or "Unknown"
                local display_name = symbol.name

                -- Add parent context for nested symbols
                if parent_name and level > 0 then
                    display_name = parent_name .. "." .. symbol.name
                end

                local location = symbol.location or symbol.selectionRange or symbol.range
                local line = location and location.start and location.start.line + 1 or 1
                local col = location and location.start and location.start.character or 0

                table.insert(flattened, {
                    name = display_name,
                    kind = kind_name,
                    line = line,
                    col = col,
                    symbol = symbol,
                    level = level,
                    parent = parent_name,
                })

                -- Recursively add children
                if symbol.children then
                    local children = flatten_symbols(symbol.children, symbol.name, level + 1)
                    vim.list_extend(flattened, children)
                end
            end

            return flattened
        end

        -- Function to sort symbols
        local function sort_symbols(symbols)
            table.sort(symbols, function(a, b)
                local pa = symbol_priority[a.kind] or 99
                local pb = symbol_priority[b.kind] or 99

                if pa == pb then
                    if a.level == b.level then
                        return a.name < b.name
                    end
                    return a.level < b.level
                end
                return pa < pb
            end)
            return symbols
        end

        -- Function to group symbols by type
        local function group_symbols(symbols)
            local groups = {}
            local group_order = {}

            for _, sym in ipairs(symbols) do
                if not groups[sym.kind] then
                    groups[sym.kind] = {}
                    table.insert(group_order, sym.kind)
                end
                table.insert(groups[sym.kind], sym)
            end

            -- Sort group order by priority
            table.sort(group_order, function(a, b)
                local pa = symbol_priority[a] or 99
                local pb = symbol_priority[b] or 99
                return pa < pb
            end)

            return groups, group_order
        end

        -- Custom entry maker for better display
        local function make_symbol_entry(symbol)
            local icon = symbol_icons[symbol.kind] or "•"
            local indent = string.rep("  ", symbol.level)
            local display = string.format("%s%s %s", indent, icon, symbol.name)

            return {
                value = symbol,
                display = display,
                ordinal = symbol.name .. " " .. symbol.kind,
                lnum = symbol.line,
                col = symbol.col,
                kind = symbol.kind,
                filename = vim.api.nvim_buf_get_name(0),
            }
        end

        -- Custom entry maker with grouping
        local function make_grouped_entries(symbols)
            local entries = {}
            local groups, group_order = group_symbols(symbols)

            for _, group_name in ipairs(group_order) do
                local group_symbols = groups[group_name]
                if #group_symbols > 0 then
                    -- Add group header
                    local group_icon = symbol_icons[group_name] or "•"
                    local header = string.format("--- %s %s (%d) ---",
                        group_icon, group_name, #group_symbols)

                    table.insert(entries, {
                        value = nil,
                        display = header,
                        ordinal = "",
                        is_header = true,
                        group = group_name,
                    })

                    -- Add symbols in this group
                    for _, symbol in ipairs(group_symbols) do
                        table.insert(entries, make_symbol_entry(symbol))
                    end

                    -- Add spacing
                    table.insert(entries, {
                        value = nil,
                        display = "",
                        ordinal = "",
                        is_spacer = true,
                    })
                end
            end

            return entries
        end

        -- Enhanced Code Inspector
        local function show_enhanced_inspector(opts)
            opts = opts or {}

            local symbols, error_msg = get_document_symbols()
            if not symbols then
                vim.notify("Code Inspector: " .. (error_msg or "No symbols available"), vim.log.levels.WARN)
                return
            end

            local flattened = flatten_symbols(symbols)
            if #flattened == 0 then
                vim.notify("No symbols found in current file", vim.log.levels.INFO)
                return
            end

            local sorted_symbols = sort_symbols(flattened)
            local entries = opts.grouped and make_grouped_entries(sorted_symbols) or
                          vim.tbl_map(make_symbol_entry, sorted_symbols)

            local filename = vim.fn.expand("%:t")
            local filetype = vim.bo.filetype

            pickers.new(opts, {
                prompt_title = string.format(" Code Inspector - %s ", filename),
                results_title = string.format(" %s Symbols (%d) ", filetype:upper(), #sorted_symbols),

                finder = finders.new_table({
                    results = entries,
                    entry_maker = function(entry)
                        return entry
                    end,
                }),

                sorter = conf.generic_sorter({}),

                previewer = previewers.vim_buffer_cat.new({
                    get_buffer_by_name = function(_, entry)
                        return entry.filename
                    end,
                    define_preview = function(self, entry, status)
                        if entry.is_header or entry.is_spacer or not entry.value then
                            return
                        end

                        conf.buffer_previewer_maker(entry.filename, self.state.bufnr, {
                            bufname = self.state.bufname,
                            winid = self.state.winid,
                            preview_title = entry.value.name .. " [" .. entry.value.kind .. "]",
                            callback = function(bufnr)
                                -- Highlight the symbol line
                                vim.api.nvim_buf_add_highlight(bufnr, -1, "TelescopePreviewLine",
                                    entry.lnum - 1, 0, -1)
                                -- Set cursor to symbol line
                                pcall(vim.api.nvim_win_set_cursor, self.state.winid, {entry.lnum, entry.col})
                            end,
                        })
                    end,
                }),

                attach_mappings = function(prompt_bufnr, map)
                    -- Enhanced selection handler
                    map("i", "<CR>", function()
                        local selection = action_state.get_selected_entry()
                        if selection and selection.value and not selection.is_header and not selection.is_spacer then
                            actions.close(prompt_bufnr)
                            -- Jump to symbol and center it
                            vim.api.nvim_win_set_cursor(0, {selection.lnum, selection.col})
                            vim.cmd("normal! zz")
                            -- Brief highlight
                            vim.cmd("normal! V")
                            vim.defer_fn(function()
                                vim.cmd("normal! <Esc>")
                            end, 300)
                        end
                    end)

                    -- Skip headers and spacers with j/k
                    map("i", "<C-j>", function()
                        actions.move_selection_next(prompt_bufnr)
                        local selection = action_state.get_selected_entry()
                        while selection and (selection.is_header or selection.is_spacer) do
                            actions.move_selection_next(prompt_bufnr)
                            selection = action_state.get_selected_entry()
                        end
                    end)

                    map("i", "<C-k>", function()
                        actions.move_selection_previous(prompt_bufnr)
                        local selection = action_state.get_selected_entry()
                        while selection and (selection.is_header or selection.is_spacer) do
                            actions.move_selection_previous(prompt_bufnr)
                            selection = action_state.get_selected_entry()
                        end
                    end)

                    -- Quick filters
                    map("i", "<C-c>", function()
                        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<C-u>Class<Space>", true, false, true))
                    end)

                    map("i", "<C-f>", function()
                        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<C-u>Function<Space>", true, false, true))
                    end)

                    map("i", "<C-m>", function()
                        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<C-u>Method<Space>", true, false, true))
                    end)

                    map("i", "<C-v>", function()
                        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<C-u>Variable<Space>", true, false, true))
                    end)

                    -- Toggle grouping
                    map("i", "<C-g>", function()
                        actions.close(prompt_bufnr)
                        show_enhanced_inspector({grouped = not (opts.grouped or false)})
                    end)

                    return true
                end,
            }):find()
        end

        -- Simple version (flat list)
        local function show_simple_inspector()
            show_enhanced_inspector({grouped = false})
        end

        -- Grouped version
        local function show_grouped_inspector()
            show_enhanced_inspector({grouped = true})
        end

        -- Create global functions
        _G.CodeInspector = show_simple_inspector
        _G.CodeInspectorGrouped = show_grouped_inspector

        -- Key mappings
        vim.keymap.set("n", "<F7>", show_simple_inspector,
            {desc = "Code Inspector", silent = true})

        vim.keymap.set("n", "<leader>ls", show_simple_inspector,
            {desc = "Document symbols", silent = true})

        vim.keymap.set("n", "<leader>lg", show_grouped_inspector,
            {desc = "Document symbols (grouped)", silent = true})

        -- User commands
        vim.api.nvim_create_user_command("CodeInspector",
            show_simple_inspector,
            {desc = "Open Code Inspector"})

        vim.api.nvim_create_user_command("CodeInspectorGrouped",
            show_grouped_inspector,
            {desc = "Open Code Inspector (grouped by type)"})

        -- Set up highlight groups for symbol colors
        for kind, color in pairs(symbol_colors) do
            vim.api.nvim_set_hl(0, "TelescopeSymbol" .. kind, {fg = color})
        end

        -- Workspace Inspector
        local function show_workspace_inspector()
            local clients = vim.lsp.get_clients({bufnr = 0})
            if #clients == 0 then
                vim.notify("Workspace Inspector: No LSP client attached", vim.log.levels.WARN)
                return
            end

            require("telescope.builtin").lsp_workspace_symbols(themes.get_dropdown({
                winblend = 10,
                previewer = true,
                layout_config = { width = 0.9, height = 0.8 },
                prompt_title = " Workspace Inspector ",
                results_title = " All Symbols ",
            }))
        end

        _G.WorkspaceInspector = show_workspace_inspector
    end
}