-- ~/.config/nvim/lua/config/tabs-list.lua
-- Independent tabs list window with search filtering.

local M = {}

-- Store current window.
M.current_win = nil

-- Function to close any existing tabs window.
function M.close_existing_window()
    if M.current_win and vim.api.nvim_win_is_valid(M.current_win) then
        pcall(vim.api.nvim_win_close, M.current_win, true)
    end
    M.current_win = nil
end

-- Function to get list of open tabs with their files.
function M.get_open_tabs()
    -- Use current working directory as root.
    local root_dir = vim.fn.getcwd()

    -- Get last N directories + filename relative to root if possible.
    local function get_short_path(full_path)
        if full_path == "" then
            return ""
        end

        local path = full_path

        -- Make path relative to cwd.
        if root_dir then
            -- Normalize both paths.
            local normalized_root = root_dir:gsub("/$", "")
            local normalized_path = path:gsub("/$", "")

            -- Check if file is under the root
            if normalized_path:sub(1, #normalized_root) == normalized_root then
                -- Make relative path
                local relative = normalized_path:sub(#normalized_root + 2)  -- +2 to skip root and "/"

                if relative ~= "" then
                    path = relative
                end
            end
        end

        -- Split path into components.
        local parts = {}
        for part in string.gmatch(path, "[^/]+") do
            table.insert(parts, part)
        end

        -- If path is now short (relative to root), show it all.
        if #parts <= 3 then
            -- Remove filename from parts.
            local dirs = {}
            for i = 1, #parts - 1 do
                table.insert(dirs, parts[i])
            end
            return table.concat(dirs, "/")
        end

        -- Otherwise, take last 3 directories.
        local start_idx = math.max(1, #parts - 3)
        local short_parts = {}
        for i = start_idx, #parts - 1 do  -- -1 to exclude filename
            table.insert(short_parts, parts[i])
        end

        return table.concat(short_parts, "/")
    end

    local tabs = {}
    for tab_nr = 1, vim.fn.tabpagenr("$") do
        local buflist = vim.fn.tabpagebuflist(tab_nr)
        local winnr = vim.fn.tabpagewinnr(tab_nr)
        local buf = buflist[winnr]

        -- Find first normal buffer.
        for _, b in ipairs(buflist) do
            local name = vim.fn.bufname(b)
            if not name:match("NvimTree_") and
               not name:match("toggleterm") and
               not name:match("dashboard") and name ~= "" then
                buf = b
                break
            end
        end

        local file_path = vim.fn.bufname(buf)
        local file_name = vim.fn.fnamemodify(file_path, ":t")
        local dir_name = get_short_path(file_path)

        if file_name == "" then
            file_name = "[No Name]"
            dir_name = ""
        end

        local is_modified = vim.bo[buf].modified
        if is_modified then
            file_name = file_name .. "*"
        end

        local is_current = (tab_nr == vim.fn.tabpagenr())

        local display_name = file_name
        if dir_name ~= "" and dir_name ~= "." then
            display_name = dir_name .. "/" .. file_name
        end

        table.insert(tabs, {
            tab_nr = tab_nr,
            file_name = file_name,
            display_name = display_name,
            file_path = file_path,
            dir_name = dir_name,
            is_current = is_current,
            is_modified = is_modified,
            buf = buf
        })
    end
    return tabs
end

-- Function to create floating window with tabs list.
function M.show_tabs_window()
    M.close_existing_window()

    local all_tabs = M.get_open_tabs()

    if #all_tabs == 0 then
        print("No tabs open")
        return
    end

    -- Create main buffer.
    local buf = vim.api.nvim_create_buf(false, true)
    local width = math.min(70, vim.o.columns - 10)
    local height = math.min(20, #all_tabs + 10)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = " Open Tabs ",
        title_pos = "center",
        zindex = 1000
    })

    M.current_win = win

    -- Create prompt buffer for search.
    local prompt_buf = vim.api.nvim_create_buf(false, true)
    local prompt_height = 1
    local prompt_win = vim.api.nvim_open_win(prompt_buf, false, {
        relative = "win",
        win = win,
        width = width - 4,
        height = prompt_height,
        row = 3,
        col = 1,
        style = "minimal",
        border = "none",
        zindex = 1001
    })

    vim.bo[prompt_buf].buftype = "prompt"
    vim.fn.prompt_setprompt(prompt_buf, " 🔍 Filter: ")

    -- State
    local filter_text = ""
    local filtered_tabs = all_tabs
    local line_to_tab = {}
    local current_tab_line = nil

    -- Function to filter tabs.
    local function filter_tabs(text)
        if text == "" then
            return all_tabs
        end

        local results = {}
        local lower_text = string.lower(text)

        for _, tab in ipairs(all_tabs) do
            local lower_display = string.lower(tab.display_name)
            if lower_display:find(lower_text, 1, true) then
                table.insert(results, tab)
            end
        end

        return results
    end

    -- Function to render tabs list.
    local function render_list()
        filtered_tabs = filter_tabs(filter_text)
        line_to_tab = {}
        current_tab_line = nil

        local lines = {}

        -- Header with tabs count.
        table.insert(lines, "")
        table.insert(lines, string.format(
            " 󰮰  Tabs: %d/%d", #filtered_tabs, #all_tabs))
        table.insert(lines, "")
        -- Prompt placeholder (will be covered by prompt window).
        table.insert(lines, "")
        -- Separator line (full width).
        table.insert(lines, string.rep("─", width))
        table.insert(lines, "")

        if #filtered_tabs == 0 then
            table.insert(lines, "   No matching tabs")
        else
            for i, tab in ipairs(filtered_tabs) do
                local prefix = tab.is_current and " ⚬ " or "   "
                local status = tab.is_modified and "" or ""
                local line = string.format("%s%d. %s%s",
                    prefix, tab.tab_nr, tab.display_name, status)
                table.insert(lines, line)

                local line_nr = #lines
                line_to_tab[line_nr] = tab.tab_nr

                if tab.is_current then
                    current_tab_line = line_nr
                end
            end
        end

        -- Make buffer modifiable before updating.
        vim.bo[buf].modifiable = true
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.bo[buf].modifiable = false

        -- Move cursor to first result or current tab
        local target_line = current_tab_line or 7
        if target_line <= #lines and vim.api.nvim_win_is_valid(win) then
            pcall(vim.api.nvim_win_set_cursor, win, {target_line, 0})
        end
    end

    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.wo[win].cursorline = true
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false

    -- Initial render.
    render_list()

    -- Prompt callback for filtering.
    vim.fn.prompt_setcallback(prompt_buf, function(text)
        filter_text = text
        render_list()
    end)

    -- Update filter on text change.
    vim.api.nvim_create_autocmd("TextChangedI", {
        buffer = prompt_buf,
        callback = function()
            local line = vim.api.nvim_buf_get_lines(
                prompt_buf, 0, 1, false)[1]
            filter_text = line:gsub("^%s*🔍%s*Filter:%s*", "")
            render_list()
        end
    })

    local function close_window()
        if vim.api.nvim_win_is_valid(prompt_win) then
            pcall(vim.api.nvim_win_close, prompt_win, true)
        end
        if vim.api.nvim_win_is_valid(win) then
            pcall(vim.api.nvim_win_close, win, true)
        end
        M.current_win = nil
    end

    -- Keymaps for main window.
    local km = {buffer = buf, nowait = true, silent = true}

    -- Enter prompt mode with 'i', '/' or Tab.
    vim.keymap.set("n", "i", function()
        vim.api.nvim_set_current_win(prompt_win)
        vim.cmd("startinsert")
    end, km)

    vim.keymap.set("n", "/", function()
        vim.api.nvim_set_current_win(prompt_win)
        vim.cmd("startinsert")
    end, km)

    vim.keymap.set("n", "<Tab>", function()
        vim.api.nvim_set_current_win(prompt_win)
        vim.cmd("startinsert")
    end, km)

    vim.keymap.set("n", "<CR>", function()
        local line_nr = vim.fn.line(".")
        local tab_nr = line_to_tab[line_nr]
        if tab_nr then
            close_window()
            vim.cmd(tab_nr .. "tabnext")
        end
    end, km)

    vim.keymap.set("n", "d", function()
        local line_nr = vim.fn.line(".")
        local tab_nr = line_to_tab[line_nr]
        if tab_nr then
            if vim.fn.tabpagenr("$") > 1 then
                close_window()
                vim.cmd(tab_nr .. "tabclose")
                vim.defer_fn(M.show_tabs_window, 200)
            else
                print("Cannot close the last tab")
            end
        end
    end, km)

    vim.keymap.set("n", "q", close_window, km)
    vim.keymap.set("n", "<Esc>", close_window, km)

    vim.keymap.set("n", "j", function()
        local current_line = vim.fn.line(".")
        local next_line = current_line + 1
        while next_line <= vim.api.nvim_buf_line_count(buf) and
              not line_to_tab[next_line] do
            next_line = next_line + 1
        end
        if line_to_tab[next_line] then
            vim.api.nvim_win_set_cursor(win, {next_line, 0})
        end
    end, km)

    vim.keymap.set("n", "k", function()
        local current_line = vim.fn.line(".")
        local prev_line = current_line - 1
        while prev_line >= 1 and not line_to_tab[prev_line] do
            prev_line = prev_line - 1
        end
        if line_to_tab[prev_line] then
            vim.api.nvim_win_set_cursor(win, {prev_line, 0})
        end
    end, km)

    -- Keymaps for prompt window.
    local prompt_km = {
        buffer = prompt_buf,
        nowait = true,
        silent = true
    }

    -- Esc - exit search, go to list.
    vim.keymap.set("i", "<Esc>", function()
        vim.cmd("stopinsert")
        vim.api.nvim_set_current_win(win)
    end, prompt_km)

    -- Tab - exit search, go to list (alternative).
    vim.keymap.set("i", "<Tab>", function()
        vim.cmd("stopinsert")
        vim.api.nvim_set_current_win(win)
    end, prompt_km)

    -- Ctrl-C - close window completely.
    vim.keymap.set("i", "<C-c>", function()
        vim.cmd("stopinsert")
        close_window()
    end, prompt_km)

    -- Enter - select current item.
    vim.keymap.set("i", "<CR>", function()
        vim.cmd("stopinsert")
        vim.api.nvim_set_current_win(win)
        local line_nr = vim.api.nvim_win_get_cursor(win)[1]
        local tab_nr = line_to_tab[line_nr]
        if tab_nr then
            close_window()
            vim.cmd(tab_nr .. "tabnext")
        end
    end, prompt_km)

    -- Arrow Down - move to next item (stay in search).
    vim.keymap.set("i", "<Down>", function()
        local current_line = vim.api.nvim_win_get_cursor(win)[1]
        local next_line = current_line + 1
        local max_lines = vim.api.nvim_buf_line_count(buf)

        while next_line <= max_lines and
              not line_to_tab[next_line] do
            next_line = next_line + 1
        end

        if line_to_tab[next_line] then
            vim.api.nvim_win_set_cursor(win, {next_line, 0})
        end
    end, prompt_km)

    vim.keymap.set("i", "<C-n>", function()
        local current_line = vim.api.nvim_win_get_cursor(win)[1]
        local next_line = current_line + 1
        local max_lines = vim.api.nvim_buf_line_count(buf)

        while next_line <= max_lines and
              not line_to_tab[next_line] do
            next_line = next_line + 1
        end

        if line_to_tab[next_line] then
            vim.api.nvim_win_set_cursor(win, {next_line, 0})
        end
    end, prompt_km)

    -- Arrow Up - move to previous item (stay in search).
    vim.keymap.set("i", "<Up>", function()
        local current_line = vim.api.nvim_win_get_cursor(win)[1]
        local prev_line = current_line - 1

        while prev_line >= 1 and not line_to_tab[prev_line] do
            prev_line = prev_line - 1
        end

        if line_to_tab[prev_line] then
            vim.api.nvim_win_set_cursor(win, {prev_line, 0})
        end
    end, prompt_km)

    vim.keymap.set("i", "<C-p>", function()
        local current_line = vim.api.nvim_win_get_cursor(win)[1]
        local prev_line = current_line - 1

        while prev_line >= 1 and not line_to_tab[prev_line] do
            prev_line = prev_line - 1
        end

        if line_to_tab[prev_line] then
            vim.api.nvim_win_set_cursor(win, {prev_line, 0})
        end
    end, prompt_km)

    -- Auto-close when main window loses focus.
    vim.api.nvim_create_autocmd({"WinLeave", "BufLeave"}, {
        buffer = buf,
        once = true,
        callback = function()
            vim.defer_fn(function()
                local current = vim.api.nvim_get_current_win()
                if current ~= win and current ~= prompt_win then
                    close_window()
                end
            end, 100)
        end
    })

    -- Start in prompt mode.
    vim.api.nvim_set_current_win(prompt_win)
    vim.cmd("startinsert")
end

function M.setup()
    _G.TabsList = M

    vim.api.nvim_create_user_command(
        "TabsList",
        M.show_tabs_window,
        {desc = "Show list of open tabs"}
    )

    vim.keymap.set("n", "<leader>et", M.show_tabs_window,
        {desc = "Show tabs list", silent = true})
end

return M