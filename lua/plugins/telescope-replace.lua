-- ~/.config/nvim/lua/plugins/telescope-replace.lua
-- Custom Telescope-based find & replace with modal UI and history.

local history_file = vim.fn.stdpath("data") .. "/telescope_replace_history.txt"
local max_history = 10
local search_history = {}

-- Load history from file.
local function load_search_history()
    search_history = {}
    local file = io.open(history_file, "r")
    if not file then return end

    for line in file:lines() do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" then
            table.insert(search_history, line)
        end
    end
    file:close()
end

-- Save history to file.
local function save_search_history()
    local file = io.open(history_file, "w")
    if not file then return end

    for i = 1, math.min(#search_history, max_history) do
        file:write(search_history[i] .. "\n")
    end
    file:close()
end

-- Add query to history.
local function add_to_search_history(query)
    if not query or query == "" then return end

    -- Remove duplicates.
    for i = #search_history, 1, -1 do
        if search_history[i] == query then
            table.remove(search_history, i)
        end
    end

    -- Add to beginning.
    table.insert(search_history, 1, query)

    -- Limit size.
    while #search_history > max_history do
        table.remove(search_history)
    end

    save_search_history()
end

-- Convert ripgrep/telescope pattern to literal string
local function normalize_pattern_to_literal(pattern)
    -- Convert common regex escapes to literal characters
    local literal = pattern
    literal = literal:gsub("\\%.", ".")  -- \. -> .
    literal = literal:gsub("\\%*", "*")  -- \* -> *
    literal = literal:gsub("\\%+", "+")  -- \+ -> +
    literal = literal:gsub("\\%?", "?")  -- \? -> ?
    literal = literal:gsub("\\%(", "(")  -- \( -> (
    literal = literal:gsub("\\%)", ")")  -- \) -> )
    literal = literal:gsub("\\%[", "[")  -- \[ -> [
    literal = literal:gsub("\\%]", "]")  -- \] -> ]
    literal = literal:gsub("\\%{", "{")  -- \{ -> {
    literal = literal:gsub("\\%}", "}")  -- \} -> }
    literal = literal:gsub("\\%^", "^")  -- \^ -> ^
    literal = literal:gsub("\\%$", "$")  -- \$ -> $
    literal = literal:gsub("\\\\", "\\") -- \\ -> \
    return literal
end

-- Load history on startup.
load_search_history()

return {
    "nvim-lua/plenary.nvim",
    lazy = false,
    priority = 800,
    config = function()
        -- Store search results globally.
        _G.TelescopeReplace = {
            results = {},
            search_term = "",
        }

        -- Function to perform replacement.
        local function do_replace(old_pattern, new_text, opts)
            opts = opts or {}
            local case_sensitive = opts.case_sensitive or false

            if #_G.TelescopeReplace.results == 0 then
                vim.notify("No search results to replace", vim.log.levels.WARN)
                return
            end

            -- Convert pattern to literal string for consistent replacement
            local literal_pattern = normalize_pattern_to_literal(old_pattern)

            -- Group results by file.
            local files = {}
            for _, result in ipairs(_G.TelescopeReplace.results) do
                local file = result.filename
                if not files[file] then
                    files[file] = {}
                end
                table.insert(files[file], result)
            end

            -- Count total replacements.
            local total_files = 0
            local total_replacements = 0

            -- Perform replacement in each file.
            for file, _ in pairs(files) do
                local bufnr = vim.fn.bufnr(file)
                local buf_existed = bufnr ~= -1

                -- Load buffer if not loaded.
                if not buf_existed then
                    vim.cmd("silent edit " .. vim.fn.fnameescape(file))
                    bufnr = vim.fn.bufnr(file)
                end

                -- Perform replacement.
                local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                local changed = false
                local file_replacements = 0

                for i, line in ipairs(lines) do
                    local new_line = ""
                    local count = 0
                    local pos = 1

                    local search_in_line = case_sensitive and line or line:lower()
                    local search_pattern = case_sensitive and literal_pattern or literal_pattern:lower()

                    while true do
                        local start_idx, end_idx = search_in_line:find(search_pattern, pos, true) -- true = literal search
                        if not start_idx then
                            new_line = new_line .. line:sub(pos)
                            break
                        end

                        -- Add text before match
                        new_line = new_line .. line:sub(pos, start_idx - 1)
                        -- Add replacement text
                        new_line = new_line .. new_text

                        pos = end_idx + 1
                        count = count + 1
                    end

                    if count > 0 then
                        lines[i] = new_line
                        changed = true
                        file_replacements = file_replacements + count
                    end
                end

                if changed then
                    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
                    vim.api.nvim_buf_call(bufnr, function()
                        vim.cmd("silent write")
                    end)
                    total_files = total_files + 1
                    total_replacements = total_replacements + file_replacements
                end
            end

            vim.notify(
                string.format("✅ Replaced %d occurrences in %d files", total_replacements, total_files),
                vim.log.levels.INFO
            )

            -- Clear results.
            _G.TelescopeReplace.results = {}
        end

        -- Helper to get CWD.
        local function get_cwd()
            local cwd = vim.fn.getcwd()
            local ok, api = pcall(require, "nvim-tree.api")
            if ok and api.tree.is_visible() then
                local root = api.tree.get_root()
                if root and root.absolute_path then
                    cwd = root.absolute_path
                end
            end
            return cwd
        end

        -- History navigation state.
        local hist_index = 0

        -- Find & Replace (respects .gitignore).
        vim.keymap.set("n", "<leader>fc", function()
            local telescope_ok, telescope = pcall(require, "telescope.builtin")
            if not telescope_ok then
                vim.notify("Telescope not loaded", vim.log.levels.ERROR)
                return
            end

            local actions = require("telescope.actions")
            local action_state = require("telescope.actions.state")

            -- Reset history index.
            hist_index = 0

            telescope.live_grep({
                prompt_title = "🔍 Find & Replace (Alt-r Replace, Alt+↑/↓ History)",
                cwd = get_cwd(),
                attach_mappings = function(prompt_bufnr, map)
                    -- History navigation.
                    map("i", "<A-Up>", function()
                        if #search_history == 0 then return end
                        hist_index = math.min(hist_index + 1, #search_history)
                        local picker = action_state.get_current_picker(prompt_bufnr)
                        if picker and search_history[hist_index] then
                            picker:reset_prompt(search_history[hist_index])
                        end
                    end)

                    map("i", "<A-Down>", function()
                        if #search_history == 0 then return end
                        hist_index = math.max(hist_index - 1, 0)
                        local picker = action_state.get_current_picker(prompt_bufnr)
                        if picker then
                            picker:reset_prompt(hist_index > 0 and search_history[hist_index] or "")
                        end
                    end)

                    map("i", "<A-r>", function()
                        local picker = action_state.get_current_picker(prompt_bufnr)
                        local search_query = picker:_get_prompt()

                        -- Save to history.
                        if search_query and search_query ~= "" then
                            add_to_search_history(search_query)
                        end

                        local manager = picker.manager
                        local results = {}
                        for entry in manager:iter() do
                            table.insert(results, entry)
                        end

                        if #results == 0 then
                            vim.notify("No results found", vim.log.levels.WARN)
                            return
                        end

                        actions.close(prompt_bufnr)
                        _G.TelescopeReplace.results = results
                        _G.TelescopeReplace.search_term = search_query

                        vim.schedule(function()
                            vim.ui.input({
                                prompt = string.format("Replace '%s' with: ", search_query),
                                default = "",
                            }, function(replacement)
                                if not replacement then return end

                                vim.ui.select(
                                    {"Yes, replace all", "No, cancel"},
                                    {
                                        prompt = string.format("Replace %d occurrences?", #results),
                                    },
                                    function(choice)
                                        if choice == "Yes, replace all" then
                                            do_replace(search_query, replacement, {case_sensitive = false})
                                        end
                                    end
                                )
                            end)
                        end)
                    end)

                    -- Save history when buffer is closed (on_detach)
                    vim.api.nvim_buf_attach(prompt_bufnr, false, {
                        on_detach = function()
                            -- Use pcall to safely get prompt
                            local ok, picker = pcall(action_state.get_current_picker, prompt_bufnr)
                            if ok and picker then
                                local success, query = pcall(function()
                                    return picker:_get_prompt()
                                end)
                                if success and query and query ~= "" then
                                    add_to_search_history(query)
                                end
                            end
                        end
                    })

                    return true
                end,
            })
        end, {desc = "Find & Replace"})

        -- Find & Replace (include ignored files).
        vim.keymap.set("n", "<leader>fC", function()
            local telescope_ok, telescope = pcall(require, "telescope.builtin")
            if not telescope_ok then
                vim.notify("Telescope not loaded", vim.log.levels.ERROR)
                return
            end

            local actions = require("telescope.actions")
            local action_state = require("telescope.actions.state")

            hist_index = 0

            telescope.live_grep({
                prompt_title = "🔍 Find & Replace ALL (Alt-r, Alt+↑/↓ History)",
                cwd = get_cwd(),
                additional_args = function()
                    return {"--no-ignore", "--hidden", "--glob", "!.git/"}
                end,
                attach_mappings = function(prompt_bufnr, map)
                    map("i", "<A-Up>", function()
                        if #search_history == 0 then return end
                        hist_index = math.min(hist_index + 1, #search_history)
                        local picker = action_state.get_current_picker(prompt_bufnr)
                        if picker and search_history[hist_index] then
                            picker:reset_prompt(search_history[hist_index])
                        end
                    end)

                    map("i", "<A-Down>", function()
                        if #search_history == 0 then return end
                        hist_index = math.max(hist_index - 1, 0)
                        local picker = action_state.get_current_picker(prompt_bufnr)
                        if picker then
                            picker:reset_prompt(hist_index > 0 and search_history[hist_index] or "")
                        end
                    end)

                    map("i", "<A-r>", function()
                        local picker = action_state.get_current_picker(prompt_bufnr)
                        local search_query = picker:_get_prompt()

                        if search_query and search_query ~= "" then
                            add_to_search_history(search_query)
                        end

                        local manager = picker.manager
                        local results = {}
                        for entry in manager:iter() do
                            table.insert(results, entry)
                        end

                        if #results == 0 then
                            vim.notify("No results found", vim.log.levels.WARN)
                            return
                        end

                        actions.close(prompt_bufnr)
                        _G.TelescopeReplace.results = results
                        _G.TelescopeReplace.search_term = search_query

                        vim.schedule(function()
                            vim.ui.input({
                                prompt = string.format("Replace '%s' with: ", search_query),
                                default = "",
                            }, function(replacement)
                                if not replacement then return end

                                vim.ui.select(
                                    {"Yes, replace all", "No, cancel"},
                                    {
                                        prompt = string.format("Replace %d occurrences?", #results),
                                    },
                                    function(choice)
                                        if choice == "Yes, replace all" then
                                            do_replace(search_query, replacement, {case_sensitive = false})
                                        end
                                    end
                                )
                            end)
                        end)
                    end)

                    vim.api.nvim_buf_attach(prompt_bufnr, false, {
                        on_detach = function()
                            local ok, picker = pcall(action_state.get_current_picker, prompt_bufnr)
                            if ok and picker then
                                local success, query = pcall(function()
                                    return picker:_get_prompt()
                                end)
                                if success and query and query ~= "" then
                                    add_to_search_history(query)
                                end
                            end
                        end
                    })

                    return true
                end,
            })
        end, {desc = "Find & Replace (include ignored)"})

        -- Replace current Word.
        vim.keymap.set("n", "<leader>fx", function()
            local word = vim.fn.expand("<cword>")
            local telescope_ok, telescope = pcall(require, "telescope.builtin")
            if not telescope_ok then return end

            local actions = require("telescope.actions")
            local action_state = require("telescope.actions.state")

            telescope.grep_string({
                prompt_title = string.format("🔍 Replace '%s' (Alt-r)", word),
                search = word,
                cwd = get_cwd(),
                attach_mappings = function(prompt_bufnr, map)
                    map("i", "<A-r>", function()
                        local picker = action_state.get_current_picker(prompt_bufnr)
                        local manager = picker.manager
                        local results = {}
                        for entry in manager:iter() do
                            table.insert(results, entry)
                        end

                        if #results == 0 then
                            vim.notify("No results found", vim.log.levels.WARN)
                            return
                        end

                        actions.close(prompt_bufnr)
                        _G.TelescopeReplace.results = results
                        _G.TelescopeReplace.search_term = word

                        vim.schedule(function()
                            vim.ui.input({
                                prompt = string.format("Replace '%s' with: ", word),
                                default = word,
                            }, function(replacement)
                                if not replacement then return end

                                vim.ui.select(
                                    {"Yes, replace all", "No, cancel"},
                                    {
                                        prompt = string.format("Replace %d occurrences?", #results),
                                    },
                                    function(choice)
                                        if choice == "Yes, replace all" then
                                            do_replace(word, replacement, {case_sensitive = true})
                                        end
                                    end
                                )
                            end)
                        end)
                    end)

                    return true
                end,
            })
        end, {desc = "Replace current word"})

        -- Visual mode: replace selected text (respects .gitignore).
        vim.keymap.set("v", "<leader>fc", function()
            vim.cmd('noau normal! "vy"')
            local selected = vim.fn.getreg("v")
            selected = vim.fn.escape(selected, "\n")

            local telescope_ok, telescope = pcall(require, "telescope.builtin")
            if not telescope_ok then return end

            local actions = require("telescope.actions")
            local action_state = require("telescope.actions.state")

            telescope.grep_string({
                prompt_title = string.format("🔍 Replace '%s' (Alt-r)", selected),
                search = selected,
                cwd = get_cwd(),
                attach_mappings = function(prompt_bufnr, map)
                    map("i", "<A-r>", function()
                        local picker = action_state.get_current_picker(prompt_bufnr)
                        local manager = picker.manager
                        local results = {}
                        for entry in manager:iter() do
                            table.insert(results, entry)
                        end

                        actions.close(prompt_bufnr)
                        _G.TelescopeReplace.results = results
                        _G.TelescopeReplace.search_term = selected

                        vim.schedule(function()
                            vim.ui.input({
                                prompt = string.format("Replace '%s' with: ", selected),
                                default = "",
                            }, function(replacement)
                                if not replacement then return end

                                vim.ui.select(
                                    {"Yes, replace all", "No, cancel"},
                                    {
                                        prompt = string.format("Replace %d occurrences?", #results),
                                    },
                                    function(choice)
                                        if choice == "Yes, replace all" then
                                            do_replace(selected, replacement, {case_sensitive = true})
                                        end
                                    end
                                )
                            end)
                        end)
                    end)

                    return true
                end,
            })
        end, {desc = "Replace selected text"})
    end,
}