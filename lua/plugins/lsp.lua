-- Native LSP lifecycle: incremental changes, shared project clients and lazy filetypes.
return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    cmd = { "LanguageToolsInstall", "LspInstall", "LspUninstall" },
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function()
        local python = require("config.python-venv")
        local servers = {
            pyright = {
                root_markers = require("config.project").python_markers,
                settings = { python = { analysis = {
                    diagnosticMode = "openFilesOnly", autoSearchPaths = true, useLibraryCodeForTypes = true,
                } } },
                before_init = function(_, config)
                    local uri = config.root_dir or config._python_file or vim.api.nvim_buf_get_name(0)
                    config.settings.python.pythonPath = python.python(uri)
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
                client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
                    json = { schemas = require("schemastore").json.schemas(), validate = { enable = true } },
                })
                client.config.settings = client.settings
                client:notify("workspace/didChangeConfiguration", { settings = client.settings })
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
            vim.lsp.config(name, { root_markers = {}, root_dir = function(buf, on_dir)
                require("config.performance").check(buf)
                if require("config.performance").is_large(buf) then return end
                if type(cmd) == "table" and vim.fn.executable(cmd[1]) == 0 then return end
                local function start(root)
                    -- A standalone file must not turn HOME or / into an indexed project.
                    if root and not require("config.project").safe_root(root) then root = nil end
                    if not root and name == "pyright" then
                        -- Rootless clients need separate interpreter settings per directory.
                        local config = vim.deepcopy(vim.lsp.config[name])
                        config.root_dir = nil
                        config._python_file = vim.api.nvim_buf_get_name(buf)
                        config._python_root = python.root(config._python_file)
                        vim.schedule(function()
                            if not vim.api.nvim_buf_is_loaded(buf) then return end
                            vim.lsp.start(config, { bufnr = buf, reuse_client = function(client, candidate)
                                return client.name == candidate.name and not client.config.root_dir
                                    and client.config._python_root == candidate._python_root
                            end })
                        end)
                        return
                    end
                    on_dir(root)
                end
                if root_dir then root_dir(buf, start)
                else start(vim.fs.root(buf, markers or { ".git" })) end
            end })
            vim.lsp.enable(name)
        end
        local function installers()
            require("lazy").load({ plugins = { "mason.nvim" } })
            require("mason-lspconfig").setup({ ensure_installed = {}, automatic_enable = false })
        end
        for _, name in ipairs({ "LspInstall", "LspUninstall" }) do
            vim.api.nvim_create_user_command(name, function(opts)
                installers()
                vim.cmd(name .. (opts.bang and "!" or "") .. " " .. opts.args)
            end, { nargs = "*", bang = true })
        end
        vim.api.nvim_create_user_command("LanguageToolsInstall", function()
            -- Installation is explicit; opening a file must not download a toolchain.
            installers()
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
