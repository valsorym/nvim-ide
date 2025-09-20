-- ~/.config/nvim/lua/plugins/formatting.lua
-- Formatting and linting configuration.

return {
    "nvimtools/none-ls.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "jay-babu/mason-null-ls.nvim"
    },
    config = function()
        local null_ls = require("null-ls")

        -- Python virtual environment detection.
        local function get_python_executable()
            local venv_path = vim.fn.getenv("VIRTUAL_ENV")
            if venv_path ~= vim.NIL and venv_path ~= "" then
                return venv_path .. "/bin/python"
            end

            -- Check for .venv directory.
            if vim.fn.isdirectory(".venv") == 1 then
                return vim.fn.getcwd() .. "/.venv/bin/python"
            end

            -- Check for venv directory.
            if vim.fn.isdirectory("venv") == 1 then
                return vim.fn.getcwd() .. "/venv/bin/python"
            end

            return "python3"
        end

        null_ls.setup({
            sources = {
                -- Python formatting with consistent line length.
                null_ls.builtins.formatting.black.with({
                    command = function()
                        local python_path = get_python_executable()
                        local black_cmd = python_path:gsub("/python$", "/black")
                        if vim.fn.executable(black_cmd) == 1 then
                            return black_cmd
                        end
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
                        local python_path = get_python_executable()
                        local isort_cmd = python_path:gsub("/python$", "/isort")
                        if vim.fn.executable(isort_cmd) == 1 then
                            return isort_cmd
                        end
                        return "isort"
                    end,
                    extra_args = {
                        "--profile", "black",
                        "--line-length", "79",
                        "--multi-line", "3",
                        "--trailing-comma"
                    }
                }),

                -- MyPy with conditional loading
                null_ls.builtins.diagnostics.mypy.with({
                    condition = function()
                        -- Check if mypy is installed
                        local python_path = get_python_executable()
                        local mypy_cmd = python_path:gsub("/python$", "/mypy")
                        local mypy_available = vim.fn.executable("mypy") == 1 or vim.fn.executable(mypy_cmd) == 1

                        if mypy_available then
                            return true
                        end

                        -- If mypy not available but pyproject.toml exists - show warning once
                        if vim.fn.filereadable("pyproject.toml") == 1 then
                            -- Use a flag to show warning only once per session
                            if not vim.g.mypy_warning_shown then
                                vim.g.mypy_warning_shown = true
                                vim.notify("MyPy not found but pyproject.toml exists. Install: pip install mypy",
                                    vim.log.levels.WARN)
                            end
                            return false
                        end

                        -- No mypy and no pyproject.toml - silently ignore
                        return false
                    end,
                    command = function()
                        local python_path = get_python_executable()
                        local mypy_cmd = python_path:gsub("/python$", "/mypy")
                        if vim.fn.executable(mypy_cmd) == 1 then
                            return mypy_cmd
                        end
                        return "mypy"
                    end,
                }),

                -- Codespell with conditional loading
                null_ls.builtins.diagnostics.codespell.with({
                    condition = function()
                        return vim.fn.executable("codespell") == 1
                    end,
                }),

                -- JavaScript/TypeScript/Vue/CSS/HTML.
                null_ls.builtins.formatting.prettier.with({
                    filetypes = {
                        "javascript",
                        "typescript",
                        "vue",
                        "css",
                        "scss",
                        "html",
                        "json",
                        "yaml",
                        "markdown"
                    },
                    extra_args = {"--print-width", "79"}
                }),

                -- Lua.
                null_ls.builtins.formatting.stylua.with({
                    extra_args = {"--column-width", "79"}
                }),

                -- Go (goimports includes gofmt functionality).
                null_ls.builtins.formatting.goimports,

                -- C/C++.
                null_ls.builtins.formatting.clang_format.with({
                    extra_args = {"-style='{BasedOnStyle: llvm, ColumnLimit: 79}'"}
                })
            },

            -- Format on save.
            on_attach = function(client, bufnr)
                if client:supports_method("textDocument/formatting") then
                    local augroup = vim.api.nvim_create_augroup("LspFormatting", {clear = false})
                    vim.api.nvim_clear_autocmds({group = augroup, buffer = bufnr})
                    vim.api.nvim_create_autocmd("BufWritePre", {
                        group = augroup,
                        buffer = bufnr,
                        callback = function()
                            if vim.g.format_on_save then
                                vim.lsp.buf.format({
                                    filter = function(client)
                                        -- Use null-ls for formatting when available
                                        return client.name == "null-ls"
                                    end,
                                    bufnr = bufnr
                                })
                            end
                        end
                    })
                end
            end
        })

        -- Manual format command.
        vim.keymap.set("n", "<leader>F", function()
            vim.lsp.buf.format({async = true})
        end, {desc = "Format document"})

        -- Toggle format on save.
        vim.g.format_on_save = true
        vim.keymap.set("n", "<leader>tf", function()
            vim.g.format_on_save = not vim.g.format_on_save
            print("Format on save: " .. (vim.g.format_on_save and "ON" or "OFF"))
        end, {desc = "Toggle format on save"})

        -- Sort Python imports manually
        vim.keymap.set("n", "<leader>is", function()
            vim.cmd("write")
            local python_path = get_python_executable()
            local isort_cmd = python_path:gsub("/python$", "/isort")
            local args = "--profile black --line-length 79 --multi-line 3 --trailing-comma"

            if vim.fn.executable(isort_cmd) == 1 then
                vim.cmd("!" .. isort_cmd .. " " .. args .. " %")
            else
                vim.cmd("!isort " .. args .. " %")
            end
            vim.cmd("edit!")
        end, {desc = "Sort Python imports"})

        -- Create pyproject.toml configuration command
        vim.api.nvim_create_user_command("CreatePyprojectToml", function()
            local pyproject_content = [[
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
]]

            -- Check if pyproject.toml exists
            if vim.fn.filereadable("pyproject.toml") == 1 then
                print("pyproject.toml already exists. Please check and update manually.")
                print("Recommended settings for 79-character line length:")
                print(pyproject_content)
            else
                -- Create pyproject.toml
                local file = io.open("pyproject.toml", "w")
                if file then
                    file:write(pyproject_content)
                    file:close()
                    print("Created pyproject.toml with 79-character line length settings")
                    print("To use mypy: pip install mypy")
                else
                    print("Error: Could not create pyproject.toml")
                end
            end
        end, {desc = "Create pyproject.toml with 79-char line length settings"})

        -- Command to check Python tools status
        vim.api.nvim_create_user_command("PythonToolsStatus", function()
            local python_path = get_python_executable()
            print("Python executable: " .. python_path)

            local tools = {"black", "isort", "mypy", "codespell"}
            for _, tool in ipairs(tools) do
                local cmd = python_path:gsub("/python$", "/" .. tool)
                local available = vim.fn.executable(tool) == 1 or vim.fn.executable(cmd) == 1
                print(tool .. ": " .. (available and "✓ available" or "✗ not found"))
            end

            local pyproject_exists = vim.fn.filereadable("pyproject.toml") == 1
            print("pyproject.toml: " .. (pyproject_exists and "✓ exists" or "✗ not found"))
        end, {desc = "Check status of Python development tools"})
    end
}