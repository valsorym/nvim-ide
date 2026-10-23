-- Format in memory. External tools receive stdin and never overwrite the file.
local M = {}
local running = {}
local warned_formatter = false

local executable = require("config.tools").executable

local function commands(buf, only)
    local ft, path = vim.bo[buf].filetype, vim.api.nvim_buf_get_name(buf)
    local line_width = require("config.line-width")
    local width = tostring(line_width.width(buf) or line_width.default_width(buf))
    local result = {}
    local function configured(files)
        -- Only invoked on formatting; project configuration owns formatter policy.
        for parent in vim.fs.parents(path ~= "" and path or (vim.fn.getcwd() .. "/untitled")) do
            for name, section in pairs(files) do
                local file = parent .. "/" .. name
                if vim.fn.filereadable(file) == 1 then
                    if section == true then return true end
                    local contents = table.concat(vim.fn.readfile(file), "\n")
                    if contents:find(section) then return true end
                end
            end
        end
        return false
    end
    local function add(name, args)
        if only and only ~= name then return end
        local exe = executable(name, buf)
        if exe then table.insert(result, vim.list_extend({ exe }, args)) end
    end
    if ft == "python" then
        local ruff_config = configured({ ["ruff.toml"] = true, [".ruff.toml"] = true,
            ["pyproject.toml"] = "%[%s*tool%.ruff[%].%s]" })
        local formatter = vim.g.nvim_ide_python_formatter or "ruff"
        if formatter ~= "ruff" and formatter ~= "black" then
            if not warned_formatter then
                vim.notify("Python formatter must be ruff or black; using ruff", vim.log.levels.WARN)
                warned_formatter = true
            end
            formatter = "ruff"
        end
        local ruff = formatter == "ruff" and executable("ruff", buf)
        if ruff and only ~= "black" then
            if not only or only == "isort" then
                local args = { ruff, "check", "--select", "I", "--fix", "--exit-zero", "--stdin-filename", path, "-" }
                if not ruff_config then vim.list_extend(args, { "--line-length", width }) end
                result[#result + 1] = args
            end
            if not only then
                local args = { ruff, "format", "--stdin-filename", path, "-" }
                if not ruff_config then
                    vim.list_extend(args, { "--line-length", width, "--config", "format.quote-style='preserve'" })
                end
                result[#result + 1] = args
            end
        else
            local isort = { "--filename", path, "-" }
            if not configured({ [".isort.cfg"] = true, ["pyproject.toml"] = "%[%s*tool%.isort%s*%]",
                ["setup.cfg"] = "%[%s*isort%s*%]", ["tox.ini"] = "%[%s*isort%s*%]" }) then
                vim.list_extend(isort, { "--profile", "black", "--line-length", width })
            end
            add("isort", isort)
            local black = { "--stdin-filename", path, "-" }
            if not configured({ ["pyproject.toml"] = "%[%s*tool%.black%s*%]" }) then
                vim.list_extend(black, { "--line-length", width, "--skip-string-normalization" })
            end
            add("black", black)
        end
    elseif ft == "lua" then
        local args = { "--search-parent-directories", "--stdin-filepath", path, "-" }
        if not configured({ ["stylua.toml"] = true, [".stylua.toml"] = true }) then
            vim.list_extend(args, { "--column-width", width })
        end
        add("stylua", args)
    elseif vim.tbl_contains({ "javascript", "javascriptreact", "typescript", "typescriptreact", "vue",
        "json", "jsonc", "yaml", "html", "css", "scss", "less", "markdown" }, ft) then
        local args = { "--stdin-filepath", path }
        if ft == "markdown" then
            -- Preserve paragraph boundaries even when the project requests reflow.
            vim.list_extend(args, { "--prose-wrap", "preserve" })
        else
            vim.list_extend(args, { "--print-width", width, "--config-precedence", "prefer-file" })
        end
        add("prettier", args)
    elseif ft == "go" then
        add("gofmt", {})
    elseif ft == "rust" and executable("rustfmt", buf) then
        local args = { "--emit", "stdout" }
        local root = vim.fs.root(path ~= "" and path or vim.fn.getcwd(), { "Cargo.toml" })
        local config = configured({ ["rustfmt.toml"] = true, [".rustfmt.toml"] = true })
        if root then
            local cargo = executable("cargo", buf)
            if not cargo then return {}, "Cargo is required to determine the Rust edition" end
            -- Read package/workspace editions without fetching dependencies or writing a lockfile.
            local ok, metadata = pcall(function()
                local result = vim.system({ cargo, "metadata", "--no-deps", "--format-version", "1",
                    "--offline", "--frozen", "--manifest-path", root .. "/Cargo.toml" }, { text = true }):wait(1000)
                assert(result.code == 0, result.stderr)
                return vim.json.decode(result.stdout)
            end)
            if not ok then return {}, "Could not determine the Rust edition: " .. tostring(metadata) end
            local edition
            for _, package in ipairs(metadata.packages or {}) do
                if vim.fs.normalize(package.manifest_path) == vim.fs.normalize(root .. "/Cargo.toml") then
                    edition = package.edition
                    break
                end
            end
            if not edition then return {}, "Cargo metadata does not include the current Rust package" end
            vim.list_extend(args, { "--edition", edition })
        elseif not config then
            vim.list_extend(args, { "--edition", "2021" })
        end
        if not config then vim.list_extend(args, { "--config", "max_width=" .. width }) end
        add("rustfmt", args)
    elseif ft == "sh" or ft == "bash" then
        add("shfmt", { "-i", tostring(vim.bo[buf].expandtab and vim.bo[buf].shiftwidth or 0) })
    elseif ft == "c" or ft == "cpp" then
        local args = { "--assume-filename=" .. path }
        if not configured({ [".clang-format"] = true, ["_clang-format"] = true }) then
            vim.list_extend(args, { "--style={BasedOnStyle: LLVM, ColumnLimit: " .. width .. "}" })
        end
        add("clang-format", args)
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
    local pipeline, command_error = commands(buf, opts.only)
    if command_error then failed(command_error); return end
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
        -- Apply minimal hunks from the end so untouched lines keep marks and extmarks.
        local diff = vim.text and vim.text.diff or vim.diff
        local hunks = diff(input, output, { result_type = "indices" })
        for i = #hunks, 1, -1 do
            local old_start, old_count, new_start, new_count = unpack(hunks[i])
            local replacement = {}
            for row = new_start, new_start + new_count - 1 do replacement[#replacement + 1] = lines[row] end
            local first = old_count == 0 and old_start or old_start - 1
            vim.api.nvim_buf_call(buf, function()
                if i < #hunks then vim.cmd("undojoin") end
                vim.api.nvim_buf_set_lines(buf, first, first + old_count, false, replacement)
            end)
        end
        vim.bo[buf].endofline = output:sub(-1) == "\n"
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
            if not ok or result.code ~= 0 then failed(ok and (result.stderr ~= "" and result.stderr or "Formatter failed (exit " .. result.code .. ")") or tostring(result)); return end
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
        for _, name in ipairs({ "ruff", "black", "isort", "mypy", "flake8" }) do
            found[#found + 1] = name .. ": " .. (executable(name, 0) or "not installed")
        end
        vim.notify(table.concat(found, "\n"))
    end, { desc = "Show Python tools" })
end

return M
