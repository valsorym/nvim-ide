-- ~/.config/nvim/lua/plugins/lsp.lua
-- Language Server Protocol configuration.

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

        -- Function to show detailed diagnostics in floating window.
        local function show_line_diagnostics()
            local opts = {
                focusable = false, -- window not focusable for quick dismiss
                close_events = {"BufLeave", "CursorMoved", "InsertEnter", "FocusLost"},
                border = "rounded",
                source = "always",
                prefix = " ",
                scope = "line"
            }
            vim.diagnostic.open_float(nil, opts)
        end

        -- Key mappings for LSP.
        local function on_attach(client, bufnr)
            local opts = {buffer = bufnr, silent = true}

            -- Navigation.
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
            vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, {desc = "Show references"}))
            vim.keymap.set(
                "n",
                "gi",
                vim.lsp.buf.implementation,
                vim.tbl_extend("force", opts, {desc = "Go to implementation"})
            )

            -- Documentation.
            vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, {desc = "Show hover info"}))
            vim.keymap.set(
                "n",
                "<C-k>",
                vim.lsp.buf.signature_help,
                vim.tbl_extend("force", opts, {desc = "Signature help"})
            )

            -- Code actions.
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
                vim.tbl_extend("force", opts, {desc = "Previous diagnostic"})
            )
            vim.keymap.set(
                "n",
                "]d",
                vim.diagnostic.goto_next,
                vim.tbl_extend("force", opts, {desc = "Next diagnostic"})
            )

            -- Show line diagnostics in floating window
            vim.keymap.set(
                "n",
                "<leader>xx",
                show_line_diagnostics,
                vim.tbl_extend("force", opts, {desc = "Show line diagnostics"})
            )

            -- Alternative key for quick access to diagnostics.
            vim.keymap.set(
                "n",
                "gl",
                show_line_diagnostics,
                vim.tbl_extend("force", opts, {desc = "Show line diagnostics"})
            )

            -- Format.
            vim.keymap.set(
                "n",
                "<leader>f",
                function()
                    vim.lsp.buf.format({async = true})
                end,
                vim.tbl_extend("force", opts, {desc = "Format buffer"})
            )
        end

        -- Diagnostic configuration with modern API.
        vim.diagnostic.config(
            {
                -- Disable virtual text (text at end of line).
                virtual_text = false,
                -- Show icons in sign column using modern API.
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = "☣",
                        [vim.diagnostic.severity.WARN] = "⚠",
                        [vim.diagnostic.severity.HINT] = "💡",
                        [vim.diagnostic.severity.INFO] = "ℹ"
                    }
                },
                -- Enable underlines for errors.
                underline = true,
                -- Don't update in insert mode for performance.
                update_in_insert = false,
                -- Sort by severity
                severity_sort = true,
                -- Floating window configuration.
                float = {
                    border = "rounded",
                    source = "always",
                    header = "",
                    prefix = "",
                    -- Compact format.
                    format = function(diagnostic)
                        return string.format("%s: %s", diagnostic.source or "LSP", diagnostic.message)
                    end
                }
            }
        )

        -- Debug function to check if diagnostics are working.
        local function debug_diagnostics()
            local diagnostics = vim.diagnostic.get(0)
            print("Diagnostics count:", #diagnostics)
            print("Signcolumn setting:", vim.wo.signcolumn)
            print("Testing icons: ☣ ⚠ 💡 ℹ")

            -- Force refresh signs
            vim.diagnostic.show(0, 0, diagnostics)

            for i, diag in ipairs(diagnostics) do
                print(string.format("Line %d: %s [%s]", diag.lnum + 1, diag.message, diag.severity))
            end
        end

        -- Add debug command.
        vim.api.nvim_create_user_command("DiagnosticsDebug", debug_diagnostics, {desc = "Debug diagnostics"})

        -- Force enable signcolumn and refresh diagnostics.
        vim.api.nvim_create_autocmd(
            "LspAttach",
            {
                callback = function()
                    vim.wo.signcolumn = "yes"
                    vim.diagnostic.show()
                end
            }
        )

        -- Make virtual text colors more subtle (kept for potential re-enabling).
        vim.api.nvim_set_hl(
            0,
            "DiagnosticVirtualTextError",
            {
                fg = "#6c6c6c",
                italic = true
            }
        )
        vim.api.nvim_set_hl(
            0,
            "DiagnosticVirtualTextWarn",
            {
                fg = "#6c6c6c",
                italic = true
            }
        )
        vim.api.nvim_set_hl(
            0,
            "DiagnosticVirtualTextInfo",
            {
                fg = "#6c6c6c",
                italic = true
            }
        )
        vim.api.nvim_set_hl(
            0,
            "DiagnosticVirtualTextHint",
            {
                fg = "#6c6c6c",
                italic = true
            }
        )

        -- Server configurations using modern vim.lsp.config API.
        local servers = {
            -- Python with Django support.
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
                        workspace = {
                            symbols = {
                                maxSymbols = 2000
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
            -- TypeScript/JavaScript.
            ts_ls = {
                settings = {
                    typescript = {
                        inlayHints = {
                            includeInlayParameterNameHints = "literal",
                            includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                            includeInlayFunctionParameterTypeHints = true,
                            includeInlayVariableTypeHints = false,
                            includeInlayPropertyDeclarationTypeHints = true,
                            includeInlayFunctionLikeReturnTypeHints = true
                        }
                    }
                },
                root_markers = {"package.json", "tsconfig.json", ".git"}
            },
            -- Vue.js (using vue_ls - modern replacement for volar)
            vue_ls = {
                filetypes = {"vue"},
                init_options = {
                    typescript = {
                        -- Path to typescript that Mason installs with vue-language-server
                        tsdk = vim.fn.stdpath("data") ..
                            "/mason/packages/vue-language-server/node_modules/typescript/lib"
                    }
                },
                root_markers = {"package.json", "vue.config.js", ".git"}
            },
            -- HTML with Django template support
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
            -- Go.
            gopls = {
                settings = {
                    gopls = {
                        analyses = {
                            unusedparams = true
                        },
                        staticcheck = true,
                        gofumpt = true
                    }
                },
                root_markers = {"go.mod", ".git"}
            },
            -- C/C++.
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
                init_options = {
                    usePlaceholders = true
                },
                root_markers = {"compile_commands.json", ".git"}
            },
            -- PlatformIO C/C++ support
            clangd_pio = {
                cmd = {
                    "clangd",
                    "--background-index",
                    "--clang-tidy",
                    "--header-insertion=iwyu",
                    "--completion-style=detailed",
                    "--function-arg-placeholders",
                    "--fallback-style=llvm",
                    "--compile-commands-dir=.pio/build"
                },
                init_options = {
                    usePlaceholders = true,
                    completeUnimported = true,
                    clangdFileStatus = true
                },
                root_markers = {
                    "platformio.ini",
                    ".pio",
                    "compile_commands.json",
                    ".git"
                },
                settings = {
                    clangd = {
                        semanticHighlighting = true,
                        fallbackFlags = {
                            "-std=c++17",
                            "-Wall",
                            "-Wextra"
                        }
                    }
                },
                -- Only activate for PlatformIO projects
                on_new_config = function(config, root_dir)
                    local platformio_ini = root_dir .. "/platformio.ini"
                    if vim.fn.filereadable(platformio_ini) == 1 then
                        -- Try to generate compile_commands.json if it doesn't exist
                        local compile_commands = root_dir .. "/.pio/build/compile_commands.json"
                        if vim.fn.filereadable(compile_commands) == 0 then
                            vim.notify("Generating compile_commands.json for PlatformIO project...")
                            vim.fn.system("cd " .. root_dir .. " && pio run --target compiledb")
                        end

                        -- Set compile commands directory
                        config.cmd = vim.list_extend(config.cmd or {}, {
                            "--compile-commands-dir=" .. root_dir .. "/.pio/build"
                        })
                    end
                end
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
                            ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
                            ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "docker-compose*.yml"
                        }
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
            -- Bash
            bashls = {
                filetypes = {"sh", "bash"},
                root_markers = {".git"}
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
                    on_attach = on_attach
                }
            )
        end

        -- Enable the configured servers.
        for server_name, _ in pairs(servers) do
            vim.lsp.enable(server_name)
        end
    end
}