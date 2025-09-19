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

        null_ls.setup(
            {
                sources = {
                    -- Python formatting.
                    null_ls.builtins.formatting.black.with(
                        {
                            command = function()
                                local python_path = get_python_executable()
                                local black_cmd = python_path:gsub("/python$", "/black")
                                if vim.fn.executable(black_cmd) == 1 then
                                    return black_cmd
                                end
                                return "black"
                            end,
                            extra_args = {"--line-length", "79"}
                        }
                    ),
                    null_ls.builtins.formatting.isort.with(
                        {
                            command = function()
                                local python_path = get_python_executable()
                                local isort_cmd = python_path:gsub("/python$", "/isort")
                                if vim.fn.executable(isort_cmd) == 1 then
                                    return isort_cmd
                                end
                                return "isort"
                            end,
                            extra_args = {"--profile", "black", "--line-length", "79"}
                        }
                    ),
                    -- JavaScript/TypeScript/Vue/CSS/HTML.
                    null_ls.builtins.formatting.prettier.with(
                        {
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
                        }
                    ),
                    -- Lua.
                    null_ls.builtins.formatting.stylua,
                    -- Go (goimports includes gofmt functionality).
                    null_ls.builtins.formatting.goimports,
                    -- C/C++.
                    null_ls.builtins.formatting.clang_format.with(
                        {
                            extra_args = {"-style='{BasedOnStyle: llvm, ColumnLimit: 79}'"}
                        }
                    )
                },
                -- Format on save.
                on_attach = function(client, bufnr)
                    if client.supports_method("textDocument/formatting") then
                        local augroup = vim.api.nvim_create_augroup("LspFormatting", {clear = false})
                        vim.api.nvim_clear_autocmds({group = augroup, buffer = bufnr})
                        vim.api.nvim_create_autocmd(
                            "BufWritePre",
                            {
                                group = augroup,
                                buffer = bufnr,
                                callback = function()
                                    if vim.g.format_on_save then
                                        vim.lsp.buf.format(
                                            {
                                                filter = function(client)
                                                    -- Use null-ls for formatting when available
                                                    return client.name == "null-ls"
                                                end,
                                                bufnr = bufnr
                                            }
                                        )
                                    end
                                end
                            }
                        )
                    end
                end
            }
        )

        -- Manual format command.
        vim.keymap.set(
            "n",
            "<leader>F",
            function()
                vim.lsp.buf.format({async = true})
            end,
            {desc = "Format document"}
        )

        -- Toggle format on save.
        vim.g.format_on_save = true
        vim.keymap.set(
            "n",
            "<leader>tf",
            function()
                vim.g.format_on_save = not vim.g.format_on_save
                print("Format on save: " .. (vim.g.format_on_save and "ON" or "OFF"))
            end,
            {desc = "Toggle format on save"}
        )

        -- Sort Python imports manually
        vim.keymap.set(
            "n",
            "<leader>is",
            function()
                vim.cmd("write")
                local python_path = get_python_executable()
                local isort_cmd = python_path:gsub("/python$", "/isort")
                if vim.fn.executable(isort_cmd) == 1 then
                    vim.cmd("!" .. isort_cmd .. " --profile black --line-length 79 %")
                else
                    vim.cmd("!isort --profile black --line-length 79 %")
                end
                vim.cmd("edit!")
            end,
            {desc = "Sort Python imports"}
        )
    end
}
