-- A read-only reference, built on demand without loading the actions it describes.
local M = {}
local namespace = vim.api.nvim_create_namespace("KeymapHelp")
local current

local labels = {
    en = {
        title = "Neovim IDE · Keyboard reference",
        controls = "/ Filter  c Clear  e English  u Українська  [[ / ]] Sections  q Close",
        intro = "<leader> = Space · Keys are sequential; uppercase needs Shift · Enter never runs an action.",
        modes = "n Normal · x Visual · o Operator-pending · i Insert · s Select · t Terminal",
        scope = "All configured global keys, local menu keys and native essentials; :help index has the full native index.",
        layout = "Ukrainian keyboard: %s · This changes key positions, not the language of descriptions.",
        filter = "Filter (both languages)", matches = "Matches", empty = "No matching keys. Press c to clear the filter.",
        general = "General / function keys / navigation",
        columns = "Key                             Mode     Description",
    },
    uk = {
        title = "Neovim IDE · Довідка з клавіш",
        controls = "/ Фільтр  c Очистити  e English  u Українська  [[ / ]] Розділи  q Закрити",
        intro = "<leader> = Пробіл · Клавіші натискаються послідовно; великі літери — із Shift · Enter не виконує дій.",
        modes = "n Звичайний · x Виділення · o Очікування оператора · i Вставлення · s Вибір · t Термінал",
        scope = "Усі налаштовані глобальні клавіші, клавіші локальних меню й основні вбудовані; повний перелік: :help index.",
        layout = "Українська клавіатура: %s · Це розташування клавіш, а не мова описів.",
        filter = "Фільтр (обидві мови)", matches = "Знайдено", empty = "Збігів немає. Натисни c, щоб очистити фільтр.",
        general = "Загальні / функціональні клавіші / навігація",
        columns = "Клавіші                         Режим    Опис",
    },
}

