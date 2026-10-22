-- Literal, buffer-local search and replacement; disk contents are never rewritten.
local M = {}
local namespace = vim.api.nvim_create_namespace("BufferSearch")
local active
local remembered = { "", "" }
local limit = 2000

local function pattern(query)
    local ignore = vim.o.ignorecase and not (vim.o.smartcase and vim.fn.tolower(query) ~= query)
    return "\\V" .. (ignore and "\\c" or "\\C") .. vim.fn.escape(query, "\\")
end

function M.open(replace)
    if active then active.close(false, true) end
    local source, origin = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
    if vim.bo[source].buftype ~= "" then vim.notify("Open a file buffer first", vim.log.levels.INFO); return end
    if replace and (vim.bo[source].readonly or not vim.bo[source].modifiable) then
        vim.notify("This buffer is not writable", vim.log.levels.WARN); return
    end
    if vim.o.columns < 32 or vim.o.lines < 14 then
        vim.notify("Enlarge the terminal to show file search", vim.log.levels.WARN); return
    end
    local state = { source = source, origin = origin, replace = replace, fields = {}, windows = {},
        matches = {}, index = 0, query = "", closed = false, large = require("config.performance").is_large(source),
        view = vim.fn.winsaveview(), anchor = vim.api.nvim_win_get_cursor(origin) }
    active = state
    local group = vim.api.nvim_create_augroup("BufferSearch" .. source, { clear = true })
    local timer = vim.uv.new_timer()
    local update, render, focus, queue
    local function valid()
        if state.closed or not vim.api.nvim_buf_is_loaded(source) or not vim.api.nvim_win_is_valid(origin)
            or vim.api.nvim_win_get_buf(origin) ~= source then return false end
        for _, field in ipairs(state.fields) do
            if not vim.api.nvim_buf_is_valid(field.buf) or not vim.api.nvim_win_is_valid(field.win) then return false end
        end
        return true
    end
    local function clear_highlights()
        if vim.api.nvim_buf_is_valid(source) then vim.api.nvim_buf_clear_namespace(source, namespace, 0, -1) end
    end
    local function close(keep, return_focus)
        if state.closed then return end
        state.closed = true
        timer:stop(); timer:close()
        vim.api.nvim_del_augroup_by_id(group)
        clear_highlights()
        if not keep and vim.api.nvim_win_is_valid(origin) and vim.api.nvim_win_get_buf(origin) == source then
            vim.api.nvim_win_call(origin, function() vim.fn.winrestview(state.view) end)
        end
        vim.cmd("stopinsert")
        for i = #state.windows, 1, -1 do
            if vim.api.nvim_win_is_valid(state.windows[i]) then vim.api.nvim_win_close(state.windows[i], true) end
        end
        if return_focus and vim.api.nvim_win_is_valid(origin) then vim.api.nvim_set_current_win(origin) end
        state.lines, state.matches = nil, nil
        if active == state then active = nil end
    end
    state.close = close
    local function read_fields()
        for i, field in ipairs(state.fields) do
            local lines = vim.api.nvim_buf_get_lines(field.buf, 0, -1, false)
            if #lines ~= 1 then state.error = "Use a single line in each field (Ctrl-U clears it)"; return false end
            state.values[i] = lines[1]
        end
        state.error = nil
        remembered = { state.values[1], state.values[2] or remembered[2] }
        return true
    end
    local function geometry()
        local width = math.min(110, vim.o.columns - 6)
        local height = math.min(replace and 20 or 17, vim.o.lines - vim.o.cmdheight - 4)
        return width, height, math.max(0, math.floor((vim.o.lines - vim.o.cmdheight - height - 2) / 2)),
            math.max(0, math.floor((vim.o.columns - width - 2) / 2))
    end
    local function preview()
        clear_highlights()
        if not valid() then return end
        -- A bounded set of highlights keeps dense matches from dominating redraws.
        for i = math.max(1, state.index - 100), math.min(#state.matches, state.index + 100) do
            local match = state.matches[i]
            vim.api.nvim_buf_set_extmark(source, namespace, match.row - 1, match.first, {
                end_col = match.last, hl_group = i == state.index and "IncSearch" or "Search", priority = 150 })
        end
        local match = state.matches[state.index]
        if match then
            vim.api.nvim_win_set_cursor(origin, { match.row, match.first })
            vim.api.nvim_win_call(origin, function() vim.cmd("normal! zvzz") end)
        end
    end
    render = function()
        if state.closed or not vim.api.nvim_buf_is_valid(state.body) then return end
        local count = #state.matches
        local total = tostring(count) .. (state.truncated and "+" or "")
        local status = state.error or state.message or (state.pending and "Large file: press Enter to search")
            or (state.query == "" and "Type text to search")
            or (count == 0 and "No matches" or string.format("Match %d / %s", state.index, total))
        local lines = { "", "  Find:", "", replace and "  Replace:" or "  Literal text · Vim ignorecase / smartcase", "",
            "  " .. status .. (replace and " · Ctrl-R: one · Ctrl-A: all" or ""),
            string.rep("─", state.width) }
        local visible = math.max(1, state.height - #lines)
        local first = math.max(1, math.min(state.index - math.floor(visible / 2), count - visible + 1))
        local row_map, marks = {}, {}
        for i = first, math.min(count, first + visible - 1) do
            local match = state.matches[i]
            local line = state.lines[match.row]
            local character = vim.fn.strchars(line:sub(1, match.first))
            local start = math.max(0, character - math.floor(state.width / 3))
            local snippet = vim.fn.strcharpart(line, start, math.max(1, state.width - 18))
            local prefix = string.format("%s %d:%d  ", i == state.index and " >" or "  ", match.row, character + 1)
            lines[#lines + 1] = prefix .. snippet
            row_map[#lines] = i
            if i == state.index then marks[#marks + 1] = { #lines - 1, "PmenuSel" } end
        end
        state.row_map = row_map
        vim.bo[state.body].modifiable = true
        vim.api.nvim_buf_set_lines(state.body, 0, -1, false, lines)
        vim.bo[state.body].modified = false
        vim.bo[state.body].modifiable = false
        vim.api.nvim_buf_clear_namespace(state.body, namespace, 0, -1)
        for _, mark in ipairs(marks) do
            vim.api.nvim_buf_set_extmark(state.body, namespace, mark[1], 0, { line_hl_group = mark[2] })
        end
        local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(source), ":t")
        local title = string.format(" %s · %s · %s matches ", replace and "Replace in file" or "Find in file",
            name ~= "" and name or "[No Name]", total)
        vim.api.nvim_win_set_config(state.win, { title = title, title_pos = "center" })
    end
    update = function(force, anchor)
        if not valid() then close(true, false); return false end
        if not read_fields() then
            state.matches, state.index, state.tick, state.truncated = {}, 0, nil, false
            render(); clear_highlights(); return false
        end
        local query, tick = state.values[1], vim.api.nvim_buf_get_changedtick(source)
        if not force and query == state.query and tick == state.tick and not state.pending then return true end
        if state.tick ~= tick or not state.lines then state.lines = vim.api.nvim_buf_get_lines(source, 0, -1, false) end
        state.query, state.tick, state.pending, state.message = query, tick, false, nil
        state.matches, state.index, state.truncated = {}, 0, false
        if query ~= "" then
            state.pattern = pattern(query)
            local regex = vim.regex(state.pattern)
            for row, line in ipairs(state.lines) do
                local offset = 0
                while offset < #line do
                    local first, last = regex:match_str(line:sub(offset + 1))
                    if not first then break end
                    state.matches[#state.matches + 1] = { row = row, first = offset + first, last = offset + last }
                    offset = offset + last
                    if #state.matches >= limit then state.truncated = true; break end
                end
                if state.truncated then break end
            end
        end
        local position = anchor or state.anchor
        for i, match in ipairs(state.matches) do
            if match.row > position[1] or (match.row == position[1] and match.first >= position[2]) then state.index = i; break end
        end
        if state.index == 0 and #state.matches > 0 then state.index = 1 end
        preview(); render()
        return true
    end
    queue = function()
        timer:stop()
        state.message = nil
        if state.large then state.pending = true; render(); return end
        timer:start(150, 0, vim.schedule_wrap(function() if not state.closed then update(false) end end))
    end
    local function step(direction)
        if not update(false) or #state.matches == 0 then return end
        state.index = (state.index - 1 + direction) % #state.matches + 1
        state.message = nil
        preview(); render()
    end
    local function remember_search()
        vim.fn.setreg("/", state.pattern)
        vim.fn.histadd("search", state.pattern)
        vim.v.searchforward = 1
        vim.v.hlsearch = 1
    end
    local function accept()
        if not update(false) or not state.matches[state.index] then return end
        local row = state.row_map[vim.api.nvim_win_get_cursor(state.win)[1]]
        if vim.api.nvim_get_current_win() == state.win and row then state.index = row; preview() end
        remember_search(); close(true, true)
    end
    local function replace_matches(all)
        if not replace or not update(false) or state.query == "" then return end
        if vim.bo[source].readonly or not vim.bo[source].modifiable then
            state.message = "This buffer is not writable"; render(); return
        end
        local match = state.matches[state.index]
        if not match then return end
        local replacement = state.values[2]
        local changes = {}
        if all then
            -- substitute() receives data, not an Ex command. Escape replacement metacharacters.
            local literal = replacement:gsub("[\\&~]", "\\%0")
            for row, line in ipairs(state.lines) do
                local result = vim.fn.substitute(line, state.pattern, literal, "g")
                if result ~= line then changes[#changes + 1] = { row = row, text = result } end
            end
        end
        local anchor = { match.row, match.first + #replacement }
        vim.api.nvim_buf_call(source, function()
            if all then
                for i = #changes, 1, -1 do
                    if i < #changes then vim.cmd("undojoin") end
                    vim.api.nvim_buf_set_lines(source, changes[i].row - 1, changes[i].row, false, { changes[i].text })
                end
            else
                vim.api.nvim_buf_set_text(source, match.row - 1, match.first, match.row - 1, match.last, { replacement })
            end
        end)
        remember_search()
        state.anchor = anchor
        update(true, anchor)
        state.message = all and ("Replaced matches on " .. #changes .. " lines · undo with u after closing")
            or "Replaced one match · undo with u after closing"
        render()
    end
    local function enter(field)
        if not update(false) then return end
        if replace and field == 1 then focus(2)
        elseif replace and field == 2 then replace_matches(false)
        else accept() end
    end
    local function scratch()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.bo[buf].bufhidden = "wipe"
        vim.bo[buf].swapfile = false
        vim.bo[buf].undofile = false
        vim.bo[buf].filetype = "nvim_ide_search"
        return buf
    end
    local width, height, row, col = geometry()
    state.width, state.height, state.values = width, height, { remembered[1], remembered[2] }
    state.body = scratch()
    state.win = vim.api.nvim_open_win(state.body, false, { relative = "editor", width = width, height = height,
        row = row, col = col, style = "minimal", border = "rounded", zindex = 80,
        title = replace and " Replace in file " or " Find in file ", title_pos = "center",
        footer = { { replace and " Enter Replace · Ctrl-A All · Tab Fields · Esc Close "
            or " Enter Jump · Ctrl-N/P Match · Tab Results · Esc Close ", "FooterKey" } }, footer_pos = "center" })
    state.windows[1] = state.win
    vim.wo[state.win].signcolumn = "no"
    vim.wo[state.win].wrap = false
    for i = 1, replace and 2 or 1 do
        local buf = scratch()
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { state.values[i] })
        local win = vim.api.nvim_open_win(buf, false, { relative = "win", win = state.win, width = width - 14,
            height = 1, row = i == 1 and 1 or 3, col = 12, style = "minimal", border = "none", zindex = 81 })
        vim.wo[win].signcolumn = "no"
        vim.wo[win].wrap = false
        vim.wo[win].cursorline = true
        state.fields[i] = { buf = buf, win = win }
        state.windows[#state.windows + 1] = win
        vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, { group = group, buffer = buf, callback = queue })
    end
    focus = function(index)
        vim.cmd("stopinsert")
        if index > #state.fields then
            vim.api.nvim_set_current_win(state.win)
        else
            local field = state.fields[index]
            vim.api.nvim_set_current_win(field.win)
            local line = vim.api.nvim_buf_get_lines(field.buf, 0, 1, false)[1]
            vim.api.nvim_win_set_cursor(field.win, { 1, #line })
            -- Finish the Insert-mode mapping's pending stopinsert before starting the new field.
            vim.schedule(function()
                if not state.closed and vim.api.nvim_get_current_win() == field.win then vim.cmd("startinsert!") end
            end)
        end
    end
    local function bind(buf, field)
        local function map(modes, lhs, action, description)
            vim.keymap.set(modes, lhs, action, { buffer = buf, silent = true, nowait = true, desc = description })
        end
        map({ "n", "i" }, "<Esc>", function() close(false, true) end, "Close file search")
        map({ "n", "i" }, "<C-c>", function() close(false, true) end, "Close file search")
        map({ "n", "i" }, "<CR>", function() enter(field) end, "Jump / replace current match")
        map({ "n", "i" }, "<C-n>", function() step(1) end, "Next file match")
        map({ "n", "i" }, "<C-p>", function() step(-1) end, "Previous file match")
        map({ "n", "i" }, "<Tab>", function() focus(field % (#state.fields + 1) + 1) end, "Next search field")
        map({ "n", "i" }, "<S-Tab>", function() focus((field - 2) % (#state.fields + 1) + 1) end, "Previous search field")
        if replace then
            map({ "n", "i" }, "<C-r>", function() replace_matches(false) end, "Replace current file match")
            map({ "n", "i" }, "<C-a>", function() replace_matches(true) end, "Replace all file matches")
        end
        if field <= #state.fields then
            map("i", "<C-u>", function()
                vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" }); queue()
            end, "Clear search field")
        else
            map("n", "q", function() close(false, true) end, "Close file search")
            map("n", "j", function() step(1) end, "Next file match")
            map("n", "k", function() step(-1) end, "Previous file match")
        end
    end
    for i, field in ipairs(state.fields) do bind(field.buf, i) end
    bind(state.body, #state.fields + 1)
    vim.api.nvim_create_autocmd("VimResized", { group = group, callback = function()
        if vim.o.columns < 32 or vim.o.lines < 14 then close(false, true); return end
        local w, h, r, c = geometry()
        state.width, state.height = w, h
        vim.api.nvim_win_set_config(state.win, { relative = "editor", width = w, height = h, row = r, col = c })
        for _, field in ipairs(state.fields) do vim.api.nvim_win_set_config(field.win, { width = w - 14 }) end
        render()
    end })
    vim.api.nvim_create_autocmd("WinLeave", { group = group, callback = function()
        vim.schedule(function()
            if state.closed then return end
            if not vim.tbl_contains(state.windows, vim.api.nvim_get_current_win()) then close(true, false) end
        end)
    end })
    vim.api.nvim_create_autocmd("WinClosed", { group = group, pattern = tostring(state.win), callback = function()
        vim.schedule(function() close(false, false) end)
    end })
    for _, buf in ipairs(vim.list_extend({ state.body }, vim.tbl_map(function(field) return field.buf end, state.fields))) do
        vim.api.nvim_create_autocmd("BufWipeout", { group = group, buffer = buf, callback = function()
            vim.schedule(function() close(false, true) end)
        end })
    end
    update(true)
    focus(1)
end

return M
