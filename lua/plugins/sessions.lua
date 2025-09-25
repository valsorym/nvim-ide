-- ~/.config/nvim/lua/plugins/sessions.lua
-- Sessions with full Telescope integration like workspace/tree-history

return {
    -- Persistence.nvim - simple and reliable
    {
        "folke/persistence.nvim",
        event = "BufReadPre",
        opts = {
            dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/"),
            options = { "buffers", "curdir", "tabpages", "winsize" },
            pre_save = function()
                pcall(function()
                    if vim.fn.exists(":NvimTreeClose") == 2 then
                        vim.cmd("NvimTreeClose")
                    end
                end)
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    local config = vim.api.nvim_win_get_config(win)
                    if config.relative ~= "" then
                        pcall(vim.api.nvim_win_close, win, true)
                    end
                end
            end,
            save_empty = false,
        },
        keys = {
            {
                "<leader>wS",
                function()
                    require("persistence").load()
                    vim.notify("Session restored", vim.log.levels.INFO, {
                        title = "Workspace",
                        icon = "",
                        timeout = 2000,
                    })
                end,
                desc = "· Restore Session"
            },
            {
                "<leader>wL",
                function()
                    require("persistence").load({ last = true })
                    vim.notify("Last session restored", vim.log.levels.INFO, {
                        title = "Workspace",
                        icon = "",
                        timeout = 2000,
                    })
                end,
                desc = "· Restore Last Session"
            },
            {
                "<leader>wD",
                function()
                    require("persistence").stop()
                    vim.notify("Session saving disabled", vim.log.levels.WARN, {
                        title = "Workspace",
                        icon = "",
                        timeout = 2000,
                    })
                end,
                desc = "· Delete Session"
            },
        },
    },

    -- Auto-session with Telescope integration
    {
        "rmagatti/auto-session",
        dependencies = {
            "nvim-telescope/telescope.nvim",
        },
        lazy = false,
        config = function()
            require("auto-session").setup({
                log_level = "error",
                auto_session_enabled = true,
                auto_save_enabled = true,
                auto_restore_enabled = false,
                auto_session_suppress_dirs = {
                    "~/",
                    "~/Downloads",
                    "/tmp",
                    "/",
                },
                auto_session_use_git_branch = false,

                pre_save_cmds = {
                    function()
                        if vim.fn.exists(":NvimTreeClose") == 2 then
                            vim.cmd("NvimTreeClose")
                        end
                    end
                },

                post_restore_cmds = {
                    function()
                        vim.defer_fn(function()
                            local cwd = vim.fn.getcwd()
                            local name = vim.fn.fnamemodify(cwd, ":t")
                            vim.o.titlestring = name
                        end, 100)
                    end
                },
            })

            -- Telescope session picker (схожий на nvim-tree history)
            local function telescope_sessions()
                local pickers = require("telescope.pickers")
                local finders = require("telescope.finders")
                local conf = require("telescope.config").values
                local actions = require("telescope.actions")
                local action_state = require("telescope.actions.state")
                local entry_display = require("telescope.pickers.entry_display")

                local sessions_dir = vim.fn.stdpath("data") .. "/sessions"

                if vim.fn.isdirectory(sessions_dir) == 0 then
                    vim.notify("No sessions found", vim.log.levels.WARN, {
                        title = "Sessions",
                        icon = "",
                        timeout = 2000,
                    })
                    return
                end

                local sessions = vim.fn.glob(sessions_dir .. "/*", false, true)
                if #sessions == 0 then
                    vim.notify("No sessions found", vim.log.levels.WARN, {
                        title = "Sessions",
                        icon = "",
                        timeout = 2000,
                    })
                    return
                end

                -- URL decode function
                local function url_decode(str)
                    str = str:gsub("%%(%x%x)", function(hex)
                        return string.char(tonumber(hex, 16))
                    end)
                    return str
                end

                local session_entries = {}
                for _, session_path in ipairs(sessions) do
                    local filename = vim.fn.fnamemodify(session_path, ":t")
                    -- Правильний URL decode замість простої заміни %
                    local path = url_decode(filename):gsub("%.vim$", "")
                    local name = vim.fn.fnamemodify(path, ":t")
                    local parent = vim.fn.fnamemodify(path, ":h:t")

                    -- Get session modification time
                    local stat = vim.loop.fs_stat(session_path)
                    local mtime = stat and stat.mtime.sec or 0
                    local time_str = os.date("%d.%m.%Y %H:%M", mtime)

                    table.insert(session_entries, {
                        name = name,
                        path = path,
                        parent = parent ~= "." and parent or "",
                        file_path = session_path,
                        mtime = mtime,
                        time_str = time_str,
                    })
                end

                -- Sort by modification time (newest first)
                table.sort(session_entries, function(a, b)
                    return a.mtime > b.mtime
                end)

                -- Display formatter (схожий на nvim-tree history)
                local displayer = entry_display.create({
                    separator = " ",
                    items = {
                        { width = 3 },  -- index
                        { width = 30 }, -- name/path
                        { remaining = true }, -- time
                    },
                })

                local function make_display(entry)
                    local display_name = entry.parent ~= ""
                        and entry.parent .. "/" .. entry.name
                        or entry.name

                    return displayer({
                        { entry.index .. ".", "TelescopePromptCounter" },
                        { " " .. display_name, "TelescopeResultsIdentifier" },
                        { entry.time_str, "TelescopeResultsComment" },
                    })
                end

                -- Add index to entries
                for i, entry in ipairs(session_entries) do
                    entry.index = i
                    entry.display = make_display
                    entry.ordinal = entry.name .. " " .. entry.path .. " " .. entry.time_str
                    entry.value = entry
                end

                pickers.new({}, {
                    prompt_title = " Sessions",
                    results_title = string.format(" Available Sessions (%d)", #session_entries),
                    finder = finders.new_table({
                        results = session_entries,
                        entry_maker = function(entry) return entry end,
                    }),
                    sorter = conf.generic_sorter({}),
                    attach_mappings = function(prompt_bufnr, map)
                        local function restore_session()
                            local selection = action_state.get_selected_entry()
                            if not selection then return end

                            actions.close(prompt_bufnr)

                            vim.schedule(function()
                                pcall(function()
                                    vim.cmd("source " .. vim.fn.fnameescape(selection.value.file_path))
                                    vim.notify("Session restored: " .. selection.value.name, vim.log.levels.INFO, {
                                        title = "Sessions",
                                        icon = "",
                                        timeout = 2500,
                                    })
                                end)
                            end)
                        end

                        local function delete_session()
                            local selection = action_state.get_selected_entry()
                            if not selection then return end

                            local choice = vim.fn.confirm(
                                "Delete session '" .. selection.value.name .. "'?",
                                "&Yes\n&No",
                                2
                            )

                            if choice == 1 then
                                pcall(vim.fn.delete, selection.value.file_path)
                                vim.notify("Session deleted: " .. selection.value.name, vim.log.levels.WARN, {
                                    title = "Sessions",
                                    icon = "",
                                    timeout = 2000,
                                })
                                -- Refresh picker
                                actions.close(prompt_bufnr)
                                telescope_sessions()
                            end
                        end

                        map("i", "<CR>", restore_session)
                        map("n", "<CR>", restore_session)
                        map("i", "<C-d>", delete_session)
                        map("n", "d", delete_session)
                        map("i", "<C-r>", function()
                            actions.close(prompt_bufnr)
                            telescope_sessions()
                        end)

                        return true
                    end,
                }):find()
            end

            -- Global function for keymap access
            _G.TelescopeSessions = telescope_sessions

            -- Updated API commands
            vim.api.nvim_create_user_command("SessionSave", function()
                require("auto-session").save_session()
                local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
                vim.notify("Session saved: " .. cwd, vim.log.levels.INFO, {
                    title = "Sessions",
                    icon = "",
                    timeout = 2000,
                })
            end, { desc = "Save current session" })

            vim.api.nvim_create_user_command("SessionRestore", function()
                require("auto-session").restore_session()
                vim.notify("Session restored", vim.log.levels.INFO, {
                    title = "Sessions",
                    icon = "",
                    timeout = 2000,
                })
            end, { desc = "Restore session" })

            vim.api.nvim_create_user_command("SessionDelete", function()
                require("auto-session").delete_session()
                vim.notify("Session deleted", vim.log.levels.WARN, {
                    title = "Sessions",
                    icon = "",
                    timeout = 2000,
                })
            end, { desc = "Delete session" })

            -- Keymaps with Telescope.
            vim.keymap.set("n", "<leader>wS", "<cmd>SessionSave<cr>", { desc = "· Save session" })
            vim.keymap.set("n", "<leader>wR", "<cmd>SessionRestore<cr>", { desc = "· Restore session" })
            vim.keymap.set("n", "<leader>wD", "<cmd>SessionDelete<cr>", { desc = "· Delete session" })
            vim.keymap.set("n", "<leader>wF", telescope_sessions, { desc = "· Find sessions" })
        end,
    }
}