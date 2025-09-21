-- ~/.config/nvim/lua/plugins/lsp.lua
-- Language Server Protocol configuration with tab-first navigation.

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

        -- Python virtual environment detection.
        local function get_python_path()
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

        -- Show diagnostics for current line in a float.
        local function show_line_diagnostics()
            local opts = {
                focusable = false,
                close_events = {
                    "BufLeave", "CursorMoved", "InsertEnter", "FocusLost"
                },
                border = "rounded",
                source = "always",
                prefix = " ",
                scope = "line"
            }
            vim.diagnostic.open_float(nil, opts)
        end

        ----------------------------------------------------------------------
        -- TAB-FIRST LSP NAVIGATION (unified handler for locations)
        ----------------------------------------------------------------------

        -- Open a single LSP location in a tab (reuse tab if already open).
        local function open_lsp_location_in_tab(loc)
            -- Location can be Location or LocationLink.
            local uri = loc.uri or loc.targetUri
            local range = loc.range or loc.targetSelectionRange
                         or loc.targetRange
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

            -- Reuse an existing tab if file is already open.
            for tab_nr = 1, vim.fn.tabpagenr("$") do
                local buflist = vim.fn.tabpagebuflist(tab_nr)
                for _, b in ipairs(buflist) do
                    if vim.fn.bufname(b) == fname then
                        vim.cmd(tab_nr .. "tabnext")
                        pcall(vim.api.nvim_win_set_cursor, 0, {lnum, col})
                        vim.cmd("normal! zz")
                        return
                    end
                end
            end

            -- Otherwise open in a new tab.
            vim.cmd("tab drop " .. vim.fn.fnameescape(fname))
            pcall(vim.api.nvim_win_set_cursor, 0, {lnum, col})
            vim.cmd("normal! zz")
        end

        -- Convert any LSP location result to a single location and open it.
        local function handle_locations_in_tabs(err, result, ctx, _)
            if err then
                vim.notify(
                    "LSP error: " .. (err.message or ""),
                    vim.log.levels.ERROR
                )
                return
            end
            if not result
               or (type(result) == "table" and vim.tbl_isempty(result)) then
                vim.notify("No locations found", vim.log.levels.INFO)
                return
            end

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

        -- Force LSP navigation requests to use our tab handler.
        vim.lsp.handlers["textDocument/definition"] = handle_locations_in_tabs
        vim.lsp.handlers["textDocument/declaration"] = handle_locations_in_tabs
        vim.lsp.handlers["textDocument/typeDefinition"] =
            handle_locations_in_tabs
        vim.lsp.handlers["textDocument/implementation"] =
            handle_locations_in_tabs

        ----------------------------------------------------------------------
        -- on_attach: keymaps (gd + mouse) now leverage the handlers above
        ----------------------------------------------------------------------
        local function on_attach(client, bufnr)
            local opts = {buffer = bufnr, silent = true}

            -- References in quickfix (kept as is).
            local function show_references()
                vim.lsp.buf.references(
                    nil,
                    {
                        on_list = function(options)
                            vim.fn.setqflist({}, " ", options)
                            vim.cmd("copen")
                            vim.wo.cursorline = true
                            vim.wo.number = true
                            vim.wo.relativenumber = false
                        end
                    }
                )
            end

            -- Navigation (tab behavior via custom handlers).
            vim.keymap.set(
                "n",
                "gd",
                vim.lsp.buf.definition,
                vim.tbl_extend("force", opts, {desc = "Go to definition"})
            )
            vim.keymap.set(
                "n",
                "gD",
                vim.lsp.buf.declaration,
                vim.tbl_extend("force", opts, {desc = "Go to declaration"})
            )
            vim.keymap.set(
                "n",
                "gi",
                vim.lsp.buf.implementation,
                vim.tbl_extend(
                    "force",
                    opts,
                    {desc = "Go to implementation"}
                )
            )
            vim.keymap.set(
                "n",
                "gr",
                show_references,
                vim.tbl_extend("force", opts, {desc = "Show references"})
            )

            -- Mouse: Ctrl+LeftClick and Double-LeftClick go to definition.
            vim.keymap.set(
                "n",
                "<C-LeftMouse>",
                vim.lsp.buf.definition,
                vim.tbl_extend(
                    "force",
                    opts,
                    {desc = "Go to definition (Ctrl+Click)"}
                )
            )
            vim.keymap.set(
                "n",
                "<2-LeftMouse>",
                vim.lsp.buf.definition,
                vim.tbl_extend(
                    "force",
                    opts,
                    {desc = "Go to definition (double click)"}
                )
            )

            -- Docs / help.
            vim.keymap.set(
                "n",
                "K",
                vim.lsp.buf.hover,
                vim.tbl_extend("force", opts, {desc = "Show hover info"})
            )
            vim.keymap.set(
                "n",
                "<C-k>",
                vim.lsp.buf.signature_help,
                vim.tbl_extend("force", opts, {desc = "Signature help"})
            )

            -- Code actions / rename.
            vim.keymap.set(
                "n",
                "<leader>ca",
                vim.lsp.buf.code_action,
                vim.tbl_extend("force", opts, {desc = "Code action"})
            )
            vim.keymap.set(
                "n",
                "<leader>rn",
                vim.lsp.buf.rename,
                vim.tbl_extend("force", opts, {desc = "Rename symbol"})
            )

            -- Diagnostics navigation.
            vim.keymap.set(
                "n",
                "[d",
                vim.diagnostic.goto_prev,
                vim.tbl_extend(
                    "force",
                    opts,
                    {desc = "Previous diagnostic"}
                )
            )
            vim.keymap.set(
                "n",
                "]d",
                vim.diagnostic.goto_next,
                vim.tbl_extend("force", opts, {desc = "Next diagnostic"})
            )

            -- Line diagnostics.
            vim.keymap.set(
                "n",
                "<leader>xx",
                show_line_diagnostics,
                vim.tbl_extend(
                    "force",
                    opts,
                    {desc = "Show line diagnostics"}
                )
            )
            vim.keymap.set(
                "n",
                "gl",
                show_line_diagnostics,
                vim.tbl_extend(
                    "force",
                    opts,
                    {desc = "Show line diagnostics"}
                )
            )

            -- Format.
            vim.keymap.set(
                "n",
                "<leader>f",
                function() vim.lsp.buf.format({async = true}) end,
                vim.tbl_extend("force", opts, {desc = "Format buffer"})
            )
        end

        ----------------------------------------------------------------------
        -- Diagnostics UI
        ----------------------------------------------------------------------
        vim.diagnostic.config({
            virtual_text = false,
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = "☣",
                    [vim.diagnostic.severity.WARN] = "⚠",
                    [vim.diagnostic.severity.HINT] = "💡",
                    [vim.diagnostic.severity.INFO] = "ℹ"
                }
            },
            underline = true,
            update_in_insert = false,
            severity_sort = true,
            float = {
                border = "rounded",
                source = "always",
                header = "",
                prefix = "",
                format = function(d)
                    return string.format("%s: %s", d.source or "LSP", d.message)
                end
            }
        })

        -- Debug helper.
        local function debug_diagnostics()
            local diagnostics = vim.diagnostic.get(0)
            print("Diagnostics count:", #diagnostics)
            print("Signcolumn setting:", vim.wo.signcolumn)
            print("Testing icons: ☣ ⚠ 💡 ℹ")
            vim.diagnostic.show(0, 0, diagnostics)
            for _, diag in ipairs(diagnostics) do
                print(string.format(
                    "Line %d: %s [%s]",
                    diag.lnum + 1,
                    diag.message,
                    diag.severity
                ))
            end
        end
        vim.api.nvim_create_user_command(
            "DiagnosticsDebug",
            debug_diagnostics,
            {desc = "Debug diagnostics"}
        )

        -- Ensure signcolumn and refresh diagnostics on LSP attach.
        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function()
                vim.wo.signcolumn = "yes"
                vim.diagnostic.show()
            end
        })

        -- Subtle virtual text colors (keep for potential re-enable).
        vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", {
            fg = "#6c6c6c",
            italic = true
        })
        vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", {
            fg = "#6c6c6c",
            italic = true
        })
        vim.api.nvim_set_hl(0, "DiagnosticVirtualTextInfo", {
            fg = "#6c6c6c",
            italic = true
        })
        vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", {
            fg = "#6c6c6c",
            italic = true
        })

        ----------------------------------------------------------------------
        -- Servers
        ----------------------------------------------------------------------
        local servers = {
            pyright = {
                settings = {
                    python = {
                        pythonPath = get_python_path(),
                        analysis = {
                            typeCheckingMode = "basic",
                            autoSearchPaths = true,
                            useLibraryCodeForTypes = true,
                            extraPaths = {"."}
                        },
                        workspace = {symbols = {maxSymbols = 2000}}
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
            ts_ls = {
                settings = {
                    typescript = {
                        inlayHints = {
                            includeInlayParameterNameHints = "literal",
                            includeInlayParameterNameHintsWhenArgumentMatchesName
                                = false,
                            includeInlayFunctionParameterTypeHints = true,
                            includeInlayVariableTypeHints = false,
                            includeInlayPropertyDeclarationTypeHints = true,
                            includeInlayFunctionLikeReturnTypeHints = true
                        }
                    }
                },
                root_markers = {"package.json", "tsconfig.json", ".git"}
            },
            vue_ls = {
                filetypes = {"vue"},
                init_options = {
                    typescript = {
                        tsdk = vim.fn.stdpath("data")
                            .. "/mason/packages/vue-language-server/"
                            .. "node_modules/typescript/lib"
                    }
                },
                root_markers = {"package.json", "vue.config.js", ".git"}
            },
            html = {
                filetypes = {"html", "htmldjango"},
                settings = {
                    html = {
                        format = {
                            templating = true,
                            wrapLineLength = 79,
                            wrapAttributes = "auto"
                        },
                        hover = {documentation = true, references = true}
                    }
                },
                root_markers = {".git"}
            },
            cssls = {
                settings = {
                    css = {validate = true, lint = {unknownAtRules = "ignore"}},
                    scss = {validate = true},
                    less = {validate = true}
                },
                root_markers = {"package.json", ".git"}
            },
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
                init_options = {html = {options = {["bem.enabled"] = true}}},
                root_markers = {".git"}
            },
            gopls = {
                settings = {
                    gopls = {
                        analyses = {unusedparams = true},
                        staticcheck = true,
                        gofumpt = true
                    }
                },
                root_markers = {"go.mod", ".git"}
            },
            clangd = {
                cmd = {
                    "clangd",
                    "--background-index",
                    "--clang-tidy",
                    "--header-insertion=iwyu",
                    "--completion-style=detailed",
                    "--function-arg-placeholders",
                    "--fallback-style=llvm"
                },
                init_options = {usePlaceholders = true},
                root_markers = {"compile_commands.json", ".git"}
            },
            dockerls = {root_markers = {"Dockerfile", ".git"}},
            yamlls = {
                settings = {
                    yaml = {
                        schemas = {
                            ["https://json.schemastore.org/github-workflow.json"] =
                                "/.github/workflows/*",
                            ["https://raw.githubusercontent.com/compose-spec/"
                             .. "compose-spec/master/schema/compose-spec.json"] =
                                "docker-compose*.yml"
                        }
                    }
                },
                root_markers = {".git"}
            },
            jsonls = {
                settings = {
                    json = {
                        schemas = require("schemastore").json.schemas(),
                        validate = {enable = true}
                    }
                },
                root_markers = {"package.json", ".git"}
            },
            lua_ls = {
                settings = {
                    Lua = {
                        runtime = {version = "LuaJIT"},
                        diagnostics = {globals = {"vim"}},
                        workspace = {
                            library = vim.api.nvim_get_runtime_file("", true),
                            checkThirdParty = false
                        },
                        telemetry = {enable = false}
                    }
                },
                root_markers = {".luarc.json", ".git"}
            },
            bashls = {filetypes = {"sh", "bash"}, root_markers = {".git"}}
        }

        -- Setup servers (modern vim.lsp.config API).
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
                    on_attach = on_attach
                }
            )
        end

        -- Enable configured servers.
        for server_name, _ in pairs(servers) do
            vim.lsp.enable(server_name)
        end
    end
}
