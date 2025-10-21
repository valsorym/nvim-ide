-- ~/.config/nvim/lua/config/tabs-list.lua
-- Independent tabs list window.

local M = {}

-- Store current window
M.current_win = nil

-- Function to close any existing tabs window
function M.close_existing_window()
    if M.current_win and vim.api.nvim_win_is_valid(M.current_win) then
        pcall(vim.api.nvim_win_close, M.current_win, true)
    end
    M.current_win = nil
end

-- Function to get list of open tabs with their files
function M.get_open_tabs()
    local tabs = {}
    for tab_nr = 1, vim.fn.tabpagenr("$") do
        local buflist = vim.fn.tabpagebuflist(tab_nr)
        local winnr = vim.fn.tabpagewinnr(tab_nr)
        local buf = buflist[winnr]

        -- Find first normal buffer
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
        local dir_name = vim.fn.fnamemodify(file_path, ":h:t")

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

-- Function to create floating window with tabs list
function M.show_tabs_window()
    M.close_existing_window()

    local tabs = M.get_open_tabs()

    if #tabs == 0 then
        print("No tabs open")
        return
    end

    local buf = vim.api.nvim_create_buf(false, true)
    local width = math.min(60, vim.o.columns - 10)
    local height = math.min(15, #tabs + 7)
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

    local lines = {}
    local line_to_tab = {}
    local current_tab_line = nil

    table.insert(lines, "")
    table.insert(lines, string.format(
        " 󰮰  Number of open tabs: %d", #tabs))
    table.insert(lines, string.rep("─", width))
    table.insert(lines, "")

    for i, tab in ipairs(tabs) do
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

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.wo[win].cursorline = true

    local function close_window()
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
        M.current_win = nil
    end

    local km = {buffer = buf, nowait = true, silent = true}

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
        while next_line <= #lines and not line_to_tab[next_line] do
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

    vim.api.nvim_create_autocmd("WinLeave", {
        buffer = buf,
        once = true,
        callback = function()
            vim.defer_fn(close_window, 100)
        end
    })

    local start_line = current_tab_line or 5
    if start_line <= #lines then
        vim.api.nvim_win_set_cursor(win, {start_line, 0})
    end
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