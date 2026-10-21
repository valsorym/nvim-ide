-- ~/.config/nvim/lua/plugins/nvim-tree.lua
-- Modal file explorer with cached project history and safe tab logic.

return {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeModal", "NvimTreeToggle", "NvimTreeOpen", "NvimTreeFocus", "NvimTreeRootHistory", "NvimTreeClearHistory" },
    init = function()
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1
        vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = function()
            local path = vim.fn.argv(0)
            if type(path) == "string" and vim.fn.isdirectory(path) == 1 then
                require("lazy").load({ plugins = { "nvim-tree.lua" } })
                require("nvim-tree.api").tree.open({ path = path })
            end
        end })
    end,
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
            -- Trim characters, not UTF-8 bytes, for Ukrainian filenames.
            local chars = vim.fn.strchars(s)
            while chars > 0 and strwidth(vim.fn.strcharpart(s, chars - 1)) <= keep do chars = chars - 1 end
            return ell .. vim.fn.strcharpart(s, chars)
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

        local function recenter_tree_top()
            vim.defer_fn(function()
                local win = api.tree.winid()
                if win and vim.api.nvim_win_is_valid(win) then
                    vim.api.nvim_win_set_cursor(win, {1, 0})

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
            local buf = vim.api.nvim_get_current_buf()
            if api.tree.is_visible() then api.tree.close(); return end
            api.tree.open({ current_window = false, find_file = false, update_root = false })
            if vim.api.nvim_buf_get_name(buf) ~= "" and vim.bo[buf].buftype == "" then
                api.tree.find_file({ buf = buf, open = true, focus = true })
            end
        end

        -- HISTORY WINDOW

        function _G.NvimTreeHistory.show_history()
            local hist = load_history()
            if #hist == 0 then
                print("No root directories in history")
                return
            end

            if vim.o.columns < 30 or vim.o.lines < 10 then
                vim.notify("Enlarge the terminal to show project history", vim.log.levels.WARN)
                return
            end
            -- Main buffer / window.
            local buf = vim.api.nvim_create_buf(false, true)
            local maxw = math.min(80, vim.o.columns - 10)
            local h = math.min(vim.o.lines - 4, #hist + 4)
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
                footer = {
                    {"─ [ ", "FloatBorder"},
                    {"/", "FooterKey"}, {" - filter", "FooterDesc"},
                    {" | ", "FloatBorder"},
                    {"d", "FooterKey"}, {" - del", "FooterDesc"},
                    {" | ", "FloatBorder"},
                    {"C", "FooterKey"}, {" - clear", "FooterDesc"},
                    {" | ", "FloatBorder"},
                    {"q", "FooterKey"}, {" - close", "FooterDesc"},
                    {" ] ─", "FloatBorder"},
                },
                footer_pos = "center",
                zindex = 1000,
            })

            -- Prompt buffer / window (overlaid on header row 3).
            local prompt_buf = vim.api.nvim_create_buf(false, true)
            local prompt_win = vim.api.nvim_open_win(prompt_buf, false, {
                relative = "win",
                win = win,
                width = maxw - 4,
                height = 1,
                row = 2,
                col = 1,
                style = "minimal",
                border = "none",
                zindex = 1001,
            })
            vim.bo[prompt_buf].buftype = "prompt"
            vim.bo[prompt_buf].bufhidden = "wipe"
            vim.fn.prompt_setprompt(prompt_buf, " 🔍 Filter: ")

            -- State.
            local filter_text = ""
            local line_to_path = {}

            local time_width = 18
            local number_width = 4
            local path_width = maxw - number_width - time_width - 1

            -- Filter history entries.
            local function filter_hist(text)
                if text == "" then return hist end
                local lower = text:lower()
                local out = {}
                for _, e in ipairs(hist) do
                    if e.path:lower():find(lower, 1, true) then
                        table.insert(out, e)
                    end
                end
                return out
            end

            -- Render list into main buffer.
            local function render()
                local filtered = filter_hist(filter_text)
                line_to_path = {}

                local lines = {}
                -- Header: empty, title, empty (prompt overlays line 3).
                table.insert(lines, "")
                table.insert(lines, (" 󰋚  Recent projects: %d/%d")
                    :format(#filtered, #hist))
                table.insert(lines, "")
                -- Separator.
                table.insert(lines, string.rep("─", maxw))

                if #filtered == 0 then
                    table.insert(lines, "")
                    table.insert(lines, "   No matching projects")
                else
                    for i, e in ipairs(filtered) do
                        local t = os.date("%d.%m.%Y %H:%M ", e.ts)
                        local disp = strshort(e.path, path_width)
                        local lp = (" %2d. %s"):format(i, disp)
                        local lw = strwidth(lp)
                        local sp = math.max(1,
                            maxw - lw - strwidth(t))
                        table.insert(lines,
                            lp .. string.rep(" ", sp) .. t)
                        line_to_path[#lines] = e.path
                    end
                end

                vim.bo[buf].modifiable = true
                vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
                vim.bo[buf].modifiable = false

                -- Highlight separator (0-indexed line 3).
                vim.api.nvim_buf_add_highlight(
                    buf, -1, "FloatBorder", 3, 0, -1)

                -- Cursor to first entry.
                local first = 5
                if line_to_path[first] and
                   vim.api.nvim_win_is_valid(win) then
                    pcall(vim.api.nvim_win_set_cursor,
                        win, {first, 0})
                end
            end

            vim.bo[buf].buftype = "nofile"
            vim.bo[buf].bufhidden = "wipe"
            vim.wo[win].cursorline = true
            vim.wo[win].scrolloff = 0

            render()

            -- Live filter on text change.
            vim.api.nvim_create_autocmd("TextChangedI", {
                buffer = prompt_buf,
                callback = function()
                    local line = vim.api.nvim_buf_get_lines(
                        prompt_buf, 0, 1, false)[1]
                    filter_text = line:gsub(
                        "^%s*🔍%s*Filter:%s*", "")
                    render()
                end,
            })

            -- Keep cursor on entry lines only.
            vim.api.nvim_create_autocmd("CursorMoved", {
                buffer = buf,
                callback = function()
                    if not vim.api.nvim_win_is_valid(win) then
                        return
                    end
                    local pos = vim.api.nvim_win_get_cursor(win)
                    if pos[1] < 5 then
                        vim.api.nvim_win_set_cursor(win, {math.min(5, vim.api.nvim_buf_line_count(buf)), 0})
                    end
                end,
            })

            local function close_win()
                if vim.api.nvim_win_is_valid(prompt_win) then
                    pcall(vim.api.nvim_win_close, prompt_win, true)
                end
                if vim.api.nvim_win_is_valid(win) then
                    vim.api.nvim_win_close(win, true)
                end
            end

            local function refresh()
                close_win()
                _G.NvimTreeHistory.show_history()
            end

            -- Navigate to next/prev entry line.
            local function go_next()
                local cur = vim.api.nvim_win_get_cursor(win)[1]
                local nxt = cur + 1
                local max = vim.api.nvim_buf_line_count(buf)
                while nxt <= max and not line_to_path[nxt] do
                    nxt = nxt + 1
                end
                if line_to_path[nxt] then
                    vim.api.nvim_win_set_cursor(win, {nxt, 0})
                end
            end

            local function go_prev()
                local cur = vim.api.nvim_win_get_cursor(win)[1]
                local prv = cur - 1
                while prv >= 1 and not line_to_path[prv] do
                    prv = prv - 1
                end
                if line_to_path[prv] then
                    vim.api.nvim_win_set_cursor(win, {prv, 0})
                end
            end

            local function select_entry()
                local l = vim.api.nvim_win_get_cursor(win)[1]
                local path = line_to_path[l]
                if not path then return end
                if not stat_isdir(path) then
                    print("Directory not found: " .. path)
                    return
                end
                close_win()
                vim.schedule(function()
                    local rp = normalize(path)
                    vim.cmd("cd " .. vim.fn.fnameescape(rp))
                    api.tree.change_root(rp)
                    vim.defer_fn(update_title, 40)
                    print("Root: " .. rp)
                end)
            end

            -- Main window keymaps.
            local km = {buffer = buf, nowait = true, silent = true}

            vim.keymap.set("n", "<CR>", select_entry, km)

            vim.keymap.set("n", "j", go_next, km)
            vim.keymap.set("n", "k", go_prev, km)

            local function enter_filter()
                vim.api.nvim_set_current_win(prompt_win)
                vim.cmd("startinsert")
            end
            vim.keymap.set("n", "/", enter_filter, km)
            vim.keymap.set("n", "i", enter_filter, km)
            vim.keymap.set("n", "<Tab>", enter_filter, km)

            vim.keymap.set("n", "d", function()
                local l = vim.fn.line(".")
                local path = line_to_path[l]
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

            -- Prompt window keymaps.
            local pkm = {
                buffer = prompt_buf, nowait = true, silent = true,
            }

            vim.keymap.set("i", "<Esc>", function()
                vim.cmd("stopinsert")
                vim.api.nvim_set_current_win(win)
            end, pkm)

            vim.keymap.set("i", "<Tab>", function()
                vim.cmd("stopinsert")
                vim.api.nvim_set_current_win(win)
            end, pkm)

            vim.keymap.set("i", "<C-c>", function()
                vim.cmd("stopinsert")
                close_win()
            end, pkm)

            vim.keymap.set("i", "<CR>", function()
                vim.cmd("stopinsert")
                vim.api.nvim_set_current_win(win)
                select_entry()
            end, pkm)

            vim.keymap.set("i", "<Down>", go_next, pkm)
            vim.keymap.set("i", "<C-n>", go_next, pkm)
            vim.keymap.set("i", "<C-j>", go_next, pkm)
            vim.keymap.set("i", "<Up>", go_prev, pkm)
            vim.keymap.set("i", "<C-p>", go_prev, pkm)
            vim.keymap.set("i", "<C-k>", go_prev, pkm)

            -- Auto-close on focus loss.
            vim.api.nvim_create_autocmd({"WinLeave", "BufLeave"}, {
                buffer = buf,
                once = true,
                callback = function()
                    vim.defer_fn(function()
                        local cur = vim.api.nvim_get_current_win()
                        if cur ~= win and cur ~= prompt_win then
                            close_win()
                        end
                    end, 100)
                end,
            })
        end

        -- NVIM-TREE SETUP

        require("nvim-tree").setup({
            sync_root_with_cwd = true,
            respect_buf_cwd = true,
            reload_on_bufenter = false,
            update_focused_file = {
                enable = true,
                update_root = false,
                ignore_list = {},
            },
            view = {
                width = 80,
                -- All sign-producing tree features are disabled; do not reserve a blank gutter.
                signcolumn = "no",
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
                        local cwd = vim.fn.fnamemodify(
                            vim.fn.getcwd(), ":~")
                        return {
                            relative = "editor",
                            border = "rounded",
                            width = w,
                            height = h,
                            row = r,
                            col = c,
                            title = {
                                {" ", "FloatBorder"},
                                {" ", "DiagnosticInfo"},
                                {" " .. cwd .. " ", "FloatTitle"},
                            },
                            title_pos = "center",
                            footer = {
                                {"─ [ ", "FloatBorder"},
                                {"n", "FooterKey"}, {" - new", "FooterDesc"},
                                {" | ", "FloatBorder"},
                                {"d", "FooterKey"}, {" - del", "FooterDesc"},
                                {" | ", "FloatBorder"},
                                {"r", "FooterKey"}, {" - ren", "FooterDesc"},
                                {" | ", "FloatBorder"},
                                {"H", "FooterKey"}, {" - dot", "FooterDesc"},
                                {" | ", "FloatBorder"},
                                {"F", "FooterKey"}, {" - filter", "FooterDesc"},
                                {" | ", "FloatBorder"},
                                {"T", "FooterKey"}, {" - fold", "FooterDesc"},
                                {" | ", "FloatBorder"},
                                {"P", "FooterKey"}, {" - up", "FooterDesc"},
                                {" ] ─", "FloatBorder"},
                            },
                            footer_pos = "center",
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

                -- Enter: folder toggle / file open with tab logic.
                vim.keymap.set("n", "<CR>", function()
                    local node = api.tree.get_node_under_cursor()
                    if not node then return end
                    if node.type == "directory" then
                        api.node.open.edit()
                        return
                    end
                    local file = normalize(node.absolute_path)
                    api.tree.close()
                    require("config.nvim-tabs").open(file)

                end, { buffer = bufnr, desc = "Open / toggle" })


                -- Change root to node (or its dir if file) + history.
                local function change_root_to(path)
                    local rp = normalize(path)
                    api.tree.change_root(rp)

                    -- Sync Neovim cwd with nvim-tree root
                    vim.cmd("cd " .. vim.fn.fnameescape(rp))

                    update_title()
                    push_history(rp)
                    recenter_tree_top()
                    print("Root: " .. vim.fn.fnamemodify(rp, ":~"))
                end

                vim.keymap.set("n", "<S-c>", function()
                    local node = api.tree.get_node_under_cursor()
                    if not node then return end
                    local new_root = node.type == "directory"
                        and node.absolute_path
                        or vim.fn.fnamemodify(
                            node.absolute_path, ":h")
                    change_root_to(new_root)
                end, { buffer = bufnr, desc = "Choose root dir" })

                vim.keymap.set("n", "<S-b>", function()
                    change_root_to(vim.fn.getcwd())
                end, { buffer = bufnr, desc = "Root to CWD" })

                vim.keymap.set("n", "gR", function()
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
                end, { buffer = bufnr, desc = "Enter root directory" })

                vim.keymap.set("n", "P", function()
                    local cur = vim.fn.getcwd()
                    local parent = vim.fn.fnamemodify(cur, ":h")
                    api.tree.change_root_to_parent()
                    update_title()
                    push_history(parent)
                    recenter_tree_top()
                end, { buffer = bufnr, desc = "Parent dir" })

                vim.keymap.set("n", "<Esc>", api.tree.close,
                    { buffer = bufnr, desc = "Close tree" })

                vim.keymap.set("n", "<S-r>", api.tree.reload,
                    { buffer = bufnr, desc = "Refresh" })
                vim.keymap.set("n", "<S-h>", api.tree.toggle_hidden_filter,
                    { buffer = bufnr, desc = "Hidden files" })
                vim.keymap.set("n", "<S-f>", api.live_filter.start,
                    { buffer = bufnr, desc = "Filter" })
                vim.keymap.set("n", "<S-x>", api.live_filter.clear,
                    { buffer = bufnr, desc = "Clear filter" })


                vim.keymap.set("n", "t", function()
                    local node = api.tree.get_node_under_cursor()
                    if not node then return end

                    local target_node

                    -- If we're on a file, get its parent directory.
                    if node.type ~= "directory" then
                        target_node = node.parent
                    else
                        target_node = node
                    end

                    if not target_node then return end

                    -- Recursive function to close all child directories.
                    local function close_all_children(dir_node)
                        if not dir_node or dir_node.type ~= "directory" then return end

                        if dir_node.nodes then
                            for _, child in ipairs(dir_node.nodes) do
                                if child.type == "directory" and child.open then
                                    close_all_children(child)
                                    api.node.open.edit(child)
                                end
                            end
                        end
                    end

                    -- Close all subdirectories first.
                    if target_node.open then
                        close_all_children(target_node)
                        -- Then close the target directory.
                        api.node.open.edit(target_node)
                        -- Move cursor to the closed directory.
                        vim.schedule(function()
                            api.tree.find_file(target_node.absolute_path)
                        end)
                    else
                        -- If closed, open it
                        api.node.open.edit(target_node)
                    end
                end, { buffer = bufnr, desc = "Toggle folder" })

                vim.keymap.set("n", "<S-t>", function()
                    -- Get current node under cursor.
                    local current_node = api.tree.get_node_under_cursor()

                    -- Find root node by going up the tree.
                    local root = current_node
                    while root and root.parent do
                        root = root.parent
                    end

                    -- If root not found via cursor, try via API.
                    if not root then
                        local nodes = api.tree.get_nodes()
                        if nodes then
                            root = nodes
                        else
                            vim.notify("nvim-tree: root not found", vim.log.levels.WARN)
                            return
                        end
                    end

                    -- Recursively close all open directories.
                    local function close_all_dirs(node)
                        if not node or not node.nodes then return end
                        for _, child in ipairs(node.nodes) do
                            if child.type == "directory" then
                                -- First close subdirectories.
                                close_all_dirs(child)
                                if child.open then
                                    api.node.open.edit(child) -- toggle off
                                end
                            end
                        end
                    end

                    close_all_dirs(root)

                    -- Move cursor to root directory.
                    vim.schedule(function()
                        local win = api.tree.winid()
                        if win and vim.api.nvim_win_is_valid(win) then
                            vim.api.nvim_win_set_cursor(win, {1, 0})
                        end
                    end)

                    vim.notify("  All folders closed", vim.log.levels.INFO, { title = "NvimTree" })
                end, { buffer = bufnr, desc = "Close all folders recursively and go root" })

                vim.keymap.set("n", "n", api.fs.create,
                    { buffer = bufnr, desc = "New object" })
                vim.keymap.set("n", "d", api.fs.remove,
                    { buffer = bufnr, desc = "Delete" })
                vim.keymap.set("n", "r", api.fs.rename,
                    { buffer = bufnr, desc = "Rename" })
                vim.keymap.set("n", "c", api.fs.copy.node,
                    { buffer = bufnr, desc = "Copy" })
                vim.keymap.set("n", "x", api.fs.cut,
                    { buffer = bufnr, desc = "Cut" })
                vim.keymap.set("n", "p", api.fs.paste,
                    { buffer = bufnr, desc = "Paste" })
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
