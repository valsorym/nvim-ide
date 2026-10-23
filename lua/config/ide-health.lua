-- A read-only, bilingual view of tools required by the configured features.
local M = {}
local current
local namespace = vim.api.nvim_create_namespace("nvim_ide_health")
local labels = {
    en = {
        title = "Neovim IDE · Tools and features", short = "IDE health",
        controls = "/ Filter  c Clear  r Refresh  e English  u Українська  [[ / ]] Sections  q Close",
        scope = "Availability check only: tools are not executed, installed or validated. Paths use the source project.",
        legend = "OK Found / available · NO Missing · WARN Limited · NATIVE Built in · OFF Not enabled / configured · INFO Details",
        source = "Source", filetype = "Filetype", unnamed = "Unnamed buffer", matches = "Features", filter = "Filter (both languages)",
        missing = "not found", install = "Installation", empty = "No matches. Press c to clear the filter.",
        footer = { "Filter", "Refresh", "Language", "Close" },
    },
    uk = {
        title = "Neovim IDE · Інструменти й можливості", short = "Діагностика IDE",
        controls = "/ Фільтр  c Очистити  r Оновити  e English  u Українська  [[ / ]] Розділи  q Закрити",
        scope = "Перевірка доступності: інструменти не запускаються, не встановлюються й не перевіряються виконанням. Шляхи — для вихідного проєкту.",
        legend = "OK Є / доступно · NO Немає · WARN Обмежено · NATIVE Вбудовано · OFF Не увімкнено / не налаштовано · INFO Подробиці",
        source = "Джерело", filetype = "Тип файла", unnamed = "Буфер без назви", matches = "Можливості", filter = "Фільтр (обидві мови)",
        missing = "не знайдено", install = "Встановлення", empty = "Збігів немає. Натисни c, щоб очистити фільтр.",
        footer = { "Фільтр", "Оновити", "Мова", "Закрити" },
    },
}
local status_groups = { ok = "DiagnosticOk", no = "DiagnosticError", warn = "DiagnosticWarn",
    native = "DiagnosticInfo", off = "Comment", info = "Comment" }
local status_words = { ok = "found available є доступно", no = "missing not found немає не знайдено",
    warn = "limited обмежено", native = "built in вбудовано", off = "not enabled configured вимкнено не налаштовано", info = "details подробиці" }

