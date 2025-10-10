-- ~/.config/nvim/lua/plugins/nvim-tree.lua
-- Modal file explorer with cached project history and safe tab logic.

return {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        "nvim-lua/plenary.nvim",
    },
    config = function()
        -- Disable netrw (conflicts with nvim-tree).
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1

        -- STATE / UTILS

        local api_ok, api = pcall(require, "nvim-tree.api")
        if not api_ok then
            vim.notify("nvim-tree.api not found", vim.log.levels.ERROR)
            return
        end

        local state = {
            history = nil,
            history_path = vim.fn.stdpath("data") ..
                "/.last_projects.json",
            max_history = 20,
        }

        local function stat_isdir(path)
            return vim.fn.isdirectory(path) == 1
        end

        local function normalize(path)
            return vim.fn.fnamemodify(path, ":p")
        end

        local function read_file(path)
            local f = io.open(path, "r")
            if not f then return nil end
            local s = f:read("*a")
            f:close()
            return s
        end

        local function write_file(path, s)
            local f = io.open(path, "w")
            if not f then return false end
            f:write(s)
            f:close()
            return true
        end

        local function load_history()
            if state.history then return state.history end
            local ok, decoded
            local raw = read_file(state.history_path)
            if raw and raw ~= "" then
                ok, decoded = pcall(vim.json.decode, raw)
            end
            state.history = (ok and type(decoded) == "table")
                and decoded
                or {}
            return state.history
        end

        local function save_history()
            if not state.history then return end
            write_file(state.history_path,
                vim.json.encode(state.history))
        end

        local function remove_from_history(path)
            local hist = load_history()
            local npath = normalize(path)
            for i = #hist, 1, -1 do
                if normalize(hist[i].path) == npath then
                    table.remove(hist, i)
                end
            end
        end

        local function push_history(path)
            if not path or path == "" then return end
            if not stat_isdir(path) then return end
            local hist = load_history()
            remove_from_history(path)
            table.insert(hist, 1, {
                path = normalize(path),
                name = vim.fn.fnamemodify(path, ":t"),
                parent = vim.fn.fnamemodify(path, ":h:t"),
                ts = os.time(),
            })
            while #hist > state.max_history do
                table.remove(hist)
            end
            save_history()
        end

        _G.NvimTreeHistory = {
            add_root = push_history,
        }

        local function update_title()
            vim.o.title = true
            local cwd = vim.fn.getcwd()
            local name = vim.fn.fnamemodify(cwd, ":t")
            vim.o.titlestring = name
        end

        local function strwidth(s)
            return vim.fn.strdisplaywidth(s)
        end

        local function strshort(s, maxw)
            if strwidth(s) <= maxw then return s end
            local ell = "…"
            local keep = math.max(1, maxw - strwidth(ell))
            -- keep tail; simple byte trim is ok for paths.
            return ell .. s:sub(#s - keep + 1)
        end

        local function on_dashboard()
            local cur = vim.api.nvim_get_current_buf()
            if vim.bo[cur].filetype == "dashboard" then
                return true
            end
            if vim.fn.bufname(cur) == "" and not vim.bo[cur].modified then
                return true
            end
            return false
        end

        local function find_tab_for_file(path)
            local npath = normalize(path)
            for t = 1, vim.fn.tabpagenr("$") do
                local bufs = vim.fn.tabpagebuflist(t)
                for _, b in ipairs(bufs) do
                    if normalize(vim.fn.bufname(b)) == npath then
                        return t
                    end
                end
            end
            return nil
        end

        local function recenter_tree_top()
            vim.defer_fn(function()
                local win = api.tree.winid()
                if win and vim.api.nvim_win_is_valid(win) then
                    vim.api.nvim_win_set_cursor(win, {1, 0})
                    vim.cmd.normal({args = {"gg"}, bang = true})
                    vim.cmd.normal({args = {"j"}, bang = true})
                end
            end, 60)
        end

        local function get_current_file()
            local p = vim.fn.expand("%:p")
            if p == "" then return "" end
            if p:match("NvimTree_") then return "" end
            if p:match("toggleterm") then return "" end
            if vim.bo.filetype == "dashboard" then return "" end
            return normalize(p)
        end

        local function open_tree_modal()
            if api.tree.is_visible() then
                api.tree.close()
            end
            api.tree.open({
                current_window = false,
                find_file = false,
                update_root = false,
            })
            local cur = get_current_file()
            vim.schedule(function()
                if cur ~= "" then api.tree.find_file(cur) end
            end)
        end

        -- HISTORY WINDOW

        function _G.NvimTreeHistory.show_history()
            local hist = load_history()
            if #hist == 0 then
                print("No root directories in history")
                return
            end

            local buf = vim.api.nvim_create_buf(false, true)
            local maxw = math.min(80, vim.o.columns - 10)
            local h = math.min(15, #hist + 5)
            local row = math.floor((vim.o.lines - h) / 2)
            local col = math.floor((vim.o.columns - maxw) / 2)

            local win = vim.api.nvim_open_win(buf, true, {
                relative = "editor",
                width = maxw,
                height = h,
                row = row,
                col = col,
                style = "minimal",
                border = "rounded",
                title = " Root Directories History ",
                title_pos = "center",
                zindex = 1000,
            })

            local lines, idx = {}, {}
            table.insert(lines, "")
            table.insert(lines, (" 󰋚  Recent projects: %d"):format(#hist))
            table.insert(lines, string.rep("─", maxw))
            table.insert(lines, "")

            -- Calculate the width needed for timestamps
            local time_width = 18  -- "24.09.2025 14:14 " length
            local number_width = 4 -- " 99. " width

            -- Available width for paths after number and time
            local path_width = maxw - number_width - time_width - 1 -- -1 for spacing

            for i, e in ipairs(hist) do
                local t = os.date("%d.%m.%Y %H:%M ", e.ts)
                local disp = strshort(e.path, path_width)

                -- Create line with fixed-width formatting
                -- Format: " 99. path..." + spaces to fill + "24.09.2025 14:14"
                local left_part = (" %2d. %s"):format(i, disp)
                local left_width = strwidth(left_part)

                -- Calculate spaces needed to right-align timestamp
                local spaces_needed = maxw - left_width - strwidth(t)
                if spaces_needed < 1 then spaces_needed = 1 end

                local line = left_part .. string.rep(" ", spaces_needed) .. t

                table.insert(lines, line)
                idx[#lines] = e.path
            end

            vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            vim.bo[buf].modifiable = false
            vim.bo[buf].buftype = "nofile"
            vim.bo[buf].bufhidden = "wipe"
            vim.wo[win].cursorline = true

            local function close_win()
                if vim.api.nvim_win_is_valid(win) then
                    vim.api.nvim_win_close(win, true)
                end
            end

            local function refresh()
                close_win()
                _G.NvimTreeHistory.show_history()
            end

            local km = {buffer = buf, nowait = true, silent = true}

            vim.keymap.set("n", "<CR>", function()
                local l = vim.fn.line(".")
                local path = idx[l]
                if not path then return end
                if not stat_isdir(path) then
                    print("Directory not found: " .. path)
                    return
                end
                close_win()
                vim.schedule(function()
                    local rp = normalize(path)
                    vim.cmd("cd " .. vim.fn.fnameescape(rp))
                    if on_dashboard() then
                        pcall(api.tree.change_root, rp)
                        vim.defer_fn(update_title, 40)
                        print("Root: " .. rp)
                    else
                        api.tree.change_root(rp)
                        vim.defer_fn(update_title, 40)
                        print("Root: " .. rp)
                    end
                end)
            end, km)

            vim.keymap.set("n", "d", function()
                local l = vim.fn.line(".")
                local path = idx[l]
                if not path then return end
                remove_from_history(path)
                save_history()
                refresh()
            end, km)

            vim.keymap.set("n", "C", function()
                vim.ui.input({prompt = "Clear history? (y/N): "},
                    function(inp)
                        if inp and inp:lower() == "y" then
                            state.history = {}
                            save_history()
                            close_win()
                            print("History cleared")
                        end
                    end)
            end, km)

            vim.keymap.set("n", "q", close_win, km)
            vim.keymap.set("n", "<Esc>", close_win, km)

            vim.keymap.set("n", "j", function()
                local cur = vim.fn.line(".")
                local nxt = cur + 1
                while nxt <= #lines and not idx[nxt] do
                    nxt = nxt + 1
                end
                if idx[nxt] then
                    vim.api.nvim_win_set_cursor(win, {nxt, 0})
                end
            end, km)

            vim.keymap.set("n", "k", function()
                local cur = vim.fn.line(".")
                local prv = cur - 1
                while prv >= 1 and not idx[prv] do
                    prv = prv - 1
                end
                if idx[prv] then
                    vim.api.nvim_win_set_cursor(win, {prv, 0})
                end
            end, km)

            vim.api.nvim_create_autocmd("WinLeave", {
                buffer = buf,
                once = true,
                callback = function()
                    vim.defer_fn(close_win, 80)
                end,
            })

            -- Set cursor to first history entry
            for ln, _ in pairs(idx) do
                vim.api.nvim_win_set_cursor(win, {ln, 0})
                break
            end
        end

        -- NVIM-TREE SETUP

        require("nvim-tree").setup({
            sync_root_with_cwd = true,
            update_focused_file = {
                enable = true,
                update_root = false,
                ignore_list = {},
            },
            view = {
                width = 80,
                float = {
                    enable = true,
                    quit_on_focus_loss = true,
                    open_win_config = function()
                        local w = math.min(80,
                            math.floor(vim.o.columns * 0.8))
                        local h = math.min(30,
                            math.floor(vim.o.lines * 0.8))
                        local r = math.floor((vim.o.lines - h) / 2)
                        local c = math.floor((vim.o.columns - w) / 2)
                        return {
                            relative = "editor",
                            border = "rounded",
                            width = w,
                            height = h,
                            row = r,
                            col = c,
                            title = " File Explorer ",
                            title_pos = "center",
                        }
                    end,
                },
            },
            actions = {
                open_file = {
                    quit_on_open = true,
                    window_picker = { enable = false },
                },
                change_dir = {
                    enable = true,
                    global = false,
                    restrict_above_cwd = false,
                },
            },
            git = { enable = false },
            diagnostics = { enable = false },
            modified = { enable = false },
            filters = {
                git_ignored = false,
                dotfiles = true,
                git_clean = false,
                no_buffer = false,
                custom = { ".DS_Store" },
                exclude = { ".env", ".gitignore", ".gitkeep", ".dockerignore", ".project" },
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
                        none = " ",
                    },
                },
                icons = {
                    webdev_colors = true,
                    git_placement = "before",
                    modified_placement = "after",
                    padding = "  ",
                    symlink_arrow = " ➛ ",
                    show = {
                        file = true,
                        folder = true,
                        folder_arrow = true,
                        git = false,
                        modified = false,
                        diagnostics = false,
                        bookmarks = false,
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
                            ignored = "◌",
                        },
                    },
                },
                special_files = {
                    "Cargo.toml", "Makefile", "README.md", "readme.md",
                },
            },
            on_attach = function(bufnr)
                api.config.mappings.default_on_attach(bufnr)

                -- -- Enter: folder toggle / file open with tab logic.
                -- vim.keymap.set("n", "<CR>", function()
                --     local node = api.tree.get_node_under_cursor()
                --     if not node then return end
                --     if node.type == "directory" then
                --         api.node.open.edit()
                --         return
                --     end
                --     local file = normalize(node.absolute_path)
                --     local tab = find_tab_for_file(file)
                --     api.tree.close()
                --     if tab then
                --         vim.cmd(tostring(tab) .. "tabnext")
                --         return
                --     end

                --     local open_cmd = on_dashboard() and "edit" or "tabnew"
                --     local ok, err = pcall(function()
                --         vim.cmd(open_cmd .. " " .. vim.fn.fnameescape(file))
                --     end)

                --     if not ok then
                --         if err:match("E325") then
                --             vim.notify("Swap file detected. Use :e! to force open",
                --                 vim.log.levels.WARN)
                --         else
                --             vim.notify("Error opening file: " .. tostring(err),
                --                 vim.log.levels.ERROR)
                --         end
                --     end
                -- end, { buffer = bufnr, desc = "Open / toggle" })

                -- Enter: folder toggle / file open with tab logic.
                vim.keymap.set("n", "<CR>", function()
                    local node = api.tree.get_node_under_cursor()
                    if not node then return end
                    if node.type == "directory" then
                        api.node.open.edit()
                        return
                    end
                    local file = normalize(node.absolute_path)
                    local tab = find_tab_for_file(file)
                    api.tree.close()
                    if tab then
                        vim.cmd(tostring(tab) .. "tabnext")
                        return
                    end

                    -- Always open in new tab at the end
                    local total_tabs = vim.fn.tabpagenr("$")
                    local open_cmd = on_dashboard() and "edit" or "tablast | tabnew"

                    local ok, err = pcall(function()
                        vim.cmd(open_cmd .. " " .. vim.fn.fnameescape(file))
                    end)

                    if not ok then
                        if err:match("E325") then
                            vim.notify("Swap file detected. Use :e! to force open",
                                vim.log.levels.WARN)
                        else
                            vim.notify("Error opening file: " .. tostring(err),
                                vim.log.levels.ERROR)
                        end
                    end
                end, { buffer = bufnr, desc = "Open / toggle" })

                vim.keymap.set("n", "<Esc>", api.tree.close,
                    { buffer = bufnr, desc = "Close tree" })
                vim.keymap.set("n", "q", api.tree.close,
                    { buffer = bufnr, desc = "Close tree" })

                -- Change root to node (or its dir if file) + history.
                local function change_root_to(path)
                    local rp = normalize(path)
                    api.tree.change_root(rp)
                    update_title()
                    push_history(rp)
                    recenter_tree_top()
                    print("Root: " .. vim.fn.fnamemodify(rp, ":~"))
                end

                vim.keymap.set("n", "C", function()
                    local node = api.tree.get_node_under_cursor()
                    if not node then return end
                    local new_root = node.type == "directory"
                        and node.absolute_path
                        or vim.fn.fnamemodify(
                            node.absolute_path, ":h")
                    change_root_to(new_root)
                end, { buffer = bufnr, desc = "Root to node" })

                vim.keymap.set("n", "B", function()
                    change_root_to(vim.fn.getcwd())
                end, { buffer = bufnr, desc = "Root to CWD" })

                vim.keymap.set("n", "R", function()
                    vim.ui.input({
                        prompt = "New root: ",
                        default = vim.fn.getcwd(),
                        completion = "dir",
                    }, function(input)
                        if not input then return end
                        if stat_isdir(input) then
                            change_root_to(input)
                        else
                            print("No such dir: " .. input)
                        end
                    end)
                end, { buffer = bufnr, desc = "Pick root" })

                vim.keymap.set("n", "P", function()
                    local cur = vim.fn.getcwd()
                    local parent = vim.fn.fnamemodify(cur, ":h")
                    api.tree.change_root_to_parent()
                    update_title()
                    push_history(parent)
                    recenter_tree_top()
                end, { buffer = bufnr, desc = "Parent dir" })

                -- File ops / filters.
                vim.keymap.set("n", "r", api.tree.reload,
                    { buffer = bufnr, desc = "Refresh" })
                vim.keymap.set("n", "a", api.fs.create,
                    { buffer = bufnr, desc = "Create" })
                vim.keymap.set("n", "d", api.fs.remove,
                    { buffer = bufnr, desc = "Delete" })
                vim.keymap.set("n", "rn", api.fs.rename,
                    { buffer = bufnr, desc = "Rename" })
                vim.keymap.set("n", "c", api.fs.copy.node,
                    { buffer = bufnr, desc = "Copy" })
                vim.keymap.set("n", "x", api.fs.cut,
                    { buffer = bufnr, desc = "Cut" })
                vim.keymap.set("n", "p", api.fs.paste,
                    { buffer = bufnr, desc = "Paste" })
                vim.keymap.set("n", "H",
                    api.tree.toggle_hidden_filter,
                    { buffer = bufnr, desc = "Hidden files" })
                vim.keymap.set("n", "f", api.live_filter.start,
                    { buffer = bufnr, desc = "Filter" })
                vim.keymap.set("n", "F", api.live_filter.clear,
                    { buffer = bufnr, desc = "Clear filter" })
            end,
        })

        -- AUTOCMDS / COMMANDS

        local aug = vim.api.nvim_create_augroup(
            "NvimTreeEx", { clear = true }
        )

        vim.api.nvim_create_autocmd({"DirChanged", "VimEnter"}, {
            group = aug,
            callback = update_title,
        })

        vim.api.nvim_create_autocmd("User", {
            group = aug,
            pattern = "NvimTreeRootChanged",
            callback = function(ev)
                if ev.data and ev.data.new_root then
                    push_history(ev.data.new_root)
                end
            end,
        })

        vim.api.nvim_create_user_command(
            "NvimTreeModal", open_tree_modal,
            { desc = "Open tree as modal" }
        )

        vim.api.nvim_create_user_command(
            "NvimTreeRootHistory",
            _G.NvimTreeHistory.show_history,
            { desc = "Show root history" }
        )

        vim.api.nvim_create_user_command(
            "NvimTreeClearHistory",
            function()
                state.history = {}
                save_history()
                print("History cleared")
            end,
            { desc = "Clear root history" }
        )

        -- Expose modal opener globally if needed.
        _G.NvimTreeModal = open_tree_modal
    end,
}
