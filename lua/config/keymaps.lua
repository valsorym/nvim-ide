-- Single source for global mappings, the command palette and the key reference.
local M = {}
M.groups = {
    b = "Buffers / explorer", c = "Code / language", d = "Document / formatting",
    e = "Editing", f = "Find / replace", g = "Git", o = "Options / tools",
    r = "Run / terminal", t = "Tabs", u = "Interface", w = "Workspaces / sessions",
    x = "Checks / diagnostics",
}
M.groups_uk = {
    b = "Буфери / дерево файлів", c = "Код / мовні інструменти", d = "Документ / форматування",
    e = "Редагування", f = "Пошук / заміна", g = "Git", o = "Параметри / інструменти",
    r = "Запуск / термінал", t = "Вкладки", u = "Інтерфейс", w = "Робочі простори / сесії",
    x = "Перевірки / діагностика",
}

local function command(cmd) return "<Cmd>" .. cmd .. "<CR>" end
local function call(module, method, ...)
    local args = { ... }
    return function() return require(module)[method](unpack(args)) end
end
local function telescope(method, opts)
    return function() require("telescope.builtin")[method](opts or {}) end
end
local function tree_history()
    require("lazy").load({ plugins = { "nvim-tree.lua" } })
    _G.NvimTreeHistory.show_history()
end
local function git_hunk(action)
    return function()
        local mode = vim.fn.mode()
        local range
        if mode == "v" or mode == "V" then
            local a, b = vim.fn.line("v"), vim.fn.line(".")
            range = { math.min(a, b), math.max(a, b) }
        end
        require("gitsigns")[action](range)
    end
end
local function render()
    if require("config.performance").is_large(0) then
        vim.notify("Rendering is disabled for large files", vim.log.levels.WARN)
    elseif vim.bo.filetype == "markdown" then
        require("lazy").load({ plugins = { "render-markdown.nvim" } })
        require("render-markdown").buf_toggle()
    elseif vim.bo.filetype == "rst" then
        require("config.rst").toggle()
    else
        vim.notify("Rendering is available for Markdown and RST")
    end
end

local function move_selection(direction)
    local first, last = vim.fn.line("v"), vim.fn.line(".")
    first, last = math.min(first, last), math.max(first, last)
    if (direction > 0 and last == vim.api.nvim_buf_line_count(0)) or (direction < 0 and first == 1) then return end
    vim.cmd.normal({ args = { "\027" }, bang = true })
    vim.cmd(string.format("%d,%dmove %d", first, last, direction > 0 and last + 1 or first - 2))
    vim.cmd("normal! gv=gv")
end

function M.palette(group)
    local entries = {}
    for _, entry in ipairs(M.entries) do
        -- The palette opens in Normal mode; visual-only actions stay on their keys.
        local modes = type(entry[4]) == "table" and entry[4] or { entry[4] or "n" }
        if vim.tbl_contains(modes, "n") and (not group or entry[1]:sub(1, 9) == "<leader>" .. group) then
            entries[#entries + 1] = entry
        end
    end
    vim.ui.select(entries, { prompt = group and M.groups[group] or "Commands",
        format_item = function(entry) return entry[1] .. "  " .. entry[3] end }, function(entry)
        if not entry then return end
        -- Replay the English mapping; langremap is off so its output stays literal.
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(entry[1], true, false, true), "m", false)
    end)
end

function M.browse()
    local groups = vim.tbl_keys(M.groups)
    table.sort(groups)
    vim.ui.select(groups, { prompt = "Key groups", format_item = function(key)
        return "<leader>" .. key .. "  " .. M.groups[key]
    end }, function(key) if key then M.palette(key) end end)
end