local function window_config(state)
    local columns, lines = vim.o.columns, vim.o.lines - vim.o.cmdheight
    local width = math.max(1, math.min(math.floor(columns * 0.9), columns - 4))
    local height = math.max(1, math.min(math.floor(lines * 0.85), lines - 4))
    local text = labels[state.language]
    local suffix = string.format(" · %s · %d / %d ", state.language:upper(), state.matched or 0, state.total or 0)
    local title = " " .. text.title .. suffix
    if vim.fn.strdisplaywidth(title) > width then title = " " .. text.short .. suffix end
    local footer = {}
    for i, key in ipairs({ "/", "r", "e/u", "q/Esc" }) do
        footer[#footer + 1] = { " " .. key .. " ", "FooterKey" }
        footer[#footer + 1] = { text.footer[i] .. " ", "FooterDesc" }
        if i < 4 then footer[#footer + 1] = { "·", "FooterDesc" } end
    end
    local footer_text = ""
    for _, chunk in ipairs(footer) do footer_text = footer_text .. chunk[1] end
    if vim.fn.strdisplaywidth(footer_text) > width then
        footer = { { width >= 26 and " / · r · e/u · q/Esc " or " q/Esc ", "FooterKey" } }
    end
    return { relative = "editor", border = "rounded", focusable = true, zindex = 70,
        width = width, height = height, row = math.max(0, math.floor((lines - height - 2) / 2)),
        col = math.max(0, math.floor((columns - width - 2) / 2)),
        title = { { title, "FloatTitle" } }, title_pos = "center", footer = footer, footer_pos = "center" }
end

local function render(state, preserve_view)
    if not vim.api.nvim_buf_is_valid(state.buf) then return end
    local text, language = labels[state.language], state.language
    local view = preserve_view and vim.api.nvim_win_call(state.win, vim.fn.winsaveview) or nil
    local lines, highlights, headings = { "" }, {}, {}
    local function append(line, group)
        lines[#lines + 1] = line ~= "" and (" " .. line) or ""
        if group then highlights[#highlights + 1] = { #lines - 1, group } end
    end
    append(text.title, "Title")
    append(text.controls, "Special")
    append("")
    append(text.scope, "Comment")
    append(text.legend, "Comment")
    append(text.source .. ": " .. (state.report.file ~= "" and state.report.file or text.unnamed), "Comment")
    append(text.filetype .. ": " .. (state.report.filetype ~= "" and state.report.filetype or "—"), "Comment")
    append("")
    local count_row = #lines + 1
    append("")
    local total, matched = 0, 0
    local terms = vim.split(vim.fn.tolower(state.query), "%s+", { trimempty = true })
    for _, section in ipairs(state.report.sections) do
        local visible = {}
        for _, feature in ipairs(section.features) do
            total = total + 1
            local words = { section.id, section.title.en, section.title.uk, feature.title.en, feature.title.uk, feature.status, status_words[feature.status],
                feature.note and feature.note.en or "", feature.note and feature.note.uk or "", feature.advice or "" }
            for _, tool in ipairs(feature.tools) do words[#words + 1] = tool.name .. " " .. (tool.path or "") .. " " .. tool.status end
            local haystack = vim.fn.tolower(table.concat(words, " "))
            local matches = true
            for _, term in ipairs(terms) do if not haystack:find(term, 1, true) then matches = false; break end end
            if matches then visible[#visible + 1] = feature end
        end
        if #visible > 0 then
            append("")
            headings[#headings + 1] = #lines + 1
            append(section.title[language], "Title")
            for _, feature in ipairs(visible) do
                matched = matched + 1
                append("  [" .. feature.status:upper() .. "] " .. feature.title[language], status_groups[feature.status])
                for _, tool in ipairs(feature.tools) do
                    append("    [" .. tool.status:upper() .. "] " .. tool.name .. "  " .. (tool.path or text.missing), status_groups[tool.status])
                end
                if feature.note then append("    " .. feature.note[language], "Comment") end
                if feature.advice then append("    " .. text.install .. ": " .. feature.advice, "Special") end
                append("")
            end
        end
    end
    if matched == 0 then append(text.empty, "WarningMsg") end
    lines[count_row] = string.format(" %s: %d / %d · %s: %s", text.matches, matched, total, text.filter,
        state.query ~= "" and state.query or "—")
    highlights[#highlights + 1] = { count_row - 1, "Special" }
    vim.bo[state.buf].readonly, vim.bo[state.buf].modifiable = false, true
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
    vim.bo[state.buf].modified = false
    vim.bo[state.buf].modifiable, vim.bo[state.buf].readonly = false, true
    vim.api.nvim_buf_clear_namespace(state.buf, namespace, 0, -1)
    for _, hl in ipairs(highlights) do
        vim.api.nvim_buf_set_extmark(state.buf, namespace, hl[1], 1, { end_col = #lines[hl[1] + 1], hl_group = hl[2] })
    end
    state.headings, state.matched, state.total = headings, matched, total
    if vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_set_config(state.win, window_config(state))
        if view then vim.api.nvim_win_call(state.win, function() vim.fn.winrestview(view) end)
        else vim.api.nvim_win_set_cursor(state.win, { 2, 1 }) end
    end
end

local function source_buffer()
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].buftype == "" then return buf end
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local candidate = vim.api.nvim_win_get_buf(win)
        if vim.api.nvim_win_get_config(win).relative == "" and vim.bo[candidate].buftype == "" then return candidate end
    end
    return buf
end

function M.open(language)
    language = language or (current and current.language) or vim.g.nvim_ide_health_language or vim.g.nvim_ide_help_language or "en"
    if not labels[language] then vim.notify("IdeHealth language must be en or uk", vim.log.levels.WARN); return end
    vim.g.nvim_ide_health_language = language
    if current and vim.api.nvim_buf_is_valid(current.buf) then
        local windows = vim.fn.win_findbuf(current.buf)
        if #windows > 0 then
            if vim.api.nvim_get_current_buf() ~= current.buf then
                current.origin, current.source = vim.api.nvim_get_current_win(), source_buffer()
            end
            if not vim.api.nvim_buf_is_valid(current.source) then current.source = source_buffer() end
            current.win, current.language = windows[1], language
            current.report = require("config.health-report").collect(current.source)
            vim.api.nvim_set_current_win(current.win)
            render(current)
            return
        end
    end
    local state = { source = source_buffer(), origin = vim.api.nvim_get_current_win(), language = language,
        buf = vim.api.nvim_create_buf(false, true), query = "" }
    state.report = require("config.health-report").collect(state.source)
    local config = window_config(state)
    config.style = "minimal"
    state.win = vim.api.nvim_open_win(state.buf, true, config)
    current = state
    for name, value in pairs({ buftype = "nofile", bufhidden = "wipe", buflisted = false, swapfile = false,
        undofile = false, undolevels = -1, filetype = "nvim_ide_health" }) do vim.bo[state.buf][name] = value end
    vim.api.nvim_buf_set_name(state.buf, "nvim-ide://health")
    for name, value in pairs({ number = false, relativenumber = false, signcolumn = "no", foldcolumn = "0",
        foldenable = false, wrap = true, linebreak = true, breakindent = true, showbreak = "  ", list = false,
        spell = false, colorcolumn = "", cursorline = false, winbar = "" }) do vim.wo[state.win][name] = value end
    local function map(key, callback, description)
        local action = callback
        if type(callback) == "function" then action = function() state.win = vim.api.nvim_get_current_win(); callback() end end
        vim.keymap.set("n", key, action, { buffer = state.buf, silent = true, nowait = true, desc = description })
    end
    local function close()
        if vim.api.nvim_win_is_valid(state.win) then
            local ok = pcall(vim.api.nvim_win_close, state.win, true)
            if not ok and vim.api.nvim_buf_is_valid(state.buf) then vim.api.nvim_buf_delete(state.buf, { force = true }) end
        end
        if vim.api.nvim_win_is_valid(state.origin) then vim.api.nvim_set_current_win(state.origin) end
    end
    map("q", close, "Close IDE health")
    map("<Esc>", close, "Close IDE health")
    map("<CR>", function() end, "Read health without executing")
    map("/", function()
        vim.ui.input({ prompt = labels[state.language].filter .. ": ", default = state.query }, function(query)
            if query == nil or not vim.api.nvim_buf_is_valid(state.buf) then return end
            state.query = vim.trim(query)
            render(state)
        end)
    end, "Filter IDE health")
    map("c", function() state.query = ""; render(state) end, "Clear health filter")
    map("r", function()
        if not vim.api.nvim_buf_is_valid(state.source) then
            vim.notify("The source buffer was closed; reopen IdeHealth from a file", vim.log.levels.WARN)
            return
        end
        require("config.python-venv").refresh()
        require("config.tools").setup_path()
        state.report = require("config.health-report").collect(state.source)
        render(state, true)
    end, "Refresh IDE health")
    for key, lang in pairs({ e = "en", u = "uk" }) do
        map(key, function() state.language = lang; vim.g.nvim_ide_health_language = lang; render(state) end, "Health language: " .. lang)
    end
    map("g/", "/", "Native search in IDE health")
    for key, direction in pairs({ ["]]"] = 1, ["[["] = -1 }) do
        map(key, function()
            local line, target = vim.api.nvim_win_get_cursor(state.win)[1]
            for _, heading in ipairs(state.headings) do
                if direction > 0 and heading > line then target = heading; break end
                if direction < 0 and heading < line then target = heading end
            end
            if target then vim.api.nvim_win_set_cursor(state.win, { target, 1 }) end
        end, "Jump health section")
    end
    local group = vim.api.nvim_create_augroup("IdeHealth" .. state.buf, { clear = true })
    vim.api.nvim_create_autocmd("VimResized", { group = group, callback = function()
        if vim.api.nvim_win_is_valid(state.win) then vim.api.nvim_win_set_config(state.win, window_config(state)) end
    end })
    vim.api.nvim_create_autocmd("BufWipeout", { group = group, buffer = state.buf, once = true, callback = function()
        if current == state then current = nil end
        vim.api.nvim_del_augroup_by_id(group)
    end })
    render(state)
end

return M
