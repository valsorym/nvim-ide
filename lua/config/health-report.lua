-- Availability only: no subprocesses, plugin loading, installation or buffer changes.
local M = {}
local function text(en, uk) return { en = en, uk = uk } end

function M.collect(buf)
    local tools = require("config.tools")
    local python = require("config.python-venv")
    local path = vim.api.nvim_buf_get_name(buf)
    local context = vim.bo[buf].buftype == "" and path or vim.fn.getcwd()
    local report = { file = path, filetype = vim.bo[buf].filetype, sections = {} }
    local function section(id, en, uk)
        local value = { id = id, title = text(en, uk), features = {} }
        report.sections[#report.sections + 1] = value
        return value
    end
    local function tool(name, ft)
        local found
        if ft == false then
            local exe = vim.fn.exepath(name)
            found = exe ~= "" and exe or nil
        else
            found = tools.executable(name, buf, ft or "", context)
        end
        return { name = name, path = found, status = found and "ok" or "no" }
    end
    local function feature(s, id, en, uk, requirements, advice, ft)
        local value = { id = id, title = text(en, uk), status = "ok", tools = {}, advice = advice }
        for _, name in ipairs(requirements or {}) do
            local item = tool(name, ft)
            value.tools[#value.tools + 1] = item
            if not item.path then value.status = "no" end
        end
        s.features[#s.features + 1] = value
        return value
    end
    local function native(s, id, en, uk, note, status)
        local value = feature(s, id, en, uk)
        value.status, value.note = status or "native", note
        return value
    end
    local function formatter(s, name, ft, advice, runtime)
        local requirements = { name }
        if runtime then requirements[#requirements + 1] = runtime end
        local value = feature(s, "format", "Formatting · Space df", "Форматування · Пробіл df", requirements, advice, ft)
        value.filetypes = { ft }
        value.commands = { name }
        return value
    end
    local function lsp(s, names, advice, runtime)
        local requirements = vim.list_extend({}, names)
        if runtime then requirements[#requirements + 1] = runtime end
        local value = feature(s, "lsp", "Completion, navigation, diagnostics", "Доповнення, переходи, діагностика", requirements, advice, false)
        value.note = text("Executables available; attachment and server configuration are checked separately with :checkhealth vim.lsp.",
            "Перевірено доступність команд; під'єднання й налаштування сервера перевіряються окремо через :checkhealth vim.lsp.")
        return value
    end
    local function parser(s, names)
        local value = feature(s, "parsers", "Tree-sitter highlighting", "Підсвічування Tree-sitter", {}, ":TSInstall " .. table.concat(names, " "))
        for _, name in ipairs(names) do
            local files = vim.api.nvim_get_runtime_file("parser/" .. name .. ".*", true)
            local found
            for _, file in ipairs(files) do
                if file:match("%.so$") or file:match("%.dll$") or file:match("%.dylib$") then found = file; break end
            end
            value.tools[#value.tools + 1] = { name = name .. " parser", path = found, status = found and "ok" or "no" }
            if not found then value.status = "no" end
        end
        value.note = text("Optional; native syntax highlighting remains available. File presence does not validate parser compatibility.",
            "Необов'язково; вбудоване підсвічування залишається доступним. Наявність файла не перевіряє сумісність парсера.")
        return value
    end

    local current = section("current", "Current buffer", "Поточний буфер")
    local mode = native(current, "mode", "Language integrations and formatting", "Мовні можливості й форматування",
        text("Normal buffer; see the language requirements below.", "Звичайний буфер; вимоги для мови наведено нижче."), "ok")
    if require("config.performance").is_large(buf) then
        mode.status, mode.note = "warn", text("Large-file mode disables LSP, Tree-sitter and formatting in this buffer.",
            "Режим великого файлу вимикає LSP, Tree-sitter та форматування в цьому буфері.")
    elseif vim.bo[buf].buftype ~= "" or vim.bo[buf].readonly or not vim.bo[buf].modifiable then
        mode.status, mode.note = "warn", text("Formatting is disabled for this special or read-only buffer.",
            "Форматування вимкнене для цього службового буфера або буфера лише для читання.")
    end
    local clients = {}
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do clients[#clients + 1] = client.name end
    table.sort(clients)
    native(current, "clients", "Attached language clients", "Під'єднані мовні клієнти",
        #clients > 0 and text(table.concat(clients, ", "), table.concat(clients, ", "))
        or text("None attached. A tool may be installed while its server is still starting, has failed, or has no suitable project root.",
            "Немає під'єднаних клієнтів. Інструмент може бути встановлений, але сервер ще запускається, завершився з помилкою або не знайшов кореня проєкту."),
        #clients > 0 and "ok" or "info")
    native(current, "save", "Formatting on save", "Форматування при збереженні",
        text("Space ds toggles this setting; a buffer may also set autoformat=false.",
            "Пробіл ds перемикає цей параметр; буфер також може мати autoformat=false."),
        vim.g.format_on_save and vim.b[buf].autoformat ~= false and "ok" or "off")

    local core = section("editor", "Editor, projects and terminal", "Редактор, проєкти й термінал")
    native(core, "version", "Neovim 0.11.3+", "Neovim 0.11.3+",
        text("Running " .. tostring(vim.version()), "Поточна версія " .. tostring(vim.version())),
        vim.fn.has("nvim-0.11.3") == 1 and "ok" or "no")
    feature(core, "git", "Git integration", "Інтеграція Git", { "git" }, "Debian: sudo apt install git", false)
    feature(core, "search", "Project search and replacement", "Пошук і заміна в проєкті", { "rg" }, "Debian: sudo apt install ripgrep", false)
    local desktop = feature(core, "desktop", "Separate desktop window", "Окреме вікно редактора", { "alacritty" }, "Debian: sudo apt install alacritty", false)
    desktop.note = text("Install the nvim-ide launcher and desktop entry as described in SETUP_DEBIAN.md.",
        "Встанови сценарій запуску nvim-ide та пункт меню за SETUP_DEBIAN.UK.md.")
    native(core, "colors", "24-bit colour setting", "Параметр 24-бітного кольору",
        text("TERM=" .. (vim.env.TERM or "") .. (vim.env.TMUX and "; tmux: see :checkhealth nvim_ide and extras/tmux.conf" or "; see :checkhealth nvim_ide"),
            "TERM=" .. (vim.env.TERM or "") .. (vim.env.TMUX and "; tmux: див. :checkhealth nvim_ide та extras/tmux.conf" or "; див. :checkhealth nvim_ide")),
        vim.o.termguicolors and "ok" or "warn")
    native(core, "clipboard", "System clipboard", "Системний буфер обміну",
        text("Provider/connection checks: :checkhealth vim.provider. A custom provider, desktop clipboard or terminal OSC52 may be used.",
            "Перевірка провайдера й з'єднання: :checkhealth vim.provider. Може використовуватися власний провайдер, буфер графічної сесії або OSC52 термінала."), "info")
    local copilot = feature(core, "copilot", "Optional Copilot", "Необов'язковий Copilot", { "node" }, "Debian: sudo apt install nodejs", false)
    if copilot.status == "ok" and vim.g.copilot_enabled ~= 1 then copilot.status = "off" end
    copilot.note = text("Enabled explicitly with Space cpt; account, runtime version and connection: :Copilot status / :Copilot setup.",
        "Вмикається явно через Пробіл cpt; обліковий запис, версія середовища й з'єднання: :Copilot status / :Copilot setup.")

    local py = section("python", "Python", "Python")
    local interpreter = python.python(context ~= "" and context or vim.fn.getcwd())
    local runtime = feature(py, "runtime", "Interpreter / project environment", "Інтерпретатор / середовище проєкту")
    runtime.status = vim.fn.executable(interpreter) == 1 and "ok" or "no"
    runtime.tools = { { name = "Python", path = runtime.status == "ok" and interpreter or nil, status = runtime.status } }
    runtime.note = text("Resolved for the source project; :VenvSelect changes the interpreter.",
        "Визначено для вихідного проєкту; :VenvSelect змінює інтерпретатор.")
    runtime.advice = "Debian: sudo apt install python3 python3-venv"
    local preference = vim.g.nvim_ide_python_formatter or "ruff"
    local ruff = tools.executable("ruff", buf, "python", context)
    local pyformat
    if preference ~= "black" and ruff then
        pyformat = formatter(py, "ruff", "python", ":MasonInstall ruff")
        pyformat.note = text("Ruff sorts imports and formats code; Black and isort are not required.",
            "Ruff впорядковує імпорти й форматує код; Black та isort не потрібні.")
    else
        pyformat = feature(py, "format", "Formatting · Space df", "Форматування · Пробіл df", { "isort", "black" },
            preference == "black" and "Project venv: python -m pip install black isort" or ":MasonInstall ruff", "python")
        if pyformat.status == "no" and (pyformat.tools[1].path or pyformat.tools[2].path) then pyformat.status = "warn" end
        pyformat.note = text("Fallback pipeline: isort sorts imports; Black formats code. Both complete the pipeline.",
            "Резервний ланцюжок: isort впорядковує імпорти, Black форматує код. Для повного ланцюжка потрібні обидва.")
        pyformat.commands = { "isort", "black" }
    end
    pyformat.filetypes = { "python" }
    if preference ~= "black" and preference ~= "ruff" then
        pyformat.note = text("Invalid formatter preference; formatting falls back to Ruff, then Black/isort.",
            "Некоректний вибір форматера; форматування використовує Ruff, далі Black/isort.")
    end
    lsp(py, { "pyright-langserver" }, ":MasonInstall pyright", "node")
    parser(py, { "python" })

    local specs = {
        { "go", "Go", "Go", "gofmt", "Debian: sudo apt install golang-go", { "gopls", "go" }, "Debian: sudo apt install golang-go gopls", { "go" } },
        { "c", "C", "C", "clang-format", "Debian: sudo apt install clang-format", { "clangd" }, "Debian: sudo apt install clangd", { "c" } },
        { "cpp", "C++", "C++", "clang-format", "Debian: sudo apt install clang-format", { "clangd" }, "Debian: sudo apt install clangd", { "cpp" } },
        { "lua", "Lua", "Lua", "stylua", ":MasonInstall stylua", { "lua-language-server" }, ":MasonInstall lua-language-server", { "lua" } },
        { "javascript", "JavaScript / JSX", "JavaScript / JSX", "prettier", ":MasonInstall prettier", { "typescript-language-server" }, ":MasonInstall typescript-language-server", { "javascript", "tsx" }, "node" },
        { "typescript", "TypeScript / TSX", "TypeScript / TSX", "prettier", ":MasonInstall prettier", { "typescript-language-server" }, ":MasonInstall typescript-language-server", { "typescript", "tsx" }, "node" },
        { "vue", "Vue", "Vue", "prettier", ":MasonInstall prettier", { "vue-language-server", "typescript-language-server" }, ":MasonInstall vue-language-server typescript-language-server", { "vue" }, "node" },
        { "html", "HTML", "HTML", "prettier", ":MasonInstall prettier", { "vscode-html-language-server" }, ":MasonInstall html-lsp", { "html" }, "node" },
        { "css", "CSS / SCSS / Less", "CSS / SCSS / Less", "prettier", ":MasonInstall prettier", { "vscode-css-language-server" }, ":MasonInstall css-lsp", { "css", "scss" }, "node" },
        { "json", "JSON / JSONC", "JSON / JSONC", "prettier", ":MasonInstall prettier", { "vscode-json-language-server" }, ":MasonInstall json-lsp", { "json" }, "node" },
        { "yaml", "YAML", "YAML", "prettier", ":MasonInstall prettier", { "yaml-language-server" }, ":MasonInstall yaml-language-server", { "yaml" }, "node" },
        { "sh", "Shell / Bash", "Shell / Bash", "shfmt", "Debian: sudo apt install shfmt", { "bash-language-server" }, ":MasonInstall bash-language-server", { "bash" }, "node" },
        { "markdown", "Markdown", "Markdown", "prettier", ":MasonInstall prettier", { "marksman" }, ":MasonInstall marksman", { "markdown", "markdown_inline" } },
    }
    local aliases = { javascript = { "javascript", "javascriptreact" }, typescript = { "typescript", "typescriptreact" },
        css = { "css", "scss", "less" }, json = { "json", "jsonc" }, sh = { "sh", "bash" } }
    for _, spec in ipairs(specs) do
        local s = section(spec[1], spec[2], spec[3])
        local format = formatter(s, spec[4], spec[1], spec[5], spec[4] == "prettier" and "node" or nil)
        if spec[4] == "prettier" then
            local selected = require("config.web-formatting").select(buf, context, spec[1])
            format.tools = { { name = selected.name, path = selected.executable, status = selected.executable and "ok" or "no" }, tool("node", false) }
            format.commands = { selected.name }
            format.status = selected.executable and format.tools[2].path and "ok" or "no"
            format.advice = selected.preference == "prettier" and ":MasonInstall prettier" or ":MasonInstall prettierd"
            format.note = selected.name == "prettierd"
                and text("Selected: prettierd. Starts on first formatting; uses project-local Prettier when installed. Prettier CLI is not required alongside it.",
                    "Вибрано prettierd. Запускається при першому форматуванні; використовує Prettier проєкту за наявності. Окремий Prettier CLI не потрібен.")
                or text("Selected: prettier. Used when explicitly selected or when prettierd is not installed.",
                    "Вибрано prettier. Використовується при явному виборі або за відсутності prettierd.")
            if selected.invalid_preference then
                format.note = text("Invalid web formatter preference; using prettierd when available, otherwise prettier.",
                    "Некоректний вибір web-форматера; використовується prettierd за наявності, інакше prettier.")
            end
        end
        format.filetypes = aliases[spec[1]] or { spec[1] }
        lsp(s, spec[6], spec[7], spec[9])
        parser(s, spec[8])
        if spec[1] == "markdown" then
            local value = feature(s, "render", "Markdown rendering · Space dr", "Візуалізація Markdown · Пробіл dr", {}, ":Lazy sync; :TSInstall markdown markdown_inline")
            value.tools = vim.deepcopy(s.features[3].tools)
            value.status = s.features[3].status
            local lazy = package.loaded["lazy.core.config"]
            local plugin = lazy and lazy.plugins["render-markdown.nvim"]
            local installed = plugin and vim.fn.isdirectory(plugin.dir) == 1
            value.tools[#value.tools + 1] = { name = "render-markdown.nvim", path = installed and plugin.dir or nil,
                status = installed and "ok" or "no" }
            if not installed then value.status = "no" end
            value.note = text("Starts in raw mode; toggle explicitly. Availability inspection does not load the renderer.",
                "Починає з вихідного тексту; перемикається явно. Перевірка доступності не завантажує візуалізатор.")
        end
        if spec[1] == "html" or spec[1] == "css" or spec[1] == "javascript" or spec[1] == "typescript" then
            feature(s, "emmet", "Emmet expansion", "Розгортання Emmet", { "emmet-ls", "node" }, ":MasonInstall emmet-ls", false)
        end
    end
    local rust = section("rust", "Rust", "Rust")
    local rustformat = formatter(rust, "rustfmt", "rust", "Debian: sudo apt install cargo rustfmt")
    if vim.fs.root(context ~= "" and context or vim.fn.getcwd(), { "Cargo.toml" }) then
        local cargo = tool("cargo")
        rustformat.tools[#rustformat.tools + 1] = cargo
        if not cargo.path then rustformat.status = "no" end
    end
    rustformat.note = text("Cargo projects also need Cargo to resolve the edition. Standalone files use edition 2021 unless rustfmt.toml supplies it.",
        "Cargo-проєктам також потрібен Cargo для визначення edition. Окремі файли використовують edition 2021, якщо її не задано в rustfmt.toml.")
    native(rust, "lsp", "Completion, navigation, diagnostics", "Доповнення, переходи, діагностика",
        text("A Rust language server is not configured in this release; installing rust-analyzer alone does not enable it.",
            "Мовний сервер Rust у цій версії не налаштований; самого встановлення rust-analyzer недостатньо."), "off")

    local django = section("htmldjango", "Django HTML", "Django HTML")
    native(django, "format", "Formatting / indentation", "Форматування / відступи",
        text("External formatting is disabled to preserve template syntax. Use native = and gq.",
            "Зовнішнє форматування вимкнене для збереження синтаксису шаблонів. Використовуй вбудовані = та gq."))
    lsp(django, { "vscode-html-language-server", "emmet-ls" }, ":MasonInstall html-lsp emmet-ls", "node")
    parser(django, { "htmldjango" })
    local docker = section("dockerfile", "Dockerfile", "Dockerfile")
    native(docker, "format", "Indentation", "Відступи", text("Use native =.", "Використовуй вбудований =."))
    lsp(docker, { "docker-langserver" }, ":MasonInstall dockerfile-language-server", "node")
    parser(docker, { "dockerfile" })
    local sass = section("sass", "Sass", "Sass")
    native(sass, "format", "Indentation", "Відступи", text("Use native =; no external formatter is configured for indented Sass.",
        "Використовуй вбудований =; зовнішній форматер для Sass із відступами не налаштований."))
    local prose = section("prose", "TXT / reStructuredText / Markdown reading", "Читання TXT / reStructuredText / Markdown")
    native(prose, "wrap", "Soft wrapping and native reflow", "Екранне перенесення й вбудоване форматування",
        text("Soft wrapping preserves paragraphs; explicit gq reflows text. RST rendering is built in (Space dr).",
            "Екранне перенесення зберігає абзаци; явний gq переносить текст. Візуалізація RST вбудована (Пробіл dr)."))
    local other = section("native", "TOML / XML / INI / Make / Vim", "TOML / XML / INI / Make / Vim")
    native(other, "editing", "Native editing and indentation", "Вбудоване редагування й відступи",
        text("Native syntax and = / gq; external formatters and language servers are not configured for these filetypes.",
            "Вбудований синтаксис і = / gq; зовнішні форматери й мовні сервери для цих типів не налаштовані."))

    -- An attached LSP formatter is the actual fallback when no external command exists.
    for _, s in ipairs(report.sections) do
        for _, value in ipairs(s.features) do
            if value.id == "format" and value.filetypes and vim.tbl_contains(value.filetypes, report.filetype) and value.status == "no" then
                local available = 0
                for _, item in ipairs(value.tools) do
                    if item.path and vim.tbl_contains(value.commands or {}, item.name) then available = available + 1 end
                end
                if available == 0 then
                    local clients_with_formatting = vim.lsp.get_clients({ bufnr = buf, method = "textDocument/formatting" })
                    if #clients_with_formatting > 0 then
                        value.status = "ok"
                        value.note = text("Available through attached LSP formatter: " .. clients_with_formatting[1].name,
                            "Доступно через під'єднаний форматер LSP: " .. clients_with_formatting[1].name)
                    end
                end
            end
        end
    end
    local focus = ({ javascriptreact = "javascript", typescriptreact = "typescript", scss = "css", less = "css",
        jsonc = "json", bash = "sh", text = "prose", rst = "prose", toml = "native", xml = "native",
        dosini = "native", ini = "native", make = "native", vim = "native" })[report.filetype] or report.filetype
    local ordered = { report.sections[1] }
    for _, s in ipairs(report.sections) do if s.id == focus and s ~= ordered[1] then ordered[#ordered + 1] = s end end
    for i = 2, #report.sections do
        local s = report.sections[i]
        if s.id ~= focus then ordered[#ordered + 1] = s end
    end
    report.sections = ordered
    return report
end

return M
