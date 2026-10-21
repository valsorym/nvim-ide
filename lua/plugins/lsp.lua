-- Native LSP lifecycle: incremental changes, shared project clients and lazy filetypes.
return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    cmd = "LanguageToolsInstall",
    dependencies = { "mason-org/mason.nvim", "mason-org/mason-lspconfig.nvim", "hrsh7th/cmp-nvim-lsp" },
    config = function()
        local python = require("config.python-venv")
        local servers = {
            pyright = {
                settings = { python = { analysis = {
                    diagnosticMode = "openFilesOnly", autoSearchPaths = true, useLibraryCodeForTypes = true,
                } } },
                before_init = function(_, config)
                    config.settings.python.pythonPath = python.python(config.root_dir)
                end,
            },
            ts_ls = {
                filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
                init_options = { plugins = { {
                    name = "@vue/typescript-plugin",
                    location = vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/@vue/language-server",
                    languages = { "vue" },
                } } },
            },
            vue_ls = {},
            html = { filetypes = { "html", "htmldjango" } },
            cssls = { settings = { css = { validate = true, lint = { unknownAtRules = "ignore" } },
                scss = { validate = true }, less = { validate = true } } },
            emmet_ls = { filetypes = { "html", "css", "scss", "javascript", "typescript", "javascriptreact", "typescriptreact", "vue", "htmldjango" } },
            gopls = { settings = { gopls = { gofumpt = true, analyses = { unusedparams = true } } } },
            clangd = { cmd = { "clangd", "--background-index", "--header-insertion=iwyu", "--clang-tidy" } },
            dockerls = {},
            yamlls = { settings = { yaml = { schemaStore = { enable = true } } } },
            jsonls = { on_init = function(client)
                client.config.settings = vim.tbl_deep_extend("force", client.config.settings or {}, {
                    json = { schemas = require("schemastore").json.schemas(), validate = { enable = true } },
                })
                client:notify("workspace/didChangeConfiguration", { settings = client.config.settings })
            end },
            lua_ls = { settings = { Lua = {
                runtime = { version = "LuaJIT" }, diagnostics = { globals = { "vim" } },
                -- Avoid indexing every installed plugin for every Lua project.
                workspace = { library = { vim.env.VIMRUNTIME }, checkThirdParty = false },
                telemetry = { enable = false },
            } } },
            bashls = {},
            marksman = {},
        }
        local capabilities = require("cmp_nvim_lsp").default_capabilities()
        for name, settings in pairs(servers) do
            settings.capabilities = capabilities
            settings.flags = { debounce_text_changes = 200 }
            vim.lsp.config(name, settings)
            local resolved = vim.lsp.config[name]
            local root_dir, markers, cmd = resolved.root_dir, resolved.root_markers, resolved.cmd
            -- Refuse expensive clients before they spawn for a large or unsupported buffer.
            vim.lsp.config(name, { root_dir = function(buf, on_dir)
                require("config.performance").check(buf)
                if require("config.performance").is_large(buf) then return end
                if type(cmd) == "table" and vim.fn.executable(cmd[1]) == 0 then return end
                if root_dir then root_dir(buf, on_dir) else
                    on_dir(vim.fs.root(buf, markers or { ".git" }) or vim.fs.dirname(vim.api.nvim_buf_get_name(buf)) or vim.fn.getcwd())
                end
            end })
            vim.lsp.enable(name)
        end
        require("mason-lspconfig").setup({ ensure_installed = {}, automatic_enable = false })
        vim.api.nvim_create_user_command("LanguageToolsInstall", function()
            -- Installation is explicit; opening a file must not download a toolchain.
            local names = vim.tbl_keys(servers)
            table.sort(names)
            vim.cmd("LspInstall " .. table.concat(names, " "))
        end, { desc = "Install all supported language servers" })
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("LspBufferOptions", { clear = true }),
            callback = function(args)
                -- Native Vim comments and indentation remain usable in templates.
                if vim.bo[args.buf].filetype == "htmldjango" then vim.bo[args.buf].formatexpr = "" end
            end,
        })
    end,
}
