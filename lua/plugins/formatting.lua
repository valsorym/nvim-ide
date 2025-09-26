-- ~/.config/nvim/lua/plugins/formatting.lua
-- Formatting and linting configuration (safe toggles).

return {
    "nvimtools/none-ls.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "jay-babu/mason-null-ls.nvim"
    },
    cmd = {
        -- "ToggleMyPy",  -- COMMENTED OUT
        "ToggleDjlint",
        "ToggleCodespell",
        "ToggleESLint",
        "ToggleFlake8",
        "PythonToolsStatus",
        "CreatePyprojectToml",
    },
    init = function()
        -- Set defaults silently without debug output.
        vim.g.enable_mypy = false
        vim.g.enable_djlint = false
        vim.g.enable_codespell = true
        vim.g.enable_eslint = false
        vim.g.enable_flake8 = false
    end,
    config = function()
        local null_ls = require("null-ls")

        -- FORCE DISABLE MYPY BUILTIN COMPLETELY
        if null_ls.builtins.diagnostics.mypy then
            null_ls.builtins.diagnostics.mypy = function()
                return nil  -- return nothing to disable completely
            end
        end

        -- Detect python executable in venv.
        local function get_python_executable()
            local venv = vim.fn.getenv("VIRTUAL_ENV")
            if venv ~= vim.NIL and venv ~= "" then
                return venv .. "/bin/python"
            end
            if vim.fn.isdirectory(".venv") == 1 then
                return vim.fn.getcwd() .. "/.venv/bin/python"
            end
            if vim.fn.isdirectory("venv") == 1 then
                return vim.fn.getcwd() .. "/venv/bin/python"
            end
            return "python3"
        end

        local sources = {
            -- Python formatting
            null_ls.builtins.formatting.black.with({
                condition = function()
                    local py = get_python_executable()
                    local exe = py:gsub("/python$", "/black")
                    return vim.fn.executable("black") == 1 or vim.fn.executable(exe) == 1
                end,
                command = function()
                    local py = get_python_executable()
                    local exe = py:gsub("/python$", "/black")
                    if vim.fn.executable(exe) == 1 then return exe end
                    return "black"
                end,
                extra_args = {
                    "--line-length", "79",
                    "--target-version", "py38",
                    "--skip-string-normalization"
                }
            }),

            null_ls.builtins.formatting.isort.with({
                condition = function()
                    local py = get_python_executable()
                    local exe = py:gsub("/python$", "/isort")
                    return vim.fn.executable("isort") == 1 or vim.fn.executable(exe) == 1
                end,
                command = function()
                    local py = get_python_executable()
                    local exe = py:gsub("/python$", "/isort")
                    if vim.fn.executable(exe) == 1 then return exe end
                    return "isort"
                end,
                extra_args = {
                    "--profile", "black",
                    "--line-length", "79",
                    "--multi-line", "3",
                    "--trailing-comma"
                }
            }),

            -- JS/TS/Vue/CSS/HTML
            null_ls.builtins.formatting.prettier.with({
                condition = function()
                    return vim.fn.executable("prettier") == 1
                end,
                filetypes = {
                    "javascript","typescript","vue","css","scss",
                    "html","json","yaml","markdown"
                },
                extra_args = {"--print-width", "79"}
            }),

            -- Lua
            null_ls.builtins.formatting.stylua.with({
                condition = function()
                    return vim.fn.executable("stylua") == 1
                end,
                extra_args = {"--column-width", "79"}
            }),

            -- Go
            null_ls.builtins.formatting.goimports.with({
                condition = function()
                    return vim.fn.executable("goimports") == 1
                end
            }),

            -- C/C++
            null_ls.builtins.formatting.clang_format.with({
                condition = function()
                    return vim.fn.executable("clang-format") == 1
                end,
                extra_args = {
                    "-style='{BasedOnStyle: llvm, ColumnLimit: 79}'"
                }
            }),
        }

        -- Codespell: safe default ON, runtime toggled by global.
        table.insert(sources, null_ls.builtins.diagnostics.codespell.with({
            condition = function()
                return vim.fn.executable("codespell") == 1
            end,
            runtime_condition = function(_)
                return vim.g.enable_codespell == true
            end
        }))

        -- Local mypy_registered = false.
        local djlint_registered = false

        local function get_project_root(bufnr)
            for _, c in ipairs(vim.lsp.get_clients({bufnr = bufnr})) do
                local rd = c.config and (c.config.root_dir or c.root_dir)
                if rd and rd ~= "" then return rd end
            end
            local ok, out = pcall(vim.fn.systemlist,
                "git rev-parse --show-toplevel 2>/dev/null")
            if ok and type(out) == "table" and out[1] and out[1] ~= "" then
                return out[1]
            end
            return vim.fn.getcwd()
        end

        -- COMMENTED OUT: MyPy functionality completely disabled.
        --[[
        local function build_mypy()
            return null_ls.builtins.diagnostics.mypy.with({
                condition = function()
                    -- Only register if tool exists at all
                    local py = get_python_executable()
                    local exe = py:gsub("/python$", "/mypy")
                    local ok = (vim.fn.executable("mypy") == 1) or
                            (vim.fn.executable(exe) == 1)
                    if not ok and vim.fn.filereadable("pyproject.toml") == 1
                    and not vim.g.mypy_warning_shown then
                        vim.g.mypy_warning_shown = true
                        vim.notify(
                            "MyPy not found. Install: pip install mypy",
                            vim.log.levels.WARN
                        )
                    end
                    return ok
                end,
                -- Per-run guard: OFF flag, and skip vendor/venv files
                runtime_condition = function(params)
                    if vim.g.enable_mypy ~= true then return false end
                    local bufnr = params.bufnr or 0
                    local name = vim.api.nvim_buf_get_name(bufnr)
                    if name == nil or name == "" then return false end

                    -- Skip all virtual environment and package files
                    if name:match("/site%-packages/") then return false end
                    if name:match("/%.venv/") then return false end
                    if name:match("/venv/") then return false end
                    if name:match("/lib/python") then return false end
                    if name:match("typing_extensions%.py") then return false end
                    if name:match("mypy_extensions%.py") then return false end

                    -- Only process files in project directory
                    local cwd = vim.fn.getcwd()
                    if not name:match("^" .. vim.pesc(cwd)) then
                        return false
                    end

                    return true
                end,
                -- Run from project root to respect local config
                cwd = function(params)
                    return get_project_root(params.bufnr or 0)
                end,
                command = function()
                    local py = get_python_executable()
                    local exe = py:gsub("/python$", "/mypy")
                    if vim.fn.executable(exe) == 1 then return exe end
                    return "mypy"
                end,
                extra_args = {
                    "--exclude",
                    "(^%.venv/|^venv/|site%-packages/|" ..
                    "lib/python.*/|typing_extensions%.py$|" ..
                    "mypy_extensions%.py$)"
                },
            })
        end
        --]]

        local function build_djlint()
            return null_ls.builtins.diagnostics.djlint.with({
                condition = function()
                    return vim.fn.executable("djlint") == 1
                end,
                runtime_condition = function(_)
                    return vim.g.enable_djlint == true
                end,
                filetypes = {"htmldjango","html","jinja","jinja2"},
                extra_args = {"--profile=django"},
            })
        end

        -- Helpers to register/disable by name.
        --[[
        local function ensure_mypy_registered()
            if not mypy_registered then
                null_ls.register(build_mypy())
                mypy_registered = true
            end
        end
        --]]
        local function ensure_djlint_registered()
            if not djlint_registered then
                null_ls.register(build_djlint())
                djlint_registered = true
            end
        end
        local function safe_disable(name)
            if null_ls.disable then
                pcall(null_ls.disable, { name = name })
            end
        end

        -- Initial setup: do NOT add mypy/djlint unless enabled.
        null_ls.setup({
            sources = sources,
            on_attach = function(client, bufnr)
                if client:supports_method("textDocument/formatting") then
                    local grp = vim.api.nvim_create_augroup(
                        "LspFormatting", {clear = false}
                    )
                    vim.api.nvim_clear_autocmds({
                        group = grp, buffer = bufnr
                    })
                    vim.api.nvim_create_autocmd("BufWritePre", {
                        group = grp,
                        buffer = bufnr,
                        callback = function()
                            if vim.g.format_on_save then
                                vim.lsp.buf.format({
                                    filter = function(c)
                                        return c.name == "null-ls"
                                    end,
                                    bufnr = bufnr
                                })
                            end
                        end
                    })
                end
            end
        })

        -- IMPORTANT: DO NOT register mypy automatically at startup!
        -- Check that mypy is really disabled.
        --[[
        if vim.g.enable_mypy == true then
            vim.notify("WARNING: MyPy enabled at startup - disabling",
                vim.log.levels.WARN)
            vim.g.enable_mypy = false
        end
        --]]

        -- Manual format.
        vim.keymap.set(
            "n", "<leader>df",
            function() vim.lsp.buf.format({async = true}) end,
            {desc = "· Format document"}
        )

        -- Toggle format on save.
        vim.g.format_on_save = true
        vim.keymap.set(
            "n", "<leader>xf",
            function()
                vim.g.format_on_save = not vim.g.format_on_save
                print("Format on save: " ..
                    (vim.g.format_on_save and "ON" or "OFF"))
            end,
            {desc = "· Toggle format on save"}
        )

        -- Sort Python imports.
        vim.keymap.set(
            "n", "<leader>ci",
            function()
                vim.cmd("write")
                local py = get_python_executable()
                local exe = py:gsub("/python$", "/isort")
                local args = table.concat({
                    "--profile","black","--line-length","79",
                    "--multi-line","3","--trailing-comma"
                }, " ")
                if vim.fn.executable(exe) == 1 then
                    vim.cmd("!" .. exe .. " " .. args .. " %")
                else
                    vim.cmd("!isort " .. args .. " %")
                end
                vim.cmd("edit!")
            end,
            {desc = "· Sort Python Imports"}
        )

        -- Create pyproject.toml.
        vim.api.nvim_create_user_command(
            "CreatePyprojectToml",
            function()
                local txt = [[
[tool.black]
line-length = 79
target-version = ['py38']
skip-string-normalization = true

[tool.isort]
profile = "black"
line_length = 79
multi_line_output = 3
include_trailing_comma = true
force_grid_wrap = 0
use_parentheses = true
ensure_newline_before_comments = true

[tool.mypy]
python_version = "3.8"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = false
check_untyped_defs = true
exclude = "(^\\.venv/|site-packages/|typing_extensions\\.py$|"
.. "mypy_extensions\\.py$)"
]]
                if vim.fn.filereadable("pyproject.toml") == 1 then
                    print("pyproject.toml already exists.")
                    print("Recommended settings:")
                    print(txt)
                else
                    local f = io.open("pyproject.toml", "w")
                    if f then
                        f:write(txt)
                        f:close()
                        print("Created pyproject.toml")
                    else
                        print("Error: Could not create pyproject.toml")
                    end
                end
            end,
            {desc = "Create pyproject.toml with 79-char settings"}
        )

        -- Tools status.
        vim.api.nvim_create_user_command(
            "PythonToolsStatus",
            function()
                local py = get_python_executable()
                print("Python executable: " .. py)
                local tools = {"black","isort","mypy","codespell","djlint"}
                for _, t in ipairs(tools) do
                    local exe = py:gsub("/python$", "/" .. t)
                    local ok = (vim.fn.executable(t) == 1) or
                               (vim.fn.executable(exe) == 1)
                    print(t .. ": " ..
                        (ok and "✓ available" or "✗ not found"))
                end
                local has_pp = (vim.fn.filereadable("pyproject.toml")==1)
                print("pyproject.toml: " .. (has_pp and "✓ exists" or "✗"))
            end,
            {desc = "Check status of Python tools"}
        )

        -- Runtime toggles with dynamic register/disable.
        local function refresh_diags()
            pcall(vim.diagnostic.reset, nil, 0)
            vim.defer_fn(function()
                pcall(vim.lsp.buf.clear_references)
            end, 10)
        end

        -- COMMENTED OUT: MyPy toggle command completely disabled
        --[[
        vim.api.nvim_create_user_command(
            "ToggleMyPy",
            function()
                local sources_mod = require("null-ls.sources")

                -- Debug info
                print("Current mypy state before toggle:", vim.g.enable_mypy)

                vim.g.enable_mypy = not vim.g.enable_mypy
                if vim.g.enable_mypy then
                    print("Registering mypy...")
                    ensure_mypy_registered()
                else
                    print("Disabling mypy...")
                    pcall(sources_mod.disable, { name = "mypy" })
                    mypy_registered = false
                end
                print("mypy: " .. (vim.g.enable_mypy and "ON" or "OFF"))
                pcall(vim.diagnostic.reset, nil, 0)
            end,
            {desc = "Toggle null-ls mypy diagnostics"}
        )
        --]]

        vim.api.nvim_create_user_command(
            "ToggleDjlint",
            function()
                vim.g.enable_djlint = not vim.g.enable_djlint
                if vim.g.enable_djlint then
                    ensure_djlint_registered()
                else
                    safe_disable("djlint")
                end
                print("djlint: " ..
                    (vim.g.enable_djlint and "ON" or "OFF"))
                refresh_diags()
            end,
            {desc = "Toggle null-ls djlint diagnostics"}
        )

        vim.api.nvim_create_user_command(
            "ToggleCodespell",
            function()
                vim.g.enable_codespell = not vim.g.enable_codespell
                print("codespell: " ..
                    (vim.g.enable_codespell and "ON" or "OFF"))
                refresh_diags()
            end,
            {desc = "Toggle null-ls codespell diagnostics"}
        )

        -- ESLint/Flake8 placeholders (no builtin registered here).
        vim.api.nvim_create_user_command(
            "ToggleESLint",
            function()
                vim.g.enable_eslint = not vim.g.enable_eslint
                print("eslint: " ..
                    (vim.g.enable_eslint and "ON" or "OFF") ..
                    " (no provider registered)")
            end,
            {desc = "Toggle ESLint diagnostics (placeholder)"}
        )

        vim.api.nvim_create_user_command(
            "ToggleFlake8",
            function()
                vim.g.enable_flake8 = not vim.g.enable_flake8
                print("flake8: " ..
                    (vim.g.enable_flake8 and "ON" or "OFF") ..
                    " (no provider registered)")
            end,
            {desc = "Toggle Flake8/Ruff diagnostics (placeholder)"}
        )

        -- Checking the status of formatters.
        vim.api.nvim_create_user_command(
            "CheckFormatters",
            function()
                local tools = {"black", "isort", "prettier", "stylua", "goimports", "clang-format"}
                print("Formatter status:")
                for _, tool in ipairs(tools) do
                    local available = vim.fn.executable(tool) == 1
                    print(tool .. ": " .. (available and "✓ available" or "✗ not found"))
                end
            end,
            {desc = "Check status of formatting tools"}
        )
    end
}