-- Format in memory. External tools receive stdin and never overwrite the file.
local M = {}
local running = {}

local function executable(name, buf)
    local path = vim.api.nvim_buf_get_name(buf)
    if vim.bo[buf].filetype == "python" then
        local python = require("config.python-venv").python(path)
        local candidate = vim.fs.dirname(python) .. "/" .. name
        if vim.fn.executable(candidate) == 1 then return candidate end
    end
    local root = vim.fs.root(path, { "package.json", ".git" })
    if root and vim.fn.executable(root .. "/node_modules/.bin/" .. name) == 1 then
        return root .. "/node_modules/.bin/" .. name
    end
    return vim.fn.executable(name) == 1 and name or nil
end

local function commands(buf, only)
    local ft, path = vim.bo[buf].filetype, vim.api.nvim_buf_get_name(buf)
    local result = {}
    local function add(name, args)
        if only and only ~= name then return end
        local exe = executable(name, buf)
        if exe then table.insert(result, vim.list_extend({ exe }, args)) end
    end
    if ft == "python" then
        add("isort", { "--profile", "black", "--line-length", "79", "--filename", path, "-" })
        add("black", { "--line-length", "79", "--skip-string-normalization", "--stdin-filename", path, "-" })
    elseif ft == "lua" then
        add("stylua", { "--column-width", "79", "--stdin-filepath", path, "-" })
    elseif vim.tbl_contains({ "javascript", "javascriptreact", "typescript", "typescriptreact", "vue",
        "json", "jsonc", "yaml", "html", "css", "scss", "less", "markdown" }, ft) then
        add("prettier", { "--stdin-filepath", path, "--print-width", "79" })
    elseif ft == "go" then
        add("gofmt", {})
    elseif ft == "sh" or ft == "bash" then
        add("shfmt", { "-i", tostring(vim.bo[buf].expandtab and vim.bo[buf].shiftwidth or 0) })
    elseif ft == "c" or ft == "cpp" then
        add("clang-format", { "--assume-filename=" .. path })
    end
    return result
end

function M.format(opts)
    opts = opts or {}
    local buf = opts.buf or vim.api.nvim_get_current_buf()
    if vim.bo[buf].buftype ~= "" or not vim.bo[buf].modifiable or vim.bo[buf].readonly then return end
    if require("config.performance").is_large(buf) then
        if not opts.quiet then vim.notify("Formatting is disabled for large files", vim.log.levels.WARN) end
        return
    end
    -- HTML formatters cannot safely rewrite Django template syntax.
    if vim.bo[buf].filetype == "htmldjango" then
        if not opts.quiet then vim.notify("Django templates use native = and gq; external formatting is disabled") end
        return
    end
    if running[buf] then return end
    local tick = vim.api.nvim_buf_get_changedtick(buf)
    local function unchanged()
        return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modifiable
            and vim.api.nvim_buf_get_changedtick(buf) == tick
    end
    local function failed(message)
        running[buf] = nil
        vim.notify(message, vim.log.levels.ERROR)
    end
    local pipeline = commands(buf, opts.only)
    if #pipeline == 0 then
        if opts.only then failed("Formatter not found: " .. opts.only); return end
        local client = vim.lsp.get_clients({ bufnr = buf, method = "textDocument/formatting" })[1]
        if not client then
            if not opts.quiet then vim.notify("No formatter available for " .. vim.bo[buf].filetype, vim.log.levels.WARN) end
            return
        end
        local params = { textDocument = vim.lsp.util.make_text_document_params(buf),
            options = { tabSize = vim.bo[buf].shiftwidth, insertSpaces = vim.bo[buf].expandtab } }
        local function apply(err, edits)
            running[buf] = nil
            if err then failed(err.message or tostring(err)); return end
            if unchanged() and edits then vim.lsp.util.apply_text_edits(edits, buf, client.offset_encoding) end
        end
        if opts.async == false then
            local response, err = client:request_sync("textDocument/formatting", params, opts.timeout_ms or 1500, buf)
            if response then apply(response.err, response.result) else failed(tostring(err)) end
        else
            running[buf] = true
            local ok = client:request("textDocument/formatting", params, apply, buf)
            if not ok then failed("Could not request formatting") end
        end
        return
    end
    local input = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
        .. (vim.bo[buf].endofline and "\n" or "")
    local function apply(output)
        running[buf] = nil
        if not unchanged() then
            vim.notify("Formatting skipped: buffer changed while the formatter was running", vim.log.levels.WARN)
            return
        end
        if output == input then return end
        local lines = vim.split(output, "\n", { plain = true })
        if lines[#lines] == "" then table.remove(lines) end
        if #lines == 0 then lines = { "" } end
        local views = {}
        for _, win in ipairs(vim.fn.win_findbuf(buf)) do
            views[win] = vim.api.nvim_win_call(win, vim.fn.winsaveview)
        end
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        for win, view in pairs(views) do
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_call(win, function() vim.fn.winrestview(view) end)
            end
        end
    end
    running[buf] = true
    local cwd = vim.fs.dirname(vim.api.nvim_buf_get_name(buf))
    local timeout = opts.timeout_ms or 1500
    if opts.async == false then
        local output = input
        for _, cmd in ipairs(pipeline) do
            local ok, result = pcall(function()
                return vim.system(cmd, { stdin = output, text = true, cwd = cwd }):wait(timeout)
            end)
            if not ok or result.code ~= 0 then failed(ok and result.stderr or tostring(result)); return end
            output = result.stdout
        end
        apply(output)
    else
        local function step(i, output)
            if i > #pipeline then apply(output); return end
            local ok, err = pcall(vim.system, pipeline[i],
                { stdin = output, text = true, cwd = cwd, timeout = 10000 },
                vim.schedule_wrap(function(result)
                    if result.code ~= 0 then failed(result.stderr ~= "" and result.stderr or "Formatter failed"); return end
                    if not unchanged() then apply(output); return end
                    step(i + 1, result.stdout)
                end))
            if not ok then failed(tostring(err)) end
        end
        step(1, input)
    end
end

function M.trim()
    local view = vim.fn.winsaveview()
    -- Keep the search register and jump list intact.
    vim.cmd([[keepjumps keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
end

function M.setup()
    local group = vim.api.nvim_create_augroup("FormatOnSave", { clear = true })
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = group,
        callback = function(args)
            if vim.g.format_on_save and vim.b[args.buf].autoformat ~= false then
                M.format({ buf = args.buf, async = false, quiet = true })
            end
        end,
    })
    vim.api.nvim_create_user_command("Format", function() M.format() end, { desc = "Format current buffer" })
    vim.api.nvim_create_user_command("FormatToggle", function()
        vim.g.format_on_save = not vim.g.format_on_save
        vim.notify("Format on save: " .. (vim.g.format_on_save and "on" or "off"))
    end, { desc = "Toggle formatting before saving" })
    vim.api.nvim_create_user_command("PythonToolsStatus", function()
        local found = {}
        for _, name in ipairs({ "black", "isort", "mypy", "flake8" }) do
            found[#found + 1] = name .. ": " .. (executable(name, 0) or "not installed")
        end
        vim.notify(table.concat(found, "\n"))
    end, { desc = "Show Python tools" })
end

return M
