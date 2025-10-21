-- ~/.config/nvim/lua/plugins/telescope-replace.lua
-- Custom Telescope-based find & replace with modal UI

return {
    "nvim-lua/plenary.nvim",
    lazy = false,
    priority = 800,
    config = function()
        -- Store search results globally
        _G.TelescopeReplace = {
            results = {},
            search_term = "",
        }

        -- Function to perform replacement
        local function do_replace(old_pattern, new_text, opts)
            opts = opts or {}
            local case_sensitive = opts.case_sensitive or false

            if #_G.TelescopeReplace.results == 0 then
                vim.notify("No search results to replace",
                    vim.log.levels.WARN)
                return
            end

            -- Group results by file
            local files = {}
            for _, result in ipairs(_G.TelescopeReplace.results) do
                local file = result.filename
                if not files[file] then
                    files[file] = {}
                end
                table.insert(files[file], result)
            end

            -- Escape pattern for literal search
            local search_pattern = vim.fn.escape(old_pattern,
                "/\\.*^$[]")

            -- Count total replacements
            local total_files = 0
            local total_replacements = 0

            -- Perform replacement in each file
            for file, _ in pairs(files) do
                local bufnr = vim.fn.bufnr(file)
                local buf_existed = bufnr ~= -1

                -- Load buffer if not loaded
                if not buf_existed then
                    vim.cmd("silent edit " ..
                        vim.fn.fnameescape(file))
                    bufnr = vim.fn.bufnr(file)
                end

                -- Perform replacement
                local lines = vim.api.nvim_buf_get_lines(
                    bufnr, 0, -1, false)
                local changed = false
                local file_replacements = 0

                for i, line in ipairs(lines) do
                    local new_line, count

                    if case_sensitive then
                        new_line, count = line:gsub(
                            vim.pesc(old_pattern),
                            new_text
                        )
                    else
                        -- Case insensitive: find all matches
                        local pattern = old_pattern:lower()
                        local line_lower = line:lower()
                        local pos = 1
                        local result = ""
                        count = 0

                        while true do
                            local start_idx, end_idx =
                                line_lower:find(pattern, pos, true)
                            if not start_idx then
                                result = result .. line:sub(pos)
                                break
                            end

                            result = result .. line:sub(pos,
                                start_idx - 1) .. new_text
                            pos = end_idx + 1
                            count = count + 1
                        end

                        if count > 0 then
                            new_line = result
                        else
                            new_line = line
                        end
                    end

                    if count > 0 then
                        lines[i] = new_line
                        changed = true
                        file_replacements = file_replacements + count
                    end
                end

                if changed then
                    vim.api.nvim_buf_set_lines(bufnr, 0, -1,
                        false, lines)
                    vim.api.nvim_buf_call(bufnr, function()
                        vim.cmd("silent write")
                    end)
                    total_files = total_files + 1
                    total_replacements = total_replacements +
                        file_replacements
                end
            end

            vim.notify(
                string.format(
                    "✅ Replaced %d occurrences in %d files",
                    total_replacements,
                    total_files
                ),
                vim.log.levels.INFO
            )

            -- Clear results
            _G.TelescopeReplace.results = {}
        end

        -- Helper to get CWD
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

        -- Custom Telescope find & replace
        vim.keymap.set("n", "<leader>fc", function()
            local telescope_ok, telescope =
                pcall(require, "telescope.builtin")
            if not telescope_ok then
                vim.notify("Telescope not loaded",
                    vim.log.levels.ERROR)
                return
            end

            local actions = require("telescope.actions")
            local action_state = require("telescope.actions.state")

            telescope.live_grep({
                prompt_title = "🔍 Find & Replace (Ctrl-R)",
                cwd = get_cwd(),
                attach_mappings = function(prompt_bufnr, map)
                    -- Ctrl-R to start replacement
                    map("i", "<C-r>", function()
                        local picker = action_state
                            .get_current_picker(prompt_bufnr)
                        local search_query = picker:_get_prompt()

                        -- Get all results
                        local manager = picker.manager
                        local results = {}
                        for entry in manager:iter() do
                            table.insert(results, entry)
                        end

                        if #results == 0 then
                            vim.notify("No results found",
                                vim.log.levels.WARN)
                            return
                        end

                        actions.close(prompt_bufnr)

                        -- Store results
                        _G.TelescopeReplace.results = results
                        _G.TelescopeReplace.search_term = search_query

                        -- Show replacement dialog
                        vim.schedule(function()
                            vim.ui.input({
                                prompt = string.format(
                                    "Replace '%s' with: ",
                                    search_query
                                ),
                                default = "",
                            }, function(replacement)
                                if not replacement then
                                    return
                                end

                                -- Ask for confirmation
                                vim.ui.select(
                                    {
                                        "Yes, replace all",
                                        "No, cancel"
                                    },
                                    {
                                        prompt = string.format(
                                            "Replace %d occurrences?",
                                            #results
                                        ),
                                    },
                                    function(choice)
                                        if choice ==
                                            "Yes, replace all" then
                                            do_replace(
                                                search_query,
                                                replacement,
                                                {
                                                    case_sensitive = false
                                                }
                                            )
                                        end
                                    end
                                )
                            end)
                        end)
                    end)

                    return true
                end,
            })
        end, {desc = "Live Change (Find & Replace)"})

        -- Quick replace current word
        vim.keymap.set("n", "<leader>fC", function()
            local word = vim.fn.expand("<cword>")
            local telescope_ok, telescope =
                pcall(require, "telescope.builtin")
            if not telescope_ok then
                return
            end

            local actions = require("telescope.actions")
            local action_state = require("telescope.actions.state")

            telescope.grep_string({
                prompt_title = string.format(
                    "🔍 Replace '%s' (Ctrl-R)",
                    word
                ),
                search = word,
                cwd = get_cwd(),
                attach_mappings = function(prompt_bufnr, map)
                    map("i", "<C-r>", function()
                        local picker = action_state
                            .get_current_picker(prompt_bufnr)
                        local manager = picker.manager
                        local results = {}
                        for entry in manager:iter() do
                            table.insert(results, entry)
                        end

                        if #results == 0 then
                            vim.notify("No results found",
                                vim.log.levels.WARN)
                            return
                        end

                        actions.close(prompt_bufnr)
                        _G.TelescopeReplace.results = results
                        _G.TelescopeReplace.search_term = word

                        vim.schedule(function()
                            vim.ui.input({
                                prompt = string.format(
                                    "Replace '%s' with: ",
                                    word
                                ),
                                default = word,
                            }, function(replacement)
                                if not replacement then
                                    return
                                end

                                vim.ui.select(
                                    {
                                        "Yes, replace all",
                                        "No, cancel"
                                    },
                                    {
                                        prompt = string.format(
                                            "Replace %d occurrences?",
                                            #results
                                        ),
                                    },
                                    function(choice)
                                        if choice ==
                                            "Yes, replace all" then
                                            do_replace(
                                                word,
                                                replacement,
                                                {case_sensitive = true}
                                            )
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

        -- Visual mode: replace selected text
        vim.keymap.set("v", "<leader>fc", function()
            -- Get selected text
            vim.cmd('noau normal! "vy"')
            local selected = vim.fn.getreg("v")
            selected = vim.fn.escape(selected, "\n")

            local telescope_ok, telescope =
                pcall(require, "telescope.builtin")
            if not telescope_ok then
                return
            end

            local actions = require("telescope.actions")
            local action_state = require("telescope.actions.state")

            telescope.grep_string({
                prompt_title = string.format(
                    "🔍 Replace '%s' (Ctrl-R)",
                    selected
                ),
                search = selected,
                cwd = get_cwd(),
                attach_mappings = function(prompt_bufnr, map)
                    map("i", "<C-r>", function()
                        local picker = action_state
                            .get_current_picker(prompt_bufnr)
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
                                prompt = string.format(
                                    "Replace '%s' with: ",
                                    selected
                                ),
                                default = "",
                            }, function(replacement)
                                if not replacement then
                                    return
                                end

                                vim.ui.select(
                                    {
                                        "Yes, replace all",
                                        "No, cancel"
                                    },
                                    {
                                        prompt = string.format(
                                            "Replace %d occurrences?",
                                            #results
                                        ),
                                    },
                                    function(choice)
                                        if choice ==
                                            "Yes, replace all" then
                                            do_replace(
                                                selected,
                                                replacement,
                                                {case_sensitive = true}
                                            )
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

        vim.notify("✅ Telescope Replace loaded", vim.log.levels.INFO)
    end,
}