M.entries = {
    { "<leader><leader>", function() M.palette() end, "Search commands", uk = "Пошук команд" },
    { "<leader>?", function() M.browse() end, "Browse key groups", uk = "Переглянути групи клавіш" },
    { "<leader>h", call("config.keymap-help", "open"), "Keyboard reference", uk = "Довідка з комбінацій клавіш" },
    { "<leader>:", telescope("commands"), "Search Ex commands", uk = "Пошук Ex-команд" },
    { "<leader>bb", telescope("buffers"), "Find buffer", uk = "Знайти буфер" },
    { "<leader>bn", command("bnext"), "Next buffer", uk = "Наступний буфер" },
    { "<leader>bp", command("bprevious"), "Previous buffer", uk = "Попередній буфер" },
    { "<leader>bd", command("confirm bdelete"), "Delete buffer", uk = "Закрити буфер" },
    { "<leader>be", command("NvimTreeModal"), "File explorer", uk = "Дерево файлів" },
    { "<leader>bh", tree_history, "Project history", uk = "Історія проєктів" },
    { "<leader>ca", call("vim.lsp.buf", "code_action"), "Code action", { "n", "x" }, uk = "Дія над кодом" },
    { "<leader>cr", call("vim.lsp.buf", "rename"), "Rename symbol", uk = "Перейменувати символ" },
    { "<leader>cd", call("config.lsp", "jump", "definition"), "Go to definition in tab", uk = "Перейти до визначення у вкладці" },
    { "<leader>cD", call("config.lsp", "jump", "declaration"), "Go to declaration in tab", uk = "Перейти до оголошення у вкладці" },
    { "<leader>ci", call("config.lsp", "jump", "implementation"), "Go to implementation in tab", uk = "Перейти до реалізації у вкладці" },
    { "<leader>ct", call("config.lsp", "jump", "type_definition"), "Go to type definition in tab", uk = "Перейти до визначення типу у вкладці" },
    { "<leader>ch", function() vim.lsp.buf.signature_help({ border = "rounded" }) end, "Signature help", uk = "Підказка параметрів функції" },
    { "<leader>cs", command("CodeInspector"), "Document symbols", uk = "Символи документа" },
    { "<leader>cS", command("CodeInspectorGrouped"), "Grouped document symbols", uk = "Згруповані символи документа" },
    { "<leader>cw", telescope("lsp_workspace_symbols"), "Workspace symbols", uk = "Символи робочого простору" },
    { "<leader>co", command("AerialToggle!"), "Toggle code outline", uk = "Показати / сховати структуру коду" },
    { "<leader>cO", command("AerialNavToggle"), "Outline navigation", uk = "Навігація структурою коду" },
    { "<leader>cva", command("VenvActivate"), "Detect Python environment", uk = "Визначити віртуальне середовище Python" },
    { "<leader>cvc", command("VenvSelect"), "Select Python environment", uk = "Вибрати віртуальне середовище Python" },
    { "<leader>cvd", command("VenvDeactivate"), "Use system Python", uk = "Використовувати системний Python" },
    { "<leader>cvs", command("VenvStatus"), "Python environment status", uk = "Стан середовища Python" },
    { "<leader>cvf", command("VenvFind"), "Refresh Python environment", uk = "Оновити середовище Python" },
    { "<leader>cpt", command("CopilotToggle"), "Toggle Copilot", uk = "Увімкнути / вимкнути Copilot" },
    { "<leader>cps", command("Copilot status"), "Copilot status", uk = "Стан Copilot" },
    { "<leader>cpa", command("Copilot setup"), "Copilot setup", uk = "Налаштувати Copilot" },
    { "<leader>cpx", command("Copilot signout"), "Copilot sign out", uk = "Вийти з облікового запису Copilot" },
    { "<leader>df", call("config.formatting", "format"), "Format document", uk = "Форматувати документ" },
    { "<leader>di", call("config.formatting", "format", { only = "isort" }), "Sort Python imports", uk = "Впорядкувати імпорти Python" },
    { "<leader>db", call("config.formatting", "format", { only = "black" }), "Format Python with Black", uk = "Форматувати Python через Black" },
    { "<leader>ds", command("FormatToggle"), "Toggle format on save", uk = "Увімкнути / вимкнути форматування при збереженні" },
    { "<leader>dx", call("config.formatting", "trim"), "Trim trailing whitespace", uk = "Видалити пробіли наприкінці рядків" },
    { "<leader>d2", command("Indent2"), "Use two-space indentation", uk = "Відступ двома пробілами" },
    { "<leader>d4", command("Indent4"), "Use four-space indentation", uk = "Відступ чотирма пробілами" },
    { "<leader>dt", command("IndentTab"), "Use tab indentation", uk = "Відступ табуляцією" },
    { "<leader>dS", command("TabsToSpaces"), "Convert tabs to spaces", uk = "Перетворити табуляцію на пробіли" },
    { "<leader>dT", command("SpacesToTabs"), "Convert spaces to tabs", uk = "Перетворити пробіли на табуляцію" },
    { "<leader>dI", command("IndentInfo"), "Show indentation settings", uk = "Показати налаштування відступів" },
    { "<leader>dr", render, "Toggle Markdown / RST rendering", uk = "Увімкнути / вимкнути оформлення Markdown / RST" },
    { "<leader>ed", '"_d', "Delete without yanking", { "n", "x" }, uk = "Видалити без копіювання" },
    { "<leader>ec", '"_c', "Change without yanking", { "n", "x" }, uk = "Замінити без копіювання" },
    { "<leader>ey", '"+y', "Yank to system clipboard", { "n", "x" }, uk = "Копіювати до системного буфера обміну" },
    { "<leader>ep", '"+p', "Paste system clipboard", { "n", "x" }, uk = "Вставити із системного буфера обміну" },
    { "<leader>ea", '<Cmd>%yank +<CR>', "Yank entire document", uk = "Копіювати весь документ до буфера обміну" },
    { "<leader>eu", command("UndotreeToggle"), "Undo history", uk = "Історія скасування змін" },
    { "<leader>ej", function() move_selection(1) end, "Move selection down", "x", uk = "Перемістити виділення вниз" },
    { "<leader>ek", function() move_selection(-1) end, "Move selection up", "x", uk = "Перемістити виділення вгору" },
    { "<leader>ff", telescope("find_files"), "Find files", uk = "Знайти файли" },
    { "<leader>fg", telescope("live_grep"), "Search project text", uk = "Пошук тексту в проєкті" },
    { "<leader>fG", telescope("live_grep", { vimgrep_arguments = require("config.search").grep_args(true) }), "Search including ignored files", uk = "Пошук тексту включно з ігнорованими файлами" },
    { "<leader>fo", telescope("oldfiles"), "Recent files", uk = "Нещодавні файли" },
    { "<leader>fh", telescope("help_tags"), "Find help", uk = "Знайти довідку Neovim" },
    { "<leader>fs", call("config.buffer-search", "open", false), "Find text in current file", uk = "Знайти текст у поточному файлі" },
    { "<leader>fc", call("config.buffer-search", "open", true), "Replace text in current file", uk = "Замінити текст у поточному файлі" },
    { "<leader>fr", call("config.replace", "search", false), "Find and replace in project", uk = "Знайти й замінити в проєкті" },
    { "<leader>fR", call("config.replace", "search", true), "Find and replace including ignored files", uk = "Знайти й замінити включно з ігнорованими файлами" },
    { "<leader>fw", call("config.replace", "word"), "Replace current word in project", uk = "Замінити поточне слово в проєкті" },
    { "<leader>fj", call("flash", "jump"), "Flash jump", { "n", "x", "o" }, uk = "Швидкий перехід Flash" },
    { "<leader>fJ", call("flash", "treesitter"), "Flash syntax selection", { "n", "x", "o" }, uk = "Виділити синтаксичний об’єкт через Flash" },
    { "<leader>gs", git_hunk("stage_hunk"), "Stage Git hunk", { "n", "x" }, uk = "Додати фрагмент змін до індексу Git" },
    { "<leader>gr", git_hunk("reset_hunk"), "Reset Git hunk", { "n", "x" }, uk = "Скинути фрагмент змін Git" },
    { "<leader>gp", call("gitsigns", "preview_hunk"), "Preview Git hunk", uk = "Переглянути фрагмент змін Git" },
    { "<leader>gb", call("gitsigns", "blame_line", { full = true }), "Blame current line", uk = "Показати автора поточного рядка" },
    { "<leader>gd", call("gitsigns", "diffthis"), "Diff current file", uk = "Показати зміни поточного файлу" },
    { "<leader>gt", call("gitsigns", "toggle_current_line_blame"), "Toggle line blame", uk = "Показати / сховати автора рядка" },
    { "<leader>ol", command("Lazy"), "Plugin manager", uk = "Менеджер плагінів" },
    { "<leader>om", command("Mason"), "Language tool manager", uk = "Менеджер мовних інструментів" },
    { "<leader>oc", function() require("config.nvim-tabs").open(vim.fn.stdpath("config") .. "/init.lua") end, "Open editor configuration", uk = "Відкрити налаштування редактора" },
    { "<leader>rf", call("config.terminal", "toggle", "float"), "Floating terminal", uk = "Термінал у плавучому вікні" },
    { "<leader>rh", call("config.terminal", "toggle", "horizontal"), "Horizontal terminal", uk = "Термінал у горизонтальному розділенні" },
    { "<leader>rv", call("config.terminal", "toggle", "vertical"), "Vertical terminal", uk = "Термінал у вертикальному розділенні" },
    { "<leader>rp", call("config.terminal", "run", "python"), "Python REPL", uk = "Інтерактивна консоль Python" },
    { "<leader>rn", call("config.terminal", "run", "node"), "Node REPL", uk = "Інтерактивна консоль Node" },
    { "<leader>rd", call("config.terminal", "run", "django"), "Django shell", uk = "Консоль Django" },
    { "<leader>rr", call("config.terminal", "run", "runserver"), "Django development server", uk = "Сервер розробки Django" },
    { "<leader>tn", call("config.nvim-tabs", "new"), "New tab", uk = "Нова вкладка" },
    { "<leader>tq", call("config.nvim-tabs", "close", false), "Close current tab", uk = "Закрити поточну вкладку" },
    { "<leader>tQ", call("config.nvim-tabs", "close", true), "Discard and close current tab", uk = "Відкинути зміни й закрити поточну вкладку" },
    { "<leader>tc", call("config.nvim-tabs", "close_saved"), "Close saved tabs", uk = "Закрити збережені вкладки" },
    { "<leader>to", command("confirm tabonly"), "Close other tabs", uk = "Закрити інші вкладки" },
    { "<leader>tl", call("config.tabs-list", "show_tabs_window"), "Tab list", uk = "Список вкладок" },
    { "<leader>th", call("config.nvim-tabs", "move_tab_left"), "Move tab left", uk = "Перемістити вкладку ліворуч" },
    { "<leader>tj", call("config.nvim-tabs", "move_tab_right"), "Move tab right", uk = "Перемістити вкладку праворуч" },
    { "<leader>ta", command("confirm qall"), "Quit editor", uk = "Вийти з редактора" },
    { "<leader>ut", call("config.theme", "pick", false), "Preview and select theme", uk = "Переглянути й вибрати тему" },
    { "<leader>us", call("config.theme", "pick", true), "Select and save theme", uk = "Вибрати й зберегти тему" },
    { "<leader>ui", command("ThemeInfo"), "Current theme", uk = "Поточна тема" },
    { "<leader>uI", function() require("ibl").setup_buffer(0, { enabled = not require("ibl.config").get_config(0).enabled }) end, "Toggle indent guides", uk = "Показати / сховати напрямні відступів" },
    { "<leader>uw", function() vim.wo.wrap = not vim.wo.wrap end, "Toggle wrapping", uk = "Увімкнути / вимкнути перенесення рядків" },
    { "<leader>ul", function() vim.wo.list = not vim.wo.list end, "Toggle whitespace marks", uk = "Показати / сховати позначки пробілів" },
    { "<leader>uc", function() require("config.line-width").toggle() end, "Toggle column guide", uk = "Показати / сховати межу колонки" },
    { "<leader>ws", command("SessionSave"), "Save session", uk = "Зберегти сесію" },
    { "<leader>wr", command("SessionRestore"), "Restore session", uk = "Відновити сесію" },
    { "<leader>wl", command("SessionLast"), "Restore last session", uk = "Відновити останню сесію" },
    { "<leader>wD", command("SessionDelete"), "Delete current session", uk = "Видалити поточну сесію" },
    { "<leader>wf", command("SessionFind"), "Find session", uk = "Знайти сесію" },
    { "<leader>wL", command("SessionLegacy"), "Import legacy session", uk = "Імпортувати сесію попереднього формату" },
    { "<leader>ww", command("WorkspaceFind"), "Find workspace", uk = "Знайти робочий простір" },
    { "<leader>wa", command("WorkspaceAdd"), "Add workspace", uk = "Додати робочий простір" },
    { "<leader>xx", function() vim.diagnostic.open_float({ scope = "line" }) end, "Line diagnostics", uk = "Показати проблеми поточного рядка" },
    { "<leader>xb", command("Trouble diagnostics toggle filter.buf=0"), "Buffer diagnostics", uk = "Проблеми поточного буфера" },
    { "<leader>xw", command("Trouble diagnostics toggle"), "Workspace diagnostics", uk = "Проблеми робочого простору" },
    { "<leader>xq", command("Trouble qflist toggle"), "Quickfix list", uk = "Список Quickfix" },
    { "<leader>xl", command("Trouble loclist toggle"), "Location list", uk = "Список Location" },
    { "<leader>xt", command("TodoTelescope"), "Find TODO comments", uk = "Знайти коментарі TODO" },
    { "<leader>xT", command("TodoTelescope keywords=TODO,FIX,FIXME"), "Find TODO / FIXME", uk = "Знайти TODO / FIXME" },
    { "<leader>xp", command("PythonToolsStatus"), "Python tools status", uk = "Стан інструментів Python" },
    { "<leader>xi", command("checkhealth vim.lsp"), "LSP health", uk = "Перевірити стан LSP" },
    { "<leader>xh", command("checkhealth nvim_ide"), "Editor / terminal health", uk = "Перевірити стан редактора / термінала" },
    { "<leader>xH", call("config.ide-health", "open"), "Language tools and feature health", uk = "Діагностика інструментів і можливостей редактора" },
    { "<leader>xL", command("LargeFileInfo"), "Buffer performance mode", uk = "Режим швидкодії поточного буфера" },
    { "<F2>", call("config.safe-save", "smart_write"), "Save file", { "n", "i" }, uk = "Зберегти файл" },
    { "<F5>", command("tabprevious"), "Previous tab", uk = "Попередня вкладка" },
    { "<F6>", command("tabnext"), "Next tab", uk = "Наступна вкладка" },
    { "<F7>", command("CodeInspector"), "Document symbols", uk = "Символи документа" },
    { "<F8>", call("config.tabs-list", "show_tabs_window"), "Tab list", uk = "Список вкладок" },
    { "<F9>", command("NvimTreeModal"), "File explorer", uk = "Дерево файлів" },
    { "<F10>", telescope("buffers"), "Buffer list", uk = "Список буферів" },
    { "gd", call("config.lsp", "jump", "definition", "gd"), "Go to definition in tab", uk = "Перейти до визначення у вкладці" },
    { "gD", call("config.lsp", "jump", "declaration", "gD"), "Go to declaration in tab", uk = "Перейти до оголошення у вкладці" },
    { "gri", call("config.lsp", "jump", "implementation"), "Go to implementation in tab", uk = "Перейти до реалізації у вкладці" },
    { "grt", call("config.lsp", "jump", "type_definition"), "Go to type definition in tab", uk = "Перейти до визначення типу у вкладці" },
    { "gl", function() vim.diagnostic.open_float({ scope = "line" }) end, "Line diagnostics", uk = "Показати проблеми поточного рядка" },
    { "<C-LeftMouse>", call("config.lsp", "jump", "definition", "<C-]>"), "Go to definition in tab", uk = "Перейти до визначення у вкладці" },
    { "zR", call("ufo", "openAllFolds"), "Open all folds", uk = "Розгорнути всі згортки" },
    { "zM", call("ufo", "closeAllFolds"), "Close all folds", uk = "Згорнути всі згортки" },
    { "zr", command("normal! zr"), "Reduce fold level", uk = "Зменшити рівень згортання" },
    { "zm", call("ufo", "closeFoldsWith"), "Fold one more level", uk = "Згорнути ще один рівень" },
    { "zp", function() if not require("ufo").peekFoldedLinesUnderCursor() then vim.lsp.buf.hover() end end, "Preview fold", uk = "Переглянути вміст згортки" },
    { "]t", call("todo-comments", "jump_next"), "Next TODO", uk = "Наступний TODO" },
    { "[t", call("todo-comments", "jump_prev"), "Previous TODO", uk = "Попередній TODO" },
    { "]c", function() if vim.wo.diff then vim.cmd("normal! ]c") else require("gitsigns").nav_hunk("next") end end, "Next Git hunk", uk = "Наступний фрагмент змін Git" },
    { "[c", function() if vim.wo.diff then vim.cmd("normal! [c") else require("gitsigns").nav_hunk("prev") end end, "Previous Git hunk", uk = "Попередній фрагмент змін Git" },
    { "<Esc>", command("nohlsearch"), "Clear search highlight", uk = "Прибрати підсвічування пошуку" },
}

