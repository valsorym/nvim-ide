-- ~/.config/nvim/lua/plugins/lsp.lua
-- Optimized LSP configuration with resource limits

return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp"
    },
    config = function()
        local cmp_nvim_lsp = require("cmp_nvim_lsp")

        -- Enhanced capabilities with autocompletion.
        local capabilities = cmp_nvim_lsp.default_capabilities()

        -- Reduce memory usage by limiting certain LSP features
        capabilities.textDocument.completion.completionItem.snippetSupport =
            true
        capabilities.textDocument.completion.completionItem
            .resolveSupport = {
            properties = {
                "documentation",
                "detail",
                "additionalTextEdits",
            },
        }

        -- Python virtual environment detection.
        local function get_python_path()
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

        -- Open location in a tab (reuse tab if file already open).
        local function open_lsp_location_in_tab(loc)
            -- Location can be Location or LocationLink.
            local uri = loc.uri or loc.targetUri
            local range = loc.range or loc.targetSelectionRange or
                loc.targetRange
            if not (uri and range) then
                return
            end

            local fname = vim.uri_to_fname(uri)
            local lnum = (range.start and range.start.line or 0) + 1
            local col = (range.start and range.start.character or 0)

            local cur = vim.api.nvim_get_current_buf()
            local cur_name = vim.api.nvim_buf_get_name(cur)

            -- Same file: just jump.
            if cur_name == fname then
                pcall(vim.api.nvim_win_set_cursor, 0, {lnum, col})
                vim.cmd("normal! zz")
                return
            end

            -- Look for an existing tab showing this file.
            for tab_nr = 1, vim.fn.tabpagenr("$") do
                local buflist = vim.fn.tabpagebuflist(tab_nr)
                for _, b in ipairs(buflist) do
                    if vim.fn.bufname(b) == fname then
                        vim.cmd(tab_nr .. "tabnext")
                        pcall(vim.api.nvim_win_set_cursor, 0,
                            {lnum, col})
                        vim.cmd("normal! zz")
                        return
                    end
                end
            end

            -- Open in a new tab.
            vim.cmd("tab drop " .. vim.fn.fnameescape(fname))
            pcall(vim.api.nvim_win_set_cursor, 0, {lnum, col})
            vim.cmd("normal! zz")
        end

        -- Generic handler for LSP locations -> open in tabs.
        local function handle_locations_in_tabs(err, result, ctx, _)
            if err then
                vim.notify("LSP error: " .. (err.message or ""),
                    vim.log.levels.ERROR)
                return
            end
            if not result or (type(result) == "table" and
                vim.tbl_isempty(result)) then
                vim.notify("No locations found", vim.log.levels.INFO)
                return
            end

            -- Result can be a single location or a list.
            local loc = result
            if vim.tbl_islist(result) then
                loc = result[1]
            end
            if not loc then
                vim.notify("No locations found", vim.log.levels.INFO)
                return
            end

            open_lsp_location_in_tab(loc)
        end

        -- Pick correct offset encoding for make_position_params.
        local function make_pos_params(bufnr)
            bufnr = bufnr or vim.api.nvim_get_current_buf()
            local clients = vim.lsp.get_clients({ bufnr = bufnr })
            local encoding = "utf-16"  -- default fallback

            -- Use encoding from first available client.
            if clients and #clients > 0 then
                encoding = clients[1].offset_encoding or "utf-16"
            end

            -- Get current cursor position.
            local row, col = unpack(vim.api.nvim_win_get_cursor(0))

            return {
                textDocument = vim.lsp.util.make_text_document_params(
                    bufnr),
                position = {
                    line = row - 1,  -- LSP uses 0-based indexing
                    character = col
                }
            }
        end

        -- Enforce tab behavior for these LSP requests.
        vim.lsp.handlers["textDocument/definition"] =
            handle_locations_in_tabs
        vim.lsp.handlers["textDocument/declaration"] =
            handle_locations_in_tabs
        vim.lsp.handlers["textDocument/typeDefinition"] =
            handle_locations_in_tabs
        vim.lsp.handlers["textDocument/implementation"] =
            handle_locations_in_tabs

        -- Key mappings for LSP with tab navigation.
        local function on_attach(client, bufnr)
            local opts = {buffer = bufnr, silent = true}

            -- Optimize LSP client settings to reduce resource usage
            client.server_capabilities.semanticTokensProvider = nil

            -- References in quickfix.
            local function show_references()
                vim.lsp.buf.references(nil, {
                    on_list = function(options)
                        vim.fn.setqflist({}, " ", options)
                        vim.cmd("copen")
                        vim.wo.cursorline = true
                        vim.wo.number = true
                        vim.wo.relativenumber = false
                    end
                })
            end

            -- Custom LSP functions that force tab behavior.
            local function definition_in_tab()
                local params = make_pos_params()
                vim.lsp.buf_request(0, "textDocument/definition", params,
                    function(err, result)
                        if err then
                            vim.notify("LSP error: " ..
                                (err.message or ""),
                                vim.log.levels.ERROR)
                            return
                        end
                        if not result or vim.tbl_isempty(result) then
                            vim.notify("No definition found",
                                vim.log.levels.INFO)
                            return
                        end
                        local location = result[1] or result
                        open_lsp_location_in_tab(location)
                    end)
            end

            local function declaration_in_tab()
                local params = make_pos_params()
                vim.lsp.buf_request(0, "textDocument/declaration",
                    params,
                    function(err, result)
                        if err then
                            vim.notify("LSP error: " ..
                                (err.message or ""),
                                vim.log.levels.ERROR)
                            return
                        end
                        if not result or vim.tbl_isempty(result) then
                            vim.notify("No declaration found",
                                vim.log.levels.INFO)
                            return
                        end
                        local location = result[1] or result
                        open_lsp_location_in_tab(location)
                    end)
            end

            local function implementation_in_tab()
                local params = make_pos_params()
                vim.lsp.buf_request(0, "textDocument/implementation",
                    params,
                    function(err, result)
                        if err then
                            vim.notify("LSP error: " ..
                                (err.message or ""),
                                vim.log.levels.ERROR)
                            return
                        end
                        if not result or vim.tbl_isempty(result) then
                            vim.notify("No implementation found",
                                vim.log.levels.INFO)
                            return
                        end
                        local location = result[1] or result
                        open_lsp_location_in_tab(location)
                    end)
            end

            _G.LspDefinitionInTab = definition_in_tab

            -- Navigation with explicit tab functions.
            vim.keymap.set("n", "gd", definition_in_tab,
                vim.tbl_extend("force", opts,
                    {desc = "Go to definition (tab)"}))
            vim.keymap.set("n", "gD", declaration_in_tab,
                vim.tbl_extend("force", opts,
                    {desc = "Go to declaration (tab)"}))
            vim.keymap.set("n", "gi", implementation_in_tab,
                vim.tbl_extend("force", opts,
                    {desc = "Go to implementation (tab)"}))
            vim.keymap.set("n", "gr", show_references,
                vim.tbl_extend("force", opts,
                    {desc = "Show references"}))

            -- Other LSP functions.
            vim.keymap.set("n", "K", vim.lsp.buf.hover,
                vim.tbl_extend("force", opts, {desc = "Hover doc"}))
            vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help,
                vim.tbl_extend("force", opts,
                    {desc = "Signature help"}))
            vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename,
                vim.tbl_extend("force", opts, {desc = "Rename symbol"}))
            vim.keymap.set({"n", "v"}, "<leader>ca",
                vim.lsp.buf.code_action,
                vim.tbl_extend("force", opts, {desc = "Code action"}))
            vim.keymap.set("n", "<leader>cf", function()
                vim.lsp.buf.format({async = true})
            end, vim.tbl_extend("force", opts, {desc = "Format buffer"}))

            -- Diagnostics.
            vim.keymap.set("n", "[d", vim.diagnostic.goto_prev,
                vim.tbl_extend("force", opts,
                    {desc = "Previous diagnostic"}))
            vim.keymap.set("n", "]d", vim.diagnostic.goto_next,
                vim.tbl_extend("force", opts,
                    {desc = "Next diagnostic"}))
            vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float,
                vim.tbl_extend("force", opts,
                    {desc = "Show diagnostic"}))
            vim.keymap.set("n", "<leader>cq", vim.diagnostic.setloclist,
                vim.tbl_extend("force", opts,
                    {desc = "Diagnostic list"}))
        end

        -- Diagnostic configuration with reduced resource usage
        vim.diagnostic.config({
            virtual_text = {
                spacing = 4,
                prefix = "●",
                severity = {
                    min = vim.diagnostic.severity.WARN,
                },
            },
            signs = true,
            underline = true,
            update_in_insert = false,
            severity_sort = true,
            float = {
                border = "rounded",
                source = "always",
                header = "",
                prefix = "",
                max_width = 80,
            },
        })

        -- Signs in the gutter.
        local signs = {
            Error = " ",
            Warn = " ",
            Hint = " ",
            Info = " "
        }
        for type, icon in pairs(signs) do
            local hl = "DiagnosticSign" .. type
            vim.fn.sign_define(hl, {text = icon, texthl = hl, numhl = ""})
        end

        -- Configure LSP servers with resource optimization.
        local servers = {
            -- Python with optimized settings.
            pyright = {
                before_init = function(_, config)
                    config.settings.python.pythonPath = get_python_path()
                end,
                settings = {
                    python = {
                        analysis = {
                            autoSearchPaths = true,
                            diagnosticMode = "openFilesOnly",
                            useLibraryCodeForTypes = false,
                            typeCheckingMode = "basic",
                            autoImportCompletions = true,
                            diagnosticSeverityOverrides = {
                                reportUnusedImport = "warning",
                                reportUnusedVariable = "warning",
                                reportGeneralTypeIssues = "none",
                            },
                            indexing = false,
                            logLevel = "Error",
                            stubPath = "",
                            completeFunctionParens = true,
                            extraPaths = {},
                            inlayHints = {
                                variableTypes = false,
                                functionReturnTypes = false
                            },
                            workspace = {
                                maxSymbols = 1000
                            }
                        }
                    }
                },
                root_markers = {
                    "pyrightconfig.json",
                    ".git",
                    "pyproject.toml",
                    "setup.py",
                    "setup.cfg",
                    "requirements.txt"
                }
            },
            -- TypeScript/JavaScript with reduced features.
            ts_ls = {
                settings = {
                    typescript = {
                        inlayHints = {
                            includeInlayParameterNameHints = "none",
                            includeInlayParameterNameHintsWhenArgumentMatchesName =
                                false,
                            includeInlayFunctionParameterTypeHints = false,
                            includeInlayVariableTypeHints = false,
                            includeInlayPropertyDeclarationTypeHints = false,
                            includeInlayFunctionLikeReturnTypeHints = false
                        },
                        suggest = {
                            includeCompletionsForModuleExports = true,
                            includeAutomaticOptionalChainCompletions = false,
                        },
                    },
                    javascript = {
                        inlayHints = {
                            includeInlayParameterNameHints = "none",
                            includeInlayParameterNameHintsWhenArgumentMatchesName =
                                false,
                            includeInlayFunctionParameterTypeHints = false,
                            includeInlayVariableTypeHints = false,
                            includeInlayPropertyDeclarationTypeHints = false,
                            includeInlayFunctionLikeReturnTypeHints = false
                        },
                        suggest = {
                            includeCompletionsForModuleExports = true,
                            includeAutomaticOptionalChainCompletions = false,
                        },
                    }
                },
                root_markers = {"package.json", "tsconfig.json", ".git"}
            },
            -- HTML with Django template support.
            html = {
                filetypes = {"html", "htmldjango"},
                settings = {
                    html = {
                        format = {
                            templating = true,
                            wrapLineLength = 79,
                            wrapAttributes = "auto"
                        },
                        hover = {
                            documentation = true,
                            references = true
                        }
                    }
                },
                root_markers = {".git"}
            },
            -- CSS with embedded support.
            cssls = {
                settings = {
                    css = {
                        validate = true,
                        lint = {
                            unknownAtRules = "ignore"
                        }
                    },
                    scss = {
                        validate = true
                    },
                    less = {
                        validate = true
                    }
                },
                root_markers = {"package.json", ".git"}
            },
            -- Emmet for HTML/CSS.
            emmet_ls = {
                filetypes = {
                    "html",
                    "css",
                    "scss",
                    "javascript",
                    "typescript",
                    "vue",
                    "htmldjango"
                },
                init_options = {
                    html = {
                        options = {
                            ["bem.enabled"] = true
                        }
                    }
                },
                root_markers = {".git"}
            },
            -- Docker.
            dockerls = {
                root_markers = {"Dockerfile", ".git"}
            },
            -- YAML.
            yamlls = {
                settings = {
                    yaml = {
                        schemas = {
                            ["https://json.schemastore.org/github-workflow.json"] =
                                "/.github/workflows/*",
                            ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] =
                                "docker-compose*.yml"
                        },
                        validate = true,
                        hover = true,
                        completion = true,
                    }
                },
                root_markers = {".git"}
            },
            -- JSON.
            jsonls = {
                settings = {
                    json = {
                        schemas = require("schemastore").json.schemas(),
                        validate = {enable = true}
                    }
                },
                root_markers = {"package.json", ".git"}
            },
            -- Lua.
            lua_ls = {
                settings = {
                    Lua = {
                        runtime = {version = "LuaJIT"},
                        diagnostics = {
                            globals = {"vim"},
                            disable = {"missing-fields"}
                        },
                        workspace = {
                            library = vim.api.nvim_get_runtime_file("",
                                true),
                            checkThirdParty = false,
                            maxPreload = 2000,
                            preloadFileSize = 1000
                        },
                        telemetry = {enable = false},
                        format = {enable = false}
                    }
                },
                root_markers = {".luarc.json", ".git"}
            },
            -- Bash with resource limits
            bashls = {
                filetypes = {"sh", "bash"},
                settings = {
                    bashIde = {
                        globPattern = "**/*@(.sh|.inc|.bash|.command)",
                    }
                },
                root_markers = {".git"},
                single_file_support = true,
                flags = {
                    debounce_text_changes = 500,
                }
            }
        }

        -- Setup servers using modern vim.lsp.config API.
        for server_name, config in pairs(servers) do
            vim.lsp.config(
                server_name,
                {
                    cmd = config.cmd,
                    root_markers = config.root_markers or {".git"},
                    capabilities = capabilities,
                    settings = config.settings or {},
                    init_options = config.init_options or {},
                    filetypes = config.filetypes,
                    on_attach = on_attach,
                    before_init = config.before_init,
                    flags = config.flags or {
                        debounce_text_changes = 300,
                        allow_incremental_sync = true,
                    },
                    single_file_support = config.single_file_support or
                        false,
                }
            )
        end

        -- Enable the configured servers.
        for server_name, _ in pairs(servers) do
            vim.lsp.enable(server_name)
        end

        -- Force set handlers after LSP is loaded (double insurance).
        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(args)
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if client then
                    -- Disable semantic tokens to reduce memory usage
                    client.server_capabilities.semanticTokensProvider = nil
                end

                -- Re-apply our custom handlers to ensure they're not
                -- overridden.
                vim.lsp.handlers["textDocument/definition"] =
                    handle_locations_in_tabs
                vim.lsp.handlers["textDocument/declaration"] =
                    handle_locations_in_tabs
                vim.lsp.handlers["textDocument/typeDefinition"] =
                    handle_locations_in_tabs
                vim.lsp.handlers["textDocument/implementation"] =
                    handle_locations_in_tabs
            end
        })

        -- Limit number of active LSP clients per buffer
        vim.api.nvim_create_autocmd("BufEnter", {
            callback = function()
                local clients = vim.lsp.get_clients()
                if #clients > 10 then
                    vim.notify(
                        "Too many LSP clients running. Consider restarting.",
                        vim.log.levels.WARN
                    )
                end
            end
        })
    end
}