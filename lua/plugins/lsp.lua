-- ~/.config/nvim/lua/plugins/lsp.lua
-- Language Server Protocol configuration with clean signature help

return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp"
    },
    config = function()
        require("config.lsp-ui")
        local cmp_nvim_lsp = require("cmp_nvim_lsp")

        -- Enhanced capabilities with autocompletion
        local capabilities = cmp_nvim_lsp.default_capabilities()

        -- CRITICAL: Disable signature help from cmp to prevent conflicts
        capabilities.textDocument.signatureHelp = nil

        -- RADICAL solution - override vim.lsp.buf.signature_help completely
        local original_signature_help = vim.lsp.buf.signature_help

        -- Track current signature window to prevent multiple windows
        local current_sig_win = nil

        -- Custom floating window function with proper padding and title
        local function create_signature_window(content, title)
            if current_sig_win and vim.api.nvim_win_is_valid(current_sig_win) then
                pcall(vim.api.nvim_win_close, current_sig_win, true)
            end

            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

            local padded = {}
            for _, l in ipairs(content) do
                table.insert(padded, " " .. l .. " ")
            end
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, padded)

            local width = 0
            for _, l in ipairs(padded) do
                width = math.max(width, #l)
            end
            width = math.min(width + 2, 82)
            local height = #padded

            local win = vim.api.nvim_open_win(buf, false, {
                relative = "cursor",
                row = 1,
                col = 0,
                width = width,
                height = height,
                style = "minimal",
                border = "rounded",
                title = title or "Signature",
                title_pos = "left",
            })
            current_sig_win = win

            -- 🔹 Universal autocmds - not per buffer, but global
            local close_group = vim.api.nvim_create_augroup("SigAutoClose", { clear = true })

            vim.api.nvim_create_autocmd({
                "CursorMoved", "CursorMovedI", "InsertLeave", "BufLeave", "WinLeave",
            }, {
                group = close_group,
                callback = function()
                    if current_sig_win and vim.api.nvim_win_is_valid(current_sig_win) then
                        pcall(vim.api.nvim_win_close, current_sig_win, true)
                        current_sig_win = nil
                    end
                    pcall(vim.api.nvim_del_augroup_by_name, "SigAutoClose")
                end,
            })

            -- 🔹 ESC also globally
            vim.keymap.set({ "i", "n" }, "<Esc>", function()
                if current_sig_win and vim.api.nvim_win_is_valid(current_sig_win) then
                    pcall(vim.api.nvim_win_close, current_sig_win, true)
                    current_sig_win = nil
                end
                pcall(vim.api.nvim_del_augroup_by_name, "SigAutoClose")
                return "<Esc>"
            end, { expr = true, desc = "Close signature help" })

            return win
        end

        vim.lsp.buf.signature_help = function()
            local params = vim.lsp.util.make_position_params()

            vim.lsp.buf_request(0, "textDocument/signatureHelp", params,
                function(err, result)
                    if err or not result or not result.signatures or
                       #result.signatures == 0 then
                        -- Fallback to original if no result
                        return
                    end

                    local sig = result.signatures[1]
                    if not sig or not sig.label then
                        return
                    end

                    -- Handle multi-line content
                    local max_width = 76  -- Leave space for padding and border
                    local lines = {}

                    -- Split long signature into multiple lines if needed
                    local text = sig.label
                    if #text > max_width then
                        -- Simple word wrapping
                        local words = vim.split(text, " ")
                        local current_line = ""

                        for _, word in ipairs(words) do
                            if #current_line + #word + 1 <= max_width then
                                if current_line == "" then
                                    current_line = word
                                else
                                    current_line = current_line .. " " .. word
                                end
                            else
                                if current_line ~= "" then
                                    table.insert(lines, current_line)
                                end
                                current_line = word
                            end
                        end

                        if current_line ~= "" then
                            table.insert(lines, current_line)
                        end
                    else
                        -- Single line
                        table.insert(lines, text)
                    end

                    -- Extract function name from signature for title
                    local func_name = text:match("([%w_]+)%(") or "Function Signature"

                    create_signature_window(lines, func_name)
                end)
        end

        -- Disable automatic hover - only manual with K key
        vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
            vim.lsp.handlers.hover, {
                border = "rounded",
                focusable = false,
                close_events = {
                    "CursorMoved", "CursorMovedI", "BufHidden",
                    "InsertLeave", "WinScrolled", "FocusLost"
                },
            }
        )

        -- Python virtual environment detection
        local function get_python_path()
            local venv_path = vim.fn.getenv("VIRTUAL_ENV")
            if venv_path ~= vim.NIL and venv_path ~= "" then
                return venv_path .. "/bin/python"
            end

            -- Check for .venv directory
            if vim.fn.isdirectory(".venv") == 1 then
                return vim.fn.getcwd() .. "/.venv/bin/python"
            end

            -- Check for venv directory
            if vim.fn.isdirectory("venv") == 1 then
                return vim.fn.getcwd() .. "/venv/bin/python"
            end

            return "python3"
        end

        -- Open location in a tab (reuse tab if file is already open)
        local function open_lsp_location_in_tab(loc)
            -- Location can be Location or LocationLink
            local uri = loc.uri or loc.targetUri
            local range = loc.range or loc.targetSelectionRange or loc.targetRange
            if not (uri and range) then
                return
            end

            local fname = vim.uri_to_fname(uri)
            local lnum = (range.start and range.start.line or 0) + 1
            local col = (range.start and range.start.character or 0)

            local cur = vim.api.nvim_get_current_buf()
            local cur_name = vim.api.nvim_buf_get_name(cur)

            -- Same file: just jump
            if cur_name == fname then
                pcall(vim.api.nvim_win_set_cursor, 0, {lnum, col})
                vim.cmd("normal! zz")
                return
            end

            -- Look for an existing tab showing this file
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

            -- Open in a new tab
            vim.cmd("tab drop " .. vim.fn.fnameescape(fname))
            pcall(vim.api.nvim_win_set_cursor, 0, {lnum, col})
            vim.cmd("normal! zz")
        end

        -- Generic handler for LSP locations -> open in tabs
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

            -- Result can be a single location or a list
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

        -- Pick correct offset encoding for make_position_params
        local function make_pos_params(bufnr)
            bufnr = bufnr or vim.api.nvim_get_current_buf()
            local clients = vim.lsp.get_clients({ bufnr = bufnr })
            local encoding = "utf-16"  -- default fallback

            -- Use encoding from first available client
            if clients and #clients > 0 then
                encoding = clients[1].offset_encoding or "utf-16"
            end

            -- Get current cursor position
            local row, col = unpack(vim.api.nvim_win_get_cursor(0))

            return {
                textDocument = vim.lsp.util.make_text_document_params(bufnr),
                position = {
                    line = row - 1,  -- LSP uses 0-based indexing
                    character = col
                }
            }
        end

        -- Enforce tab behavior for these LSP requests
        vim.lsp.handlers["textDocument/definition"] =
            handle_locations_in_tabs
        vim.lsp.handlers["textDocument/declaration"] =
            handle_locations_in_tabs
        vim.lsp.handlers["textDocument/typeDefinition"] =
            handle_locations_in_tabs
        vim.lsp.handlers["textDocument/implementation"] =
            handle_locations_in_tabs

        -- Key mappings for LSP with tab navigation
        local function on_attach(client, bufnr)
            local opts = {buffer = bufnr, silent = true}

            -- Manual signature help with Ctrl+k (simplified unified style)
            vim.keymap.set({"n", "i"}, "<C-k>", function()
                vim.lsp.buf.signature_help()
            end, {
                buffer = bufnr,
                silent = true,
                desc = "Show signature help (unified style)"
            })

            -- References in quickfix
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

            -- Custom LSP functions that force tab behavior
            local function definition_in_tab()
                local params = make_pos_params()
                vim.lsp.buf_request(0, "textDocument/definition", params,
                    function(err, result)
                        if err then
                            vim.notify("LSP error: " .. (err.message or ""),
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
                vim.lsp.buf_request(0, "textDocument/declaration", params,
                    function(err, result)
                        if err then
                            vim.notify("LSP error: " .. (err.message or ""),
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
                vim.lsp.buf_request(0, "textDocument/implementation", params,
                    function(err, result)
                        if err then
                            vim.notify("LSP error: " .. (err.message or ""),
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

            -- Navigation with explicit tab functions
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

            -- Override Ctrl+LeftMouse for this buffer
            vim.keymap.set("n", "<C-LeftMouse>", definition_in_tab,
                vim.tbl_extend("force", opts,
                {desc = "Go to definition (mouse)"}))

            -- Documentation
            vim.keymap.set("n", "K", vim.lsp.buf.hover,
                vim.tbl_extend("force", opts,
                {desc = "Show hover info"}))

            -- Code actions (these are also mapped in keymaps.lua)
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action,
                vim.tbl_extend("force", opts,
                {desc = "Code action"}))

            vim.keymap.set("n", "<leader>cn", vim.lsp.buf.rename,
                vim.tbl_extend("force", opts,
                {desc = "Rename Symbol"}))

            -- Diagnostics navigation
            vim.keymap.set("n", "[d", vim.diagnostic.goto_prev,
                vim.tbl_extend("force", opts,
                {desc = "Previous diagnostic"}))

            vim.keymap.set("n", "]d", vim.diagnostic.goto_next,
                vim.tbl_extend("force", opts,
                {desc = "Next diagnostic"}))

            -- Show line diagnostics
            vim.keymap.set("n", "<leader>xx", function()
                local diagnostic_opts = {
                    focusable = false,
                    close_events = {"BufLeave", "CursorMoved",
                        "InsertEnter", "FocusLost"},
                    border = "rounded",
                    source = "always",
                    prefix = " ",
                    scope = "line"
                }
                vim.diagnostic.open_float(nil, diagnostic_opts)
            end, vim.tbl_extend("force", opts,
                {desc = "Show line diagnostics"}))

            vim.keymap.set("n", "gl", function()
                local diagnostic_opts = {
                    focusable = false,
                    close_events = {"BufLeave", "CursorMoved",
                        "InsertEnter", "FocusLost"},
                    border = "rounded",
                    source = "always",
                    prefix = " ",
                    scope = "line"
                }
                vim.diagnostic.open_float(nil, diagnostic_opts)
            end, vim.tbl_extend("force", opts,
                {desc = "Show line diagnostics"}))

            -- Format
            vim.keymap.set("n", "<leader>f", function()
                vim.lsp.buf.format({async = true})
            end, vim.tbl_extend("force", opts,
                {desc = "Format buffer"}))

            -- Signature help is handled by lsp-signature plugin
            -- Do not add manual Ctrl+k mapping here
        end -- end on_attach

        -- Force disable underlines for all diagnostic types
        vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", {
            underline = false,
            undercurl = false,
            sp = "NONE"
        })

        vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", {
            underline = false,
            undercurl = false,
            sp = "NONE"
        })

        vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", {
            underline = false,
            undercurl = false,
            sp = "NONE"
        })

        vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", {
            underline = false,
            undercurl = false,
            sp = "NONE"
        })

        -- Diagnostic configuration with modern API
        vim.diagnostic.config({
            -- Disable virtual text (text at end of line)
            virtual_text = false,
            -- Show icons in sign column using modern API
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = "☣",
                    [vim.diagnostic.severity.WARN] = "⚠",
                    [vim.diagnostic.severity.HINT] = "💡",
                    [vim.diagnostic.severity.INFO] = "🛈"
                }
            },
            -- Disable underlines completely
            underline = false,
            -- Don't update in insert mode for performance
            update_in_insert = false,
            -- Sort by severity
            severity_sort = true,
            -- Floating window configuration
            float = {
                border = "rounded",
                source = "always",
                header = "",
                prefix = "",
                -- Compact format
                format = function(diagnostic)
                    return string.format("%s: %s",
                        diagnostic.source or "LSP",
                        diagnostic.message)
                end
            }
        })

        -- Debug function to check if diagnostics are working
        local function debug_diagnostics()
            local diagnostics = vim.diagnostic.get(0)
            print("Diagnostics count:", #diagnostics)
            print("Signcolumn setting:", vim.wo.signcolumn)
            print("Testing icons: ☣ ⚠ 💡 🛈")

            -- Force refresh signs
            vim.diagnostic.show(0, 0, diagnostics)

            for i, diag in ipairs(diagnostics) do
                print(string.format("Line %d: %s [%s]",
                    diag.lnum + 1, diag.message, diag.severity))
            end
        end

        -- Add debug command
        vim.api.nvim_create_user_command("DiagnosticsDebug",
            debug_diagnostics, {desc = "Debug diagnostics"})

        -- Debug command for unified signature help
        vim.api.nvim_create_user_command("SignatureDebug", function()
            print("=== Signature Help Conflict Debug ===")

            -- Check loaded cmp modules
            print("Checking for CMP conflicts:")
            for name, _ in pairs(package.loaded) do
                if name:match("cmp") then
                    print("  📦 " .. name)
                end
            end

            -- Check LSP clients
            local clients = vim.lsp.get_clients({ bufnr = 0 })
            print("Active LSP clients: " .. #clients)

            for _, client in pairs(clients) do
                print("  - " .. client.name)
                if client.supports_method("textDocument/signatureHelp") then
                    print("    ✅ Supports signature help")
                    -- Check capabilities
                    local caps = client.server_capabilities
                    if caps and caps.signatureHelpProvider then
                        print("    📝 SignatureHelp provider enabled")
                    end
                else
                    print("    ❌ No signature help support")
                end
            end

            print("Our signature help override is active")
            print("CMP signature help capabilities: DISABLED ✅")

        end, {desc = "Debug signature help conflicts"})

        -- Simple test command
        vim.api.nvim_create_user_command("SigHelp", function()
            vim.lsp.buf.signature_help()
        end, {desc = "Show unified signature help"})

        -- Test original vs our override
        vim.api.nvim_create_user_command("SigTest", function()
            print("=== Testing Signature Help Override ===")
            print("Our function will bypass any LSP server styling")
            print("Press Ctrl+k to test the overridden version")

            -- Show what we're overriding
            vim.schedule(function()
                vim.lsp.buf.signature_help()
            end)
        end, {desc = "Test signature help override"})

        -- Force reapply signature help override
        vim.api.nvim_create_user_command("SigFix", function()
            -- First close any existing windows
            if current_sig_win and vim.api.nvim_win_is_valid(current_sig_win) then
                pcall(vim.api.nvim_win_close, current_sig_win, true)
                current_sig_win = nil
            end

            -- Clear the main autocmd group
            pcall(vim.api.nvim_del_augroup_by_name, "SigAutoClose")

            print("✅ Signature help windows closed and autocmd groups cleared!")
        end, {desc = "Close signature help windows and clear autocmds"})

        -- Emergency command to close all floating windows
        vim.api.nvim_create_user_command("SigClose", function()
            local closed_count = 0

            -- Close all floating windows
            for _, win in ipairs(vim.api.nvim_list_wins()) do
                local config = vim.api.nvim_win_get_config(win)
                if config.relative ~= "" then
                    pcall(vim.api.nvim_win_close, win, true)
                    closed_count = closed_count + 1
                end
            end

            -- Clear the tracking variable
            current_sig_win = nil

            -- Clear the autocmd group
            pcall(vim.api.nvim_del_augroup_by_name, "SigAutoClose")

            print(string.format("✅ Closed %d floating windows and cleared SigAutoClose group", closed_count))
        end, {desc = "Emergency close all floating windows and clear autocmds"})

        -- Test command to check autocmd state
        vim.api.nvim_create_user_command("SigTest", function()
            print("=== Signature Help State ===")
            print("Current signature window: " .. (current_sig_win and "EXISTS" or "NONE"))
            print("Testing new autocmd approach with SigAutoClose group")
            print("")
            print("Test steps:")
            print("1. Press Ctrl+k to open signature help")
            print("2. Move cursor (arrow keys) - should auto-close")
            print("3. Press Esc - should also close")
            print("4. Try :SigClose for emergency close")
        end, {desc = "Test signature help state"})

        -- Force enable signcolumn and refresh diagnostics
        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function()
                vim.wo.signcolumn = "yes"
                vim.diagnostic.show()
            end
        })

        -- Make virtual text colors more subtle (kept for potential
        -- re-enabling)
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

        -- Server configurations using modern vim.lsp.config API
        local servers = {
            -- Python with Django support
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
            -- TypeScript/JavaScript
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
            -- Vue.js
            vue_ls = {
                filetypes = {"vue"},
                init_options = {
                    typescript = {
                        tsdk = vim.fn.stdpath("data") ..
                            "/mason/packages/vue-language-server" ..
                            "/node_modules/typescript/lib"
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
            -- CSS with embedded support
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
            -- Emmet for HTML/CSS
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
            -- Go
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
            -- C/C++
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
            -- Docker
            dockerls = {
                root_markers = {"Dockerfile", ".git"}
            },
            -- YAML
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
            -- JSON
            jsonls = {
                settings = {
                    json = {
                        schemas = require("schemastore").json.schemas(),
                        validate = {enable = true}
                    }
                },
                root_markers = {"package.json", ".git"}
            },
            -- Lua
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
            },
            -- Markdown
            marksman = {
                filetypes = {"markdown", "markdown.mdx"},
                settings = {
                    marksman = {
                        completion = {
                            enabled = true,
                        },
                        hover = {
                            enabled = true,
                        },
                    }
                },
                root_markers = {".git", ".marksman.toml"}
            },
        }

        -- Setup servers using modern vim.lsp.config API
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

        -- Enable LSP only when relevant filetype is opened
        vim.api.nvim_create_autocmd("FileType", {
            callback = function(args)
                local ft = vim.bo[args.buf].filetype
                for name, cfg in pairs(servers) do
                    if cfg.filetypes and vim.tbl_contains(
                        cfg.filetypes, ft) then
                        local existing = vim.lsp.get_clients({
                            name = name,
                            bufnr = args.buf,
                        })
                        if #existing == 0 then
                            vim.lsp.enable(name)
                        end
                        break
                    end
                end
            end,
        })

        -- Auto-stop unused LSP clients when buffer is deleted
        vim.api.nvim_create_autocmd("BufDelete", {
            callback = function(args)
                vim.defer_fn(function()
                    for _, client in ipairs(vim.lsp.get_clients(
                        { bufnr = args.buf })) do
                        local bufs = vim.lsp.get_buffers_by_client_id(
                            client.id)
                        if #bufs == 0 then
                            vim.lsp.stop_client(client.id)
                        end
                    end
                end, 200)
            end,
        })

        -- Force set handlers after LSP is loaded (double insurance)
        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(args)
                -- Prevent multiple LSP clients of same type for same
                -- root dir
                local client = vim.lsp.get_client_by_id(
                    args.data.client_id)
                if client then
                    local root = client.config.root_dir
                    for _, c in pairs(vim.lsp.get_clients()) do
                        if c.name == client.name and
                           c.config.root_dir == root and
                           c.id ~= client.id then
                            vim.schedule(function()
                                vim.lsp.stop_client(client.id)
                            end)
                            break
                        end
                    end
                end

                -- Re-apply our custom handlers to ensure they're not
                -- overridden
                vim.lsp.handlers["textDocument/definition"] =
                    handle_locations_in_tabs
                vim.lsp.handlers["textDocument/declaration"] =
                    handle_locations_in_tabs
                vim.lsp.handlers["textDocument/typeDefinition"] =
                    handle_locations_in_tabs
                vim.lsp.handlers["textDocument/implementation"] =
                    handle_locations_in_tabs

                -- FORCE override vim.lsp.buf.signature_help after LSP attaches
                -- Custom floating window function with proper padding and title
                local function create_signature_window(content, title)
                    -- Create buffer
                    local buf = vim.api.nvim_create_buf(false, true)
                    vim.bo[buf].bufhidden = 'wipe'
                    vim.bo[buf].buftype = 'nofile'
                    vim.bo[buf].swapfile = false

                    -- Set buffer content with padding
                    local padded_lines = {}
                    for _, line in ipairs(content) do
                        table.insert(padded_lines, " " .. line .. " ")
                    end
                    vim.api.nvim_buf_set_lines(buf, 0, -1, false, padded_lines)

                    -- Calculate window size
                    local max_width = 0
                    for _, line in ipairs(padded_lines) do
                        max_width = math.max(max_width, #line)
                    end
                    max_width = math.min(max_width + 2, 82) -- Add border space
                    local height = #padded_lines

                    -- Window options
                    local opts = {
                        relative = 'cursor',
                        row = 1,
                        col = 0,
                        width = max_width,
                        height = height,
                        style = 'minimal',
                        border = 'rounded',
                        title = title or "Function Signature",
                        title_pos = 'left'
                    }

                    -- Create window
                    local win = vim.api.nvim_open_win(buf, false, opts)

                    -- Set window options
                    vim.wo[win].wrap = false
                    vim.wo[win].linebreak = false
                    vim.wo[win].cursorline = false

                    -- Auto-close events
                    vim.api.nvim_create_autocmd({'CursorMoved', 'CursorMovedI', 'InsertLeave', 'BufHidden'}, {
                        buffer = buf,
                        once = true,
                        callback = function()
                            pcall(vim.api.nvim_win_close, win, true)
                        end
                    })

                    return win
                end

                vim.lsp.buf.signature_help = function()
                    local params = vim.lsp.util.make_position_params()

                    vim.lsp.buf_request(0, "textDocument/signatureHelp", params,
                        function(err, result)
                            if err or not result or not result.signatures or
                               #result.signatures == 0 then
                                return
                            end

                            local sig = result.signatures[1]
                            if not sig or not sig.label then
                                return
                            end

                            -- Handle multi-line content
                            local max_width = 76  -- Leave space for padding and border
                            local lines = {}

                            -- Split long signature into multiple lines if needed
                            local text = sig.label
                            if #text > max_width then
                                local words = vim.split(text, " ")
                                local current_line = ""

                                for _, word in ipairs(words) do
                                    if #current_line + #word + 1 <= max_width then
                                        if current_line == "" then
                                            current_line = word
                                        else
                                            current_line = current_line .. " " .. word
                                        end
                                    else
                                        if current_line ~= "" then
                                            table.insert(lines, current_line)
                                        end
                                        current_line = word
                                    end
                                end

                                if current_line ~= "" then
                                    table.insert(lines, current_line)
                                end
                            else
                                -- Single line
                                table.insert(lines, text)
                            end

                            -- Extract function name from signature for title
                            local func_name = text:match("([%w_]+)%(") or "Function Signature"

                            create_signature_window(lines, func_name)
                        end)
                end
            end
        })
    end
}