function M.setup()
    vim.ui.select = require("config.picker").select
    for _, entry in ipairs(M.entries) do
        vim.keymap.set(entry[4] or "n", entry[1], entry[2], { silent = true, desc = entry[3] })
    end
    -- Keep native operators, Ctrl-W windows, Ctrl-T tags, Ctrl-K digraphs and z folds.
    vim.keymap.set("x", "<", "<gv", { silent = true, desc = "Indent selection left" })
    vim.keymap.set("x", ">", ">gv", { silent = true, desc = "Indent selection right" })
    vim.api.nvim_create_user_command("TabsList", call("config.tabs-list", "show_tabs_window"), {})
    vim.api.nvim_create_user_command("KeymapLegend", function() M.palette() end, {})
    vim.api.nvim_create_user_command("FindInBuffer", call("config.buffer-search", "open", false),
        { desc = "Find literal text in the current buffer" })
    vim.api.nvim_create_user_command("ReplaceInBuffer", call("config.buffer-search", "open", true),
        { desc = "Replace literal text in the current buffer" })
    vim.api.nvim_create_user_command("KeymapHelp", function(opts)
        require("config.keymap-help").open(opts.args ~= "" and opts.args or nil)
    end, { nargs = "?", complete = function() return { "en", "uk" } end,
        desc = "Open the English or Ukrainian keyboard reference" })
    vim.api.nvim_create_user_command("IdeHealth", function(opts)
        require("config.ide-health").open(opts.args ~= "" and opts.args or nil)
    end, { nargs = "?", complete = function() return { "en", "uk" } end,
        desc = "Inspect language tools and feature availability" })
end
return M
