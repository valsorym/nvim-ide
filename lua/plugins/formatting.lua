-- ~/.config/nvim/lua/plugins/formatting.lua
-- Clean version: simple error handling, no blocking messages.

return {
    "nvimtools/none-ls.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "jay-babu/mason-null-ls.nvim"
    },
    cmd = {
        "PythonToolsStatus",
        "CreatePyprojectToml",
        "InstallPythonTools",
    },
    config = function()
        -- Get python executable.
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

        -- Settings.
        vim.g.format_on_save = false

        vim.keymap.set("n", "<leader>xf", function()
            vim.g.format_on_save = not vim.g.format_on_save
            vim.notify("Format on save: " .. (vim.g.format_on_save and "ON" or "OFF"), vim.log.levels.INFO)
        end, {desc = "Toggle format on save"})

        -- isort - clean and simple.
        vim.keymap.set("n", "<leader>ci", function()
            if vim.bo.filetype ~= "python" then
                vim.notify("🚫 Not a Python file", vim.log.levels.WARN)
                return
            end

            if vim.bo.modified then vim.cmd("silent write") end

            local py = get_python_executable()
            local exe = py:gsub("/python$", "/isort")
            local current_file = vim.fn.expand("%:p")

            local isort_cmd = vim.fn.executable(exe) == 1 and exe or "isort"
            if vim.fn.executable(isort_cmd) == 0 then
                vim.notify("🚫 isort not found", vim.log.levels.WARN)
                return
            end

            vim.notify("🔄 Sorting imports...", vim.log.levels.INFO)

            local cursor_pos = vim.api.nvim_win_get_cursor(0)
            local result = vim.fn.system({
                isort_cmd, "--profile", "black", "--line-length", "79",
                "--multi-line", "3", "--trailing-comma", current_file
            })

            if vim.v.shell_error == 0 then
                vim.cmd("silent! edit!")
                pcall(vim.api.nvim_win_set_cursor, 0, cursor_pos)
                vim.notify("📝 Imports sorted", vim.log.levels.INFO)
            else
                vim.notify("❌ isort failed", vim.log.levels.ERROR)
            end
        end, {desc = "Sort Python imports", silent = true})


        -- 🖤 Black - clean with syntax error detection.
        vim.keymap.set("n", "<leader>cb", function()
            if vim.bo.filetype ~= "python" then
                vim.notify("🚫 Not a Python file", vim.log.levels.WARN)
                return
            end

            if vim.bo.modified then vim.cmd("silent write") end

            local py = get_python_executable()
            local exe = py:gsub("/python$", "/black")
            local current_file = vim.fn.expand("%:p")

            local black_cmd = vim.fn.executable(exe) == 1 and exe or "black"
            if vim.fn.executable(black_cmd) == 0 then
                vim.notify("🚫 black not found", vim.log.levels.WARN)
                return
            end

            vim.notify("🔄 Formatting code...", vim.log.levels.INFO)

            local cursor_pos = vim.api.nvim_win_get_cursor(0)
            local result = vim.fn.system({
                black_cmd, "--line-length", "79", "--skip-string-normalization", current_file
            })

            if vim.v.shell_error == 0 then
                vim.cmd("silent! edit!")
                pcall(vim.api.nvim_win_set_cursor, 0, cursor_pos)
                vim.notify("🖤 Code formatted", vim.log.levels.INFO)
            else
                -- Check if it's a syntax error and extract line number
                if result:match("Cannot parse") or result:match("SyntaxError") then
                    local line_number = result:match(": (%d+):")
                    if line_number then
                        vim.notify("❌ Syntax error on line " .. line_number .. " - fix it first", vim.log.levels.ERROR)
                        -- Jump to the error line
                        pcall(vim.api.nvim_win_set_cursor, 0, {tonumber(line_number), 0})
                    else
                        vim.notify("❌ Code has syntax errors - fix them first", vim.log.levels.ERROR)
                    end
                else
                    vim.notify("❌ black failed", vim.log.levels.ERROR)
                end
            end
        end, {desc = "Format Python code", silent = true})

        -- Manual format for different languages.
        vim.keymap.set("n", "<leader>df", function()
            local ft = vim.bo.filetype
            if ft == "python" then
                -- For Python: run both isort and black.
                if vim.bo.modified then vim.cmd("silent write") end

                local py = get_python_executable()
                local current_file = vim.fn.expand("%:p")
                local cursor_pos = vim.api.nvim_win_get_cursor(0)

                -- Step 1: Sort imports with isort.
                local isort_exe = py:gsub("/python$", "/isort")
                local isort_cmd = vim.fn.executable(isort_exe) == 1 and isort_exe or "isort"

                if vim.fn.executable(isort_cmd) == 1 then
                    vim.notify("🔄 Sorting imports + formatting code...", vim.log.levels.INFO)

                    local isort_result = vim.fn.system({
                        isort_cmd, "--profile", "black", "--line-length", "79",
                        "--multi-line", "3", "--trailing-comma", current_file
                    })

                    if vim.v.shell_error ~= 0 then
                        vim.notify("❌ isort failed", vim.log.levels.ERROR)
                        return
                    end
                end

                -- Step 2: Format with black.
                local black_exe = py:gsub("/python$", "/black")
                local black_cmd = vim.fn.executable(black_exe) == 1 and black_exe or "black"

                if vim.fn.executable(black_cmd) == 1 then
                    local black_result = vim.fn.system({
                        black_cmd, "--line-length", "79", "--skip-string-normalization", current_file
                    })

                    if vim.v.shell_error == 0 then
                        vim.cmd("silent! edit!")
                        pcall(vim.api.nvim_win_set_cursor, 0, cursor_pos)
                        vim.notify("✅ Python code: imports sorted + formatted", vim.log.levels.INFO)
                    else
                        -- Parse syntax errors
                        if black_result:match("Cannot parse") or black_result:match("SyntaxError") then
                            local line_number = black_result:match(": (%d+):")
                            if line_number then
                                vim.notify("❌ Syntax error on line " .. line_number .. " - fix it first", vim.log.levels.ERROR)
                                pcall(vim.api.nvim_win_set_cursor, 0, {tonumber(line_number), 0})
                            else
                                vim.notify("❌ Code has syntax errors - fix them first", vim.log.levels.ERROR)
                            end
                        else
                            vim.notify("❌ black failed", vim.log.levels.ERROR)
                        end
                    end
                else
                    vim.notify("🚫 black not found", vim.log.levels.WARN)
                end

            elseif ft == "lua" and vim.fn.executable("stylua") == 1 then
                -- Lua formatting.
                if vim.bo.modified then vim.cmd("silent write") end
                local cursor_pos = vim.api.nvim_win_get_cursor(0)
                vim.notify("🔄 Formatting Lua...", vim.log.levels.INFO)

                vim.fn.system({"stylua", "--column-width", "79", vim.fn.expand("%:p")})
                if vim.v.shell_error == 0 then
                    vim.cmd("silent! edit!")
                    pcall(vim.api.nvim_win_set_cursor, 0, cursor_pos)
                    vim.notify("🌙 Lua formatted", vim.log.levels.INFO)
                else
                    vim.notify("❌ stylua failed", vim.log.levels.ERROR)
                end

            elseif (ft == "javascript" or ft == "typescript" or ft == "json") and vim.fn.executable("prettier") == 1 then
                -- JavaScript/TypeScript formatting.
                if vim.bo.modified then vim.cmd("silent write") end
                local cursor_pos = vim.api.nvim_win_get_cursor(0)
                vim.notify("🔄 Formatting " .. ft:upper() .. "...", vim.log.levels.INFO)

                vim.fn.system({"prettier", "--write", "--print-width", "79", vim.fn.expand("%:p")})
                if vim.v.shell_error == 0 then
                    vim.cmd("silent! edit!")
                    pcall(vim.api.nvim_win_set_cursor, 0, cursor_pos)
                    vim.notify("✨ " .. ft:upper() .. " formatted", vim.log.levels.INFO)
                else
                    vim.notify("❌ prettier failed", vim.log.levels.ERROR)
                end

            else
                vim.notify("No formatter available for " .. ft, vim.log.levels.INFO)
            end
        end, {desc = "Format document (Python: isort+black, others: language-specific)"})

        -- Commands.
        vim.api.nvim_create_user_command("InstallPythonTools", function()
            local py = get_python_executable()
            vim.notify("Installing Python tools...", vim.log.levels.INFO)
            vim.fn.system(py .. " -m pip install -U black isort mypy flake8")
            vim.notify("✅ Tools installed", vim.log.levels.INFO)
        end, {desc = "Install Python tools"})

        vim.api.nvim_create_user_command("PythonToolsStatus", function()
            local py = get_python_executable()
            local tools = {"black", "isort", "mypy", "flake8"}

            print("Python: " .. py)
            for _, tool in ipairs(tools) do
                local exe = py:gsub("/python$", "/" .. tool)
                local available = vim.fn.executable(tool) == 1 or vim.fn.executable(exe) == 1
                print("  " .. tool .. ": " .. (available and "✅" or "❌"))
            end
        end, {desc = "Check Python tools"})

        vim.api.nvim_create_user_command("CreatePyprojectToml", function()
            local content = [[
# Fix the [project] section before installing.
# Activate virtual environment and run `pip install -e .`

[project]
name = "project-name"
version = "0.0.1"

[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_meta"

[tool.setuptools]
package-dir = {"" = "src"}

[tool.setuptools.packages.find]
where = ["src"]

[tool.black]
line-length = 79
skip-string-normalization = true

[tool.isort]
profile = "black"
line_length = 79
multi_line_output = 3
include_trailing_comma = true
]]
            if vim.fn.filereadable("pyproject.toml") == 1 then
                vim.notify("pyproject.toml already exists", vim.log.levels.WARN)
            else
                local file = io.open("pyproject.toml", "w")
                if file then
                    file:write(content)
                    file:close()
                    vim.notify("✅ Created pyproject.toml", vim.log.levels.INFO)
                end
            end
        end, {desc = "Create pyproject.toml"})
    end
}