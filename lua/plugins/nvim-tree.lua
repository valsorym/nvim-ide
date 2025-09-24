-- ~/.config/nvim/lua/plugins/nvim-tree.lua
-- Modal file explorer with project history functionality

return {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        "nvim-lua/plenary.nvim"
    },
    config = function()
        -- Disable netrw (conflicts with nvim-tree).
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1

        -- Global namespace for root history.
        _G.NvimTreeHistory = {}

        local history_file = vim.fn.stdpath("data") .. "/.last_projects.json"
        local max_history = 20

        -- Load history from file.
        local function load_history()
            local file = io.open(history_file, "r")
            if file then
                local content = file:read("*all")
                file:close()
                local ok, data = pcall(vim.json.decode, content)
                if ok and type(data) == "table" then
                    return data
                end
            end
            return {}
        end

        -- Save history to file.
        local function save_history(history)
            local file = io.open(history_file, "w")
            if file then
                file:write(vim.json.encode(history))
                file:close()
            end
        end

        -- Add root to history.
        function _G.NvimTreeHistory.add_root(root_path)
            if not root_path or root_path == "" then
                return
            end

            local history = load_history()

            -- Remove if already exists.
            for i = #history, 1, -1 do
                if history[i].path == root_path then
                    table.remove(history, i)
                end
            end

            -- Add to beginning.
            table.insert(history, 1, {
                path = root_path,
                name = vim.fn.fnamemodify(root_path, ":t"),
                parent = vim.fn.fnamemodify(root_path, ":h:t"),
                timestamp = os.time()
            })

            -- Limit history size.
            while #history > max_history do
                table.remove(history)
            end

            save_history(history)
        end

        -- Update window title with current root.
        local function update_window_title()
            local current_root = vim.fn.getcwd()
            local project_name = vim.fn.fnamemodify(current_root, ":t")

            -- Use same formatting logic as history display
            local display_path = current_root
            local display_width = 36
            if #current_root > display_width then
                display_path = "…" .. current_root:sub(-(display_width - 1))
            end

            vim.o.title = true  -- Enable title
            vim.o.titlestring = project_name .. " - " .. display_path
        end

        -- Helper function to format path display.
        -- local function format_path_display(path, max_width)
        --     local parts = vim.split(path, "/", {plain = true})

        --     -- Remove empty parts.
        --     local filtered_parts = {}
        --     for _, part in ipairs(parts) do
        --         if part ~= "" then
        --             table.insert(filtered_parts, part)
        --         end
        --     end

        --     -- If we have 3 or fewer parts, show full path.
        --     if #filtered_parts <= 3 then
        --         return path
        --     end

        --     -- Take last 3 parts.
        --     local last_three = {}
        --     for i = math.max(1, #filtered_parts - 2), #filtered_parts do
        --         table.insert(last_three, filtered_parts[i])
        --     end

        --     local short_path = "···/" .. table.concat(last_three, "/")

        --     -- If still too long, truncate further.
        --     if #short_path > max_width then
        --         return "···/" .. short_path:sub(-(max_width - 4))
        --     end

        --     return short_path
        -- end
        local function format_path_display(path, max_width)
            -- If path is longer than max_width, show last 36
            -- characters with prefix.
            local display_width = 36
            if #path > display_width then
                return "…" .. path:sub(-(display_width - 1))
            end

            return path
        end

        -- Show root history window.
        function _G.NvimTreeHistory.show_history()
            local history = load_history()

            if #history == 0 then
                print("No root directories in history")
                return
            end

            -- Create buffer.
            local buf = vim.api.nvim_create_buf(false, true)

            -- Calculate window size.
            local width = math.min(80, vim.o.columns - 10)
            local height = math.min(15, #history + 5)

            -- Calculate position.
            local row = math.floor((vim.o.lines - height) / 2)
            local col = math.floor((vim.o.columns - width) / 2)

            -- Create window.
            local win_opts = {
                relative = "editor",
                width = width,
                height = height,
                row = row,
                col = col,
                style = "minimal",
                border = "rounded",
                title = " Root Directories History ",
                title_pos = "center",
                zindex = 1000
            }

            local win = vim.api.nvim_open_win(buf, true, win_opts)

            -- Prepare content.
            local lines = {}
            local line_to_path = {}

            -- Header.
            table.insert(lines, "")
            table.insert(lines, string.format(" 󰋚  Number of recent projects: %d", #history))
            table.insert(lines, string.rep("─", width))
            table.insert(lines, "")

            -- History entries
            for i, entry in ipairs(history) do
                -- Format timestamp.
                local time_str = os.date("%d.%m.%Y %H:%M", entry.timestamp)

                -- Calculate available space for path (reserve space for number, time, and padding).
                local path_width = width - 8 - #time_str - 3 -- "99. " + time + padding

                -- Format path display.
                local display_path = format_path_display(entry.path, path_width)

                -- Create line with proper spacing.
                local line = string.format(" %2d. %s", i, display_path)
                local padding_needed = width - #line - #time_str - 1
                if padding_needed > 0 then
                    line = line .. string.rep(" ", padding_needed) .. time_str
                else
                    -- If no space, just add the time at the end.
                    line = line .. " " .. time_str
                end

                table.insert(lines, line)
                line_to_path[#lines] = entry.path
            end

            -- table.insert(lines, "")
            -- table.insert(lines, " Keys: <CR>=set root, d=remove, C=clear all, q/ESC=quit")

            -- Set buffer content
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            vim.bo[buf].modifiable = false
            vim.bo[buf].buftype = "nofile"
            vim.bo[buf].bufhidden = "wipe"

            -- Enable cursor line
            vim.wo[win].cursorline = true

            -- Helper function to close window
            local function close_window()
                if vim.api.nvim_win_is_valid(win) then
                    vim.api.nvim_win_close(win, true)
                end
            end

            -- Helper function to refresh window
            local function refresh_window()
                close_window()
                _G.NvimTreeHistory.show_history()
            end

            -- Set up keymaps
            local keymap_opts = {buffer = buf, nowait = true, silent = true}

            -- Helper: check if we are on Dashboard or empty startup buffer
            local function on_dashboard()
                local cur = vim.api.nvim_get_current_buf()
                return vim.bo[cur].filetype == "dashboard"
                    or (vim.fn.bufname(cur) == "" and not vim.bo[cur].modified)
            end

            -- Set root with Enter (without creating new tab from Dashboard)
            vim.keymap.set("n", "<CR>", function()
                local line_nr = vim.fn.line(".")
                local root_path = line_to_path[line_nr]
                if not root_path then
                    return
                end
                if vim.fn.isdirectory(root_path) ~= 1 then
                    print("Directory no longer exists: " .. root_path)
                    return
                end

                close_window()

                vim.schedule(function()
                    local api = require("nvim-tree.api")

                    -- If we're on dashboard, handle specially
                    if on_dashboard() then
                        -- Just change root without opening tree
                        api.tree.change_root(root_path)
                        vim.defer_fn(update_window_title, 100)
                        print("Selected new root directory: " .. root_path)

                        -- If tree is already visible, just reload it
                        if api.tree.is_visible() then
                            vim.defer_fn(function()
                                api.tree.reload()
                                local tree_win = api.tree.winid()
                                if tree_win and vim.api.nvim_win_is_valid(tree_win) then
                                    vim.api.nvim_win_set_cursor(tree_win, {1, 0})
                                end
                            end, 50)
                        end
                        -- Don't open tree if not visible to avoid tab creation
                    else
                        -- Normal behavior for non-dashboard buffers
                        api.tree.change_root(root_path)
                        vim.defer_fn(update_window_title, 100)
                        print("Selected new root directory: " .. root_path)

                        if not api.tree.is_visible() then
                            api.tree.open({
                                current_window = false,
                                find_file = false,
                                update_root = false,
                            })
                        end

                        vim.defer_fn(function()
                            api.tree.reload()
                            local tree_win = api.tree.winid()
                            if tree_win and vim.api.nvim_win_is_valid(tree_win) then
                                vim.api.nvim_win_set_cursor(tree_win, {1, 0})
                            end
                        end, 50)
                    end
                end)
            end, keymap_opts)

            -- Remove entry with 'd'
            vim.keymap.set("n", "d", function()
                local line_nr = vim.fn.line(".")
                local root_path = line_to_path[line_nr]

                if root_path then
                    local history = load_history()
                    for i = #history, 1, -1 do
                        if history[i].path == root_path then
                            table.remove(history, i)
                            break
                        end
                    end
                    save_history(history)
                    refresh_window()
                end
            end, keymap_opts)

            -- Clear all history with 'c'
            vim.keymap.set("n", "C", function()
                vim.ui.input({prompt = "Clear all history? (y/N): "}, function(input)
                    if input and input:lower() == "y" then
                        save_history({})
                        close_window()
                        print("Root directories history cleared.")
                    end
                end)
            end, keymap_opts)

            -- Close window
            vim.keymap.set("n", "q", close_window, keymap_opts)
            vim.keymap.set("n", "<Esc>", close_window, keymap_opts)

            -- Navigation
            vim.keymap.set("n", "j", function()
                local current_line = vim.fn.line(".")
                local next_line = current_line + 1

                while next_line <= #lines and not line_to_path[next_line] do
                    next_line = next_line + 1
                end

                if line_to_path[next_line] then
                    vim.api.nvim_win_set_cursor(win, {next_line, 0})
                end
            end, keymap_opts)

            vim.keymap.set("n", "k", function()
                local current_line = vim.fn.line(".")
                local prev_line = current_line - 1

                while prev_line >= 1 and not line_to_path[prev_line] do
                    prev_line = prev_line - 1
                end

                if line_to_path[prev_line] then
                    vim.api.nvim_win_set_cursor(win, {prev_line, 0})
                end
            end, keymap_opts)

            -- Auto-close on focus lost
            vim.api.nvim_create_autocmd("WinLeave", {
                buffer = buf,
                once = true,
                callback = function()
                    vim.defer_fn(close_window, 100)
                end
            })

            -- Position cursor on first entry
            for line_nr, _ in pairs(line_to_path) do
                vim.api.nvim_win_set_cursor(win, {line_nr, 0})
                break
            end
        end

        -- Function to get current file path for sync.
        local function get_current_file()
            local current_buf = vim.api.nvim_get_current_buf()
            local file_path = vim.fn.bufname(current_buf)

            -- Return empty string for special buffers
            if
                file_path == "" or file_path:match("NvimTree_") or
                file_path:match("toggleterm") or file_path:match("dashboard")
             then
                return ""
            end

            return vim.fn.fnamemodify(file_path, ":p")
        end

        -- Function to open nvim-tree as modal window with sync.
        local function open_tree_modal()
            local api = require("nvim-tree.api")

            -- Close existing tree if open.
            if api.tree.is_visible() then
                api.tree.close()
            end

            -- Open tree in modal mode.
            api.tree.open(
                {
                    current_window = false,
                    find_file = false,
                    update_root = false
                }
            )

            -- Get current file for sync.
            local current_file = get_current_file()

            -- Schedule sync after tree opens.
            vim.schedule(
                function()
                    if current_file ~= "" then
                        api.tree.find_file(current_file)
                    end
                end
            )
        end

        require("nvim-tree").setup(
            {
                sync_root_with_cwd = true,
                update_focused_file = {
                    enable = true,
                    update_root = false, -- don't auto-update root
                    ignore_list = {}
                },
                view = {
                    width = 80,
                    float = {
                        enable = true,
                        quit_on_focus_loss = true,
                        open_win_config = function()
                            local width = math.min(80, math.floor(vim.o.columns * 0.8))
                            local height = math.min(30, math.floor(vim.o.lines * 0.8))
                            local row = math.floor((vim.o.lines - height) / 2)
                            local col = math.floor((vim.o.columns - width) / 2)

                            return {
                                relative = "editor",
                                border = "rounded",
                                width = width,
                                height = height,
                                row = row,
                                col = col,
                                title = " File Explorer ",
                                title_pos = "center"
                            }
                        end
                    }
                },
                actions = {
                    open_file = {
                        quit_on_open = true, -- close tree after opening file
                        window_picker = {
                            enable = false -- always open in new tab
                        }
                    },
                    change_dir = {
                        enable = true,
                        global = false,
                        restrict_above_cwd = false
                    }
                },
                git = {
                    enable = false -- disable git integration for simplicity
                },
                diagnostics = {
                    enable = false -- disable LSP diagnostics
                },
                modified = {
                    enable = false -- disable modified indicators
                },
                filters = {
                    git_ignored = false,
                    dotfiles = true,
                    git_clean = false,
                    no_buffer = false,
                    custom = {".DS_Store"},
                    exclude = {".env", ".gitignore", ".gitkeep"}
                },
                renderer = {
                    add_trailing = false,
                    group_empty = false,
                    highlight_git = false,
                    full_name = false,
                    highlight_opened_files = "all",
                    highlight_modified = "none",
                    root_folder_label = function(path)
                        return vim.fn.fnamemodify(path, ":~")
                    end,
                    indent_width = 2,
                    indent_markers = {
                        enable = true,
                        inline_arrows = true,
                        icons = {
                            corner = "└",
                            edge = "│",
                            item = "│",
                            bottom = "─",
                            none = " "
                        }
                    },
                    icons = {
                        webdev_colors = true,
                        git_placement = "before",
                        modified_placement = "after",
                        padding = " ",
                        symlink_arrow = " ➛ ",
                        show = {
                            file = true,
                            folder = true,
                            folder_arrow = true,
                            git = false,
                            modified = false,
                            diagnostics = false,
                            bookmarks = false
                        },
                        glyphs = {
                            default = "",
                            symlink = "",
                            bookmark = "",
                            modified = "*",
                            folder = {
                                arrow_closed = "", -- ►
                                arrow_open = "", -- ▼
                                default = "", -- closed folder
                                open = "", -- open folder
                                empty = "", -- "🗀",  -- empty closed
                                empty_open = "", -- "🗁",  -- empty open
                                symlink = "", -- symlink folder
                                symlink_open = "" -- symlink open
                            },
                            git = {
                                unstaged = "✗",
                                staged = "✓",
                                unmerged = "",
                                renamed = "➜",
                                untracked = "★",
                                deleted = "",
                                ignored = "◌"
                            }
                        }
                    },
                    special_files = {"Cargo.toml", "Makefile", "README.md", "readme.md"}
                },
                on_attach = function(bufnr)
                    local api = require("nvim-tree.api")

                    -- Clear default mappings.
                    api.config.mappings.default_on_attach(bufnr)

                    -- Enter -> expand folder or open file in new tab.
                    vim.keymap.set(
                        "n",
                        "<CR>",
                        function()
                            local node = api.tree.get_node_under_cursor()
                            if not node then
                                return
                            end

                            if node.type == "directory" then
                                -- Expand/collapse folder.
                                api.node.open.edit()
                            elseif node.type == "file" then
                                local file_path = node.absolute_path
                                local found = false
                                local replace_current = false

                                -- Check if file is already open in any tab.
                                for tab_nr = 1, vim.fn.tabpagenr("$") do
                                    local buflist = vim.fn.tabpagebuflist(tab_nr)
                                    for _, buf_nr in ipairs(buflist) do
                                        if vim.fn.bufname(buf_nr) == file_path then
                                            api.tree.close()
                                            vim.cmd(tab_nr .. "tabnext")
                                            found = true
                                            break
                                        end
                                    end
                                    if found then
                                        break
                                    end
                                end

                                if not found then
                                    api.tree.close()

                                    -- Check if current tab is dashboard or empty.
                                    local curbuf = vim.api.nvim_get_current_buf()
                                    if
                                        vim.bo[curbuf].filetype == "dashboard" or
                                            (vim.fn.bufname(curbuf) == "" and not vim.bo[curbuf].modified)
                                     then
                                        replace_current = true
                                    end

                                    if replace_current then
                                        -- Replace current tab with the file.
                                        vim.cmd("edit " .. vim.fn.fnameescape(file_path))
                                    else
                                        -- Open in new tab.
                                        vim.cmd("tabnew " .. vim.fn.fnameescape(file_path))
                                    end
                                end
                            end
                        end,
                        {
                            buffer = bufnr,
                            desc = "Expand folder or open file in new tab"
                        }
                    )

                    -- Close tree with Escape or q
                    vim.keymap.set("n", "<Esc>", api.tree.close, {buffer = bufnr, desc = "Close tree"})
                    vim.keymap.set("n", "q", api.tree.close, {buffer = bufnr, desc = "Close tree"})

                    -- Root directory management with history integration.
                    vim.keymap.set(
                        "n",
                        "C",
                        function()
                            local node = api.tree.get_node_under_cursor()
                            if not node then
                                return
                            end

                            local new_root
                            if node.type == "directory" then
                                new_root = node.absolute_path
                                api.tree.change_root(new_root)
                                vim.defer_fn(update_window_title, 100)
                                print("Root changed to: " .. vim.fn.fnamemodify(new_root, ":~"))
                            else
                                -- If it's a file, change to its directory.
                                new_root = vim.fn.fnamemodify(node.absolute_path, ":h")
                                api.tree.change_root(new_root)
                                vim.defer_fn(update_window_title, 100)
                                print("Root changed to: " .. vim.fn.fnamemodify(new_root, ":~"))
                            end

                            -- Add to history.
                            _G.NvimTreeHistory.add_root(new_root)

                            -- Refresh and position at top.
                            vim.defer_fn(function()
                                api.tree.reload()
                                local win = api.tree.winid()
                                if win and vim.api.nvim_win_is_valid(win) then
                                    vim.api.nvim_win_set_cursor(win, {1, 0})
                                    vim.cmd("normal! gg")
                                    vim.cmd("normal! j")
                                end
                            end, 100)
                        end,
                        {
                            buffer = bufnr,
                            desc = "Change root to selected directory"
                        }
                    )

                    vim.keymap.set("n", "B", function()
                        local cwd = vim.fn.getcwd()
                        api.tree.change_root(cwd)
                        vim.defer_fn(update_window_title, 100)
                        print("Root changed to: " .. cwd)

                        -- Add to history.
                        _G.NvimTreeHistory.add_root(cwd)

                        -- Refresh and position at top.
                        vim.defer_fn(function()
                            api.tree.reload()
                            local win = api.tree.winid()
                            if win and vim.api.nvim_win_is_valid(win) then
                                vim.api.nvim_win_set_cursor(win, {1, 0})
                                vim.cmd("normal! gg")
                                vim.cmd("normal! j")
                            end
                        end, 100)
                    end, {buffer = bufnr, desc = "Change root to CWD"})

                    vim.keymap.set("n", "R", function()
                        vim.ui.input(
                            {
                                prompt = "New root directory: ",
                                default = vim.fn.getcwd(),
                                completion = "dir"
                            },
                            function(input)
                                if input and vim.fn.isdirectory(input) == 1 then
                                    local full_path = vim.fn.fnamemodify(input, ":p")
                                    api.tree.change_root(full_path)
                                    vim.defer_fn(update_window_title, 100)
                                    print("Root changed to: " .. full_path)

                                    -- Add to history
                                    _G.NvimTreeHistory.add_root(full_path)

                                    -- Refresh and position at top
                                    vim.defer_fn(function()
                                        api.tree.reload()
                                        local win = api.tree.winid()
                                        if win and vim.api.nvim_win_is_valid(win) then
                                            vim.api.nvim_win_set_cursor(win, {1, 0})
                                            vim.cmd("normal! gg")
                                            vim.cmd("normal! j")
                                        end
                                    end, 100)
                                elseif input then
                                    print("Directory does not exist: " .. input)
                                end
                            end
                        )
                    end, {buffer = bufnr, desc = "Pick root directory"})

                    vim.keymap.set("n", "P", function()
                        local current_root = vim.fn.getcwd()
                        local parent_path = vim.fn.fnamemodify(current_root, ":h")

                        api.tree.change_root_to_parent()

                        -- Add to history
                        _G.NvimTreeHistory.add_root(parent_path)

                        -- Refresh and position at top
                        vim.defer_fn(function()
                            api.tree.reload()
                            local win = api.tree.winid()
                            if win and vim.api.nvim_win_is_valid(win) then
                                vim.api.nvim_win_set_cursor(win, {1, 0})
                                vim.cmd("normal! gg")
                                vim.cmd("normal! j")
                            end
                        end, 100)
                    end, {buffer = bufnr, desc = "Parent directory"})

                    -- Show project history (removed from here - use <leader>eh instead)
                    -- vim.keymap.set("n", "H", function()
                    --     _G.NvimTreeHistory.show_history()
                    -- end, {buffer = bufnr, desc = "Show project history"})

                    -- Refresh tree
                    vim.keymap.set("n", "r", api.tree.reload, {buffer = bufnr, desc = "Refresh"})

                    -- Create file/directory.
                    vim.keymap.set("n", "a", api.fs.create, {buffer = bufnr, desc = "Create file/directory"})

                    -- Delete file/directory.
                    vim.keymap.set("n", "d", api.fs.remove, {buffer = bufnr, desc = "Delete"})

                    -- Rename file/directory.
                    vim.keymap.set("n", "rn", api.fs.rename, {buffer = bufnr, desc = "Rename"})

                    -- Copy file/directory.
                    vim.keymap.set("n", "c", api.fs.copy.node, {buffer = bufnr, desc = "Copy"})

                    -- Cut file/directory.
                    vim.keymap.set("n", "x", api.fs.cut, {buffer = bufnr, desc = "Cut"})

                    -- Paste file/directory.
                    vim.keymap.set("n", "p", api.fs.paste, {buffer = bufnr, desc = "Paste"})

                    -- Toggle hidden files.
                    vim.keymap.set(
                        "n",
                        "H",
                        api.tree.toggle_hidden_filter,
                        {buffer = bufnr, desc = "Toggle hidden files"}
                    )

                    -- Filter files (live filter)
                    vim.keymap.set("n", "f", api.live_filter.start, {buffer = bufnr, desc = "Filter files"})
                    vim.keymap.set("n", "F", api.live_filter.clear, {buffer = bufnr, desc = "Clear filter"})
                end
            }
        )

        -- Global function for modal tree access.
        _G.NvimTreeModal = open_tree_modal

        -- Hook into nvim-tree root changes.
        vim.api.nvim_create_autocmd("User", {
            pattern = "NvimTreeRootChanged",
            callback = function(event)
                if event.data and event.data.new_root then
                    _G.NvimTreeHistory.add_root(event.data.new_root)
                end
            end
        })

        -- Auto-update title when root changes.
        vim.api.nvim_create_autocmd({"DirChanged", "VimEnter"}, {
            callback = update_window_title
        })

        -- User commands.
        vim.api.nvim_create_user_command("NvimTreeModal",
            open_tree_modal,
            {desc = "Open NvimTree as modal window"})

        vim.api.nvim_create_user_command("NvimTreeRootHistory",
            _G.NvimTreeHistory.show_history,
            {desc = "Show nvim-tree root directories history"})

        vim.api.nvim_create_user_command("NvimTreeClearHistory",
            function()
                save_history({})
                print("Root directories history cleared")
            end,
            {desc = "Clear nvim-tree root directories history"})
    end
}