local function sections()
    local registry = require("config.keymaps")
    local result = { { en = labels.en.general, uk = labels.uk.general, entries = {} } }
    local groups = vim.tbl_keys(registry.groups)
    table.sort(groups)
    local by_group = {}
    for _, key in ipairs(groups) do
        local section = { en = "<leader>" .. key .. " · " .. registry.groups[key],
            uk = "<leader>" .. key .. " · " .. registry.groups_uk[key], entries = {} }
        result[#result + 1], by_group[key] = section, section
    end
    for _, entry in ipairs(registry.entries) do
        local key = entry[1]:match("^<leader>([a-z])")
        local section = by_group[key] or result[1]
        local mode = type(entry[4]) == "table" and table.concat(entry[4], "/") or entry[4] or "n"
        section.entries[#section.entries + 1] = { entry[1], mode, entry[3], entry.uk or entry[3] }
    end
    for _, section in ipairs(require("config.keymap-reference")) do result[#result + 1] = section end
    return result
end

local function lower(text) return vim.fn.tolower(text) end

local function render(state)
    if not vim.api.nvim_buf_is_valid(state.buf) then return end
    local text = labels[state.language]
    local lines, highlights, headings = {}, {}, {}
    local function append(line, group)
        lines[#lines + 1] = line
        if group then highlights[#highlights + 1] = { #lines - 1, 0, #line, group } end
    end
    append(text.title, "Title")
    append(text.controls, "Special")
    append("")
    append(text.intro, "Comment")
    append(text.modes, "Comment")
    append(text.scope, "Comment")
    local layout = vim.g.nvim_ide_ukrainian_layout or "mac"
    local positions = layout == "mac" and "і=b, и=s" or "і=s, и=b"
    append(text.layout:format(layout .. " (" .. positions .. ")"), "Comment")
    append("")
    local count_line = #lines + 1
    append("")
    append(text.columns, "Comment")
    local terms = vim.split(lower(state.query), "%s+", { trimempty = true })
    local matched, total = 0, 0
    for _, section in ipairs(sections()) do
        local visible = {}
        for _, entry in ipairs(section.entries) do
            total = total + 1
            -- Search both languages and both headings, using literal words, not patterns.
            local haystack = lower(table.concat({ entry[1], entry[2], entry[3], entry[4], section.en, section.uk }, " "))
            if entry[3]:match("^Yank") then haystack = haystack .. " copy clipboard" end
            local matches = true
            for _, term in ipairs(terms) do
                if not haystack:find(term, 1, true) then matches = false; break end
            end
            if matches then visible[#visible + 1] = entry end
        end
        if #visible > 0 then
            append("")
            headings[#headings + 1] = #lines + 1
            append(section[state.language], "Title")
            for _, entry in ipairs(visible) do
                local description = state.language == "uk" and entry[4] or entry[3]
                local key = "  " .. entry[1]
                local prefix = key .. string.rep(" ", math.max(2, 32 - vim.fn.strdisplaywidth(key)))
                local row = prefix .. entry[2] .. string.rep(" ", math.max(2, 9 - #entry[2])) .. description
                append(row)
                highlights[#highlights + 1] = { #lines - 1, 2, #key, "Special" }
                highlights[#highlights + 1] = { #lines - 1, #prefix, #prefix + #entry[2], "Comment" }
                matched = matched + 1
            end
        end
    end
    if matched == 0 then append(""); append(text.empty, "WarningMsg") end
    lines[count_line] = string.format("%s: %d / %d · %s: %s", text.matches, matched, total,
        text.filter, state.query ~= "" and state.query or "—")
    highlights[#highlights + 1] = { count_line - 1, 0, #lines[count_line], "Special" }
    vim.bo[state.buf].readonly = false
    vim.bo[state.buf].modifiable = true
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
    vim.bo[state.buf].modified = false
    vim.bo[state.buf].modifiable = false
    vim.bo[state.buf].readonly = true
    vim.api.nvim_buf_clear_namespace(state.buf, namespace, 0, -1)
    for _, hl in ipairs(highlights) do
        vim.api.nvim_buf_set_extmark(state.buf, namespace, hl[1], hl[2], { end_col = hl[3], hl_group = hl[4] })
    end
    state.headings = headings
    if vim.api.nvim_win_is_valid(state.win) and vim.api.nvim_win_get_buf(state.win) == state.buf then
        vim.api.nvim_win_set_cursor(state.win, { 1, 0 })
        vim.wo[state.win].winbar = " " .. text.title .. " · " .. matched .. " / " .. total .. " · /  e/u  q "
    end
end

function M.open(language)
    language = language or (current and current.language) or vim.g.nvim_ide_help_language or "en"
    if not labels[language] then
        vim.notify("KeymapHelp language must be en or uk", vim.log.levels.WARN)
        return
    end
    vim.g.nvim_ide_help_language = language
    if current and vim.api.nvim_buf_is_valid(current.buf) then
        local windows = vim.fn.win_findbuf(current.buf)
        if #windows > 0 then
            current.win = windows[1]
            vim.api.nvim_set_current_win(current.win)
            current.language = language
            render(current)
            return
        end
    end

    -- A regular split supports native scrolling, selection, copying and window commands.
    -- :new creates a scratch view without editing or saving the originating buffer.
    if vim.o.columns >= 140 then
        vim.cmd("botright " .. math.floor(vim.o.columns * 0.65) .. "vnew")
    else
        vim.cmd("botright " .. math.max(6, math.floor(vim.o.lines * 0.6)) .. "new")
    end
    local state = { buf = vim.api.nvim_get_current_buf(), win = vim.api.nvim_get_current_win(),
        language = language, query = "", headings = {} }
    current = state
    vim.bo[state.buf].buftype = "nofile"
    vim.bo[state.buf].bufhidden = "wipe"
    vim.bo[state.buf].buflisted = false
    vim.bo[state.buf].swapfile = false
    vim.bo[state.buf].undofile = false
    vim.bo[state.buf].undolevels = -1
    vim.bo[state.buf].filetype = "nvim_ide_keys"
    vim.api.nvim_buf_set_name(state.buf, "nvim-ide://keyboard-reference")
    for name, value in pairs({ number = false, relativenumber = false, signcolumn = "no",
        foldcolumn = "0", foldenable = false, wrap = true, linebreak = true, breakindent = true,
        showbreak = "  ", list = false, spell = false, colorcolumn = "", cursorline = false }) do
        vim.wo[state.win][name] = value
    end
    local function map(key, action, description)
        if type(action) == "function" then
            local callback = action
            action = function()
                -- Native :split may show the reference in another window.
                state.win = vim.api.nvim_get_current_win()
                callback()
            end
        end
        vim.keymap.set("n", key, action, { buffer = state.buf, silent = true, nowait = true, desc = description })
    end
    local function close()
        if not vim.api.nvim_win_is_valid(state.win) then return end
        if #vim.api.nvim_tabpage_list_wins(0) > 1 then
            vim.api.nvim_win_close(state.win, true)
        else
            -- The originating window might have been closed while reading the reference.
            vim.cmd("enew")
        end
    end
    map("q", close, "Close keyboard reference")
    map("<Esc>", close, "Close keyboard reference")
    map("<CR>", function() end, "Read reference without executing")
    map("/", function()
        vim.ui.input({ prompt = labels[state.language].filter .. ": ", default = state.query }, function(query)
            if query == nil or not vim.api.nvim_buf_is_valid(state.buf) then return end
            state.query = vim.trim(query)
            render(state)
        end)
    end, "Filter keyboard reference")
    map("c", function() state.query = ""; render(state) end, "Clear reference filter")
    for key, lang in pairs({ e = "en", u = "uk" }) do
        map(key, function()
            state.language = lang
            vim.g.nvim_ide_help_language = lang
            render(state)
        end, "Reference language: " .. lang)
    end
    map("g/", "/", "Native search in keyboard reference")
    for key, direction in pairs({ ["]]"] = 1, ["[["] = -1 }) do
        map(key, function()
            local line = vim.api.nvim_win_get_cursor(state.win)[1]
            local target
            for _, heading in ipairs(state.headings) do
                if direction > 0 and heading > line then target = heading; break end
                if direction < 0 and heading < line then target = heading end
            end
            if target then vim.api.nvim_win_set_cursor(state.win, { target, 0 }) end
        end, "Jump reference section")
    end
    vim.api.nvim_create_autocmd("BufWipeout", { buffer = state.buf, once = true, callback = function()
        if current == state then current = nil end
    end })
    render(state)
end

return M
