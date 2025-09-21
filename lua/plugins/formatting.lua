-- ~/.config/nvim/lua/plugins/formatting.lua
-- Formatting and linting configuration.

return {
    "nvimtools/none-ls.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "jay-babu/mason-null-ls.nvim"
    },
    cmd = {
        "ToggleMyPy",
        "ToggleDjlint",
        "ToggleCodespell",
        "ToggleESLint",
        "ToggleFlake8",
        "PythonToolsStatus",
        "CreatePyprojectToml",
    },
    config = function()
        local null_ls = require("null-ls")

        -- Runtime toggles defaults
        if vim.g.enable_mypy == nil then vim.g.enable_mypy = false end
        if vim.g.enable_djlint == nil then vim.g.enable_djlint = false end
        if vim.g.enable_codespell == nil then vim.g.enable_codespell = true end
        if vim.g.enable_eslint == nil then vim.g.enable_eslint = false end
        if vim.g.enable_flake8 == nil then vim.g.enable_flake8 = false end

        -- We keep provider flag for future, but do not register flake8/ruff
        vim.g._flake8_provider = nil

        -- Detect python executable within venvs
        local function get_python_executable()
            local venv_path = vim.fn.getenv("VIRTUAL_ENV")
            if venv_path ~= vim.NIL and venv_path ~= "" then
                return venv_path .. "/bin/python"
            end
            if vim.fn.isdirectory(".venv") == 1 then
                return vim.fn.getcwd() .. "/.venv/bin/python"
            end
            if vim.fn.isdirectory("venv") == 1 then
                return vim.fn.getcwd() .. "/venv/bin/python"
            end
            return "python3"
        end

        -- Base sources (safe only)
        local sources = {
            -- Python formatting
            null_ls.builtins.formatting.black.with({
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
                filetypes = {
                    "javascript","typescript","vue","css","scss",
                    "html","json","yaml","markdown"
                },
                extra_args = {"--print-width", "79"}
            }),

            -- Lua
            null_ls.builtins.formatting.stylua.with({
                extra_args = {"--column-width", "79"}
            }),

            -- Go
            null_ls.builtins.formatting.goimports,

            -- C/C++
            null_ls.builtins.formatting.clang_format.with({
                extra_args = {
                    "-style='{BasedOnStyle: llvm, ColumnLimit: 79}'"
                }
            }),
        }

        -- Codespell (safe by default)
        table.insert(sources, null_ls.builtins.diagnostics.codespell.with({
            condition = function() return vim.fn.executable("codespell") == 1 end,
            runtime_condition = function(_) return vim.g.enable_codespell end
        }))

        -- MyPy (runtime toggle)
        table.insert(sources, null_ls.builtins.diagnostics.mypy.with({
            condition = function()
                local py = get_python_executable()
                local exe = py:gsub("/python$", "/mypy")
                local ok = (vim.fn.executable("mypy") == 1) or
                        (vim.fn.executable(exe) == 1)
                if not ok and vim.fn.filereadable("pyproject.toml") == 1 and
                not vim.g.mypy_warning_shown then
                    vim.g.mypy_warning_shown = true
                    vim.notify(
                        "MyPy not found. Install: pip install mypy",
                        vim.log.levels.WARN
                    )
                end
                return ok
            end,
            runtime_condition = function(_) return vim.g.enable_mypy end,
            command = function()
                local py = get_python_executable()
                local exe = py:gsub("/python$", "/mypy")
                if vim.fn.executable(exe) == 1 then return exe end
                return "mypy"
            end,
            extra_args = {
                "--exclude",
                "(^%.venv/|site%-packages/|typing_extensions%.py$|" ..
                "mypy_extensions%.py$)"
            },
        }))

        -- djlint (runtime toggle)
        table.insert(sources, null_ls.builtins.diagnostics.djlint.with({
            condition = function() return vim.fn.executable("djlint") == 1 end,
            runtime_condition = function(_) return vim.g.enable_djlint end,
            filetypes = {"htmldjango","html","jinja","jinja2"},
            extra_args = {"--profile=django"},
        }))

        -- NOTE: ESLint and Flake8/Ruff are NOT registered here to avoid
        -- "failed to load builtin ..." errors on older none-ls versions.
        -- We keep toggles/which-key, and print status to the user.

        null_ls.setup({
            sources = sources,
            on_attach = function(client, bufnr)
                if client:supports_method("textDocument/formatting") then
                    local grp = vim.api.nvim_create_augroup(
                        "LspFormatting", {clear = false}
                    )
                    vim.api.nvim_clear_autocmds({group = grp, buffer = bufnr})
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

        -- Manual format
        vim.keymap.set(
            "n", "<leader>F",
            function() vim.lsp.buf.format({async = true}) end,
            {desc = "Format document"}
        )

        -- Toggle format on save
        vim.g.format_on_save = true
        vim.keymap.set(
            "n", "<leader>tf",
            function()
                vim.g.format_on_save = not vim.g.format_on_save
                print(
                    "Format on save: " ..
                    (vim.g.format_on_save and "ON" or "OFF")
                )
            end,
            {desc = "Toggle format on save"}
        )

        -- Sort Python imports
        vim.keymap.set(
            "n", "<leader>is",
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
            {desc = "Sort Python imports"}
        )

        -- Create pyproject.toml (unchanged)
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
exclude = "(^\\.venv/|site-packages/|typing_extensions\\.py$|" ..
"mypy_extensions\\.py$)"
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

        -- Tools status
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
                    print(t .. ": " .. (ok and "✓ available" or "✗ not found"))
                end
                local has_pp = vim.fn.filereadable("pyproject.toml") == 1
                print("pyproject.toml: " .. (has_pp and "✓ exists" or "✗"))
                local prov = vim.g._flake8_provider or "none"
                print("flake8 provider: " .. prov)
            end,
            {desc = "Check status of Python tools"}
        )

        -- Runtime toggles (no-op for flake8/eslint until provider added)
        local function refresh_diags()
            pcall(vim.diagnostic.reset, nil, 0)
            vim.defer_fn(function()
                pcall(vim.lsp.buf.clear_references)
            end, 10)
        end

        vim.api.nvim_create_user_command(
            "ToggleMyPy",
            function()
                vim.g.enable_mypy = not vim.g.enable_mypy
                print("mypy: " .. (vim.g.enable_mypy and "ON" or "OFF"))
                refresh_diags()
            end,
            {desc = "Toggle null-ls mypy diagnostics"}
        )

        vim.api.nvim_create_user_command(
            "ToggleDjlint",
            function()
                vim.g.enable_djlint = not vim.g.enable_djlint
                print("djlint: " .. (vim.g.enable_djlint and "ON" or "OFF"))
                refresh_diags()
            end,
            {desc = "Toggle null-ls djlint diagnostics"}
        )

        vim.api.nvim_create_user_command(
            "ToggleCodespell",
            function()
                vim.g.enable_codespell = not vim.g.enable_codespell
                print(
                    "codespell: " ..
                    (vim.g.enable_codespell and "ON" or "OFF")
                )
                refresh_diags()
            end,
            {desc = "Toggle null-ls codespell diagnostics"}
        )

        vim.api.nvim_create_user_command(
            "ToggleESLint",
            function()
                vim.g.enable_eslint = not vim.g.enable_eslint
                local s = (vim.g.enable_eslint and "ON" or "OFF")
                print("eslint: " .. s .. " (no provider registered)")
            end,
            {desc = "Toggle null-ls ESLint diagnostics (no-op if none)"}
        )

        vim.api.nvim_create_user_command(
            "ToggleFlake8",
            function()
                vim.g.enable_flake8 = not vim.g.enable_flake8
                local s = (vim.g.enable_flake8 and "ON" or "OFF")
                local prov = vim.g._flake8_provider or "none"
                print("flake8: " .. s .. " (provider: " .. prov .. ")")
            end,
            {desc = "Toggle Flake8/Ruff diagnostics (no-op if none)"}
        )
    end
}
