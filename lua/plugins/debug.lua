-- ~/.config/nvim/lua/plugins/debug.lua
-- Debug Adapter Protocol (DAP) configuration

return {
    -- Core DAP plugin
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            -- DAP UI for better debugging experience
            {
                "rcarriga/nvim-dap-ui",
                dependencies = {"nvim-neotest/nvim-nio"}
            },
            -- Virtual text for debugging
            "theHamsta/nvim-dap-virtual-text",
            -- Python DAP
            "mfussenegger/nvim-dap-python",
            -- Node.js DAP
            "mxsdev/nvim-dap-vscode-js",
        },
        keys = {
            {"<F9>", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint"},
            {"<S-F9>", function()
                vim.ui.input({prompt = "Breakpoint condition: "}, function(condition)
                    require("dap").set_breakpoint(condition)
                end)
            end, desc = "Conditional Breakpoint"},
            {"<F5>", function() require("dap").continue() end, desc = "Continue"},
            {"<S-F5>", function() require("dap").terminate() end, desc = "Terminate"},
            {"<F10>", function() require("dap").step_over() end, desc = "Step Over"},
            {"<F11>", function() require("dap").step_into() end, desc = "Step Into"},
            {"<S-F11>", function() require("dap").step_out() end, desc = "Step Out"},
            {"<leader>dr", function() require("dap").repl.open() end, desc = "Open REPL"},
            {"<leader>dl", function() require("dap").run_last() end, desc = "Run Last"},
            {"<leader>dh", function() require("dap.ui.widgets").hover() end, desc = "Hover Variables"},
            {"<leader>ds", function()
                local widgets = require("dap.ui.widgets")
                widgets.sidebar(widgets.scopes).open()
            end, desc = "Sidebar Scopes"},
        },
        config = function()
            local dap = require("dap")
            local dapui = require("dapui")

            -- DAP UI setup
            dapui.setup({
                icons = {
                    expanded = "▾",
                    collapsed = "▸",
                    current_frame = "▸"
                },
                mappings = {
                    expand = {"<CR>", "<2-LeftMouse>"},
                    open = "o",
                    remove = "d",
                    edit = "e",
                    repl = "r",
                    toggle = "t",
                },
                element_mappings = {},
                expand_lines = vim.fn.has("nvim-0.7") == 1,
                layouts = {
                    {
                        elements = {
                            {id = "scopes", size = 0.25},
                            {id = "breakpoints", size = 0.25},
                            {id = "stacks", size = 0.25},
                            {id = "watches", size = 0.25},
                        },
                        size = 40,
                        position = "left",
                    },
                    {
                        elements = {
                            {id = "repl", size = 0.5},
                            {id = "console", size = 0.5},
                        },
                        size = 0.25,
                        position = "bottom",
                    },
                },
                controls = {
                    enabled = true,
                    element = "repl",
                    icons = {
                        pause = "",
                        play = "",
                        step_into = "",
                        step_over = "",
                        step_out = "",
                        step_back = "",
                        run_last = "▶▶",
                        terminate = "⏹",
                    },
                },
                floating = {
                    max_height = nil,
                    max_width = nil,
                    border = "single",
                    mappings = {close = {"q", "<Esc>"}},
                },
                windows = {indent = 1},
                render = {
                    max_type_length = nil,
                    max_value_lines = 100,
                }
            })

            -- Virtual text setup
            require("nvim-dap-virtual-text").setup({
                enabled = true,
                enabled_commands = true,
                highlight_changed_variables = true,
                highlight_new_as_changed = false,
                show_stop_reason = true,
                commented = false,
                only_first_definition = true,
                all_references = false,
                filter_references_pattern = '<module',
                virt_text_pos = 'eol',
                all_frames = false,
                virt_lines = false,
                virt_text_win_col = nil
            })

            -- Auto open/close UI
            dap.listeners.after.event_initialized["dapui_config"] = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated["dapui_config"] = function()
                dapui.close()
            end
            dap.listeners.before.event_exited["dapui_config"] = function()
                dapui.close()
            end

            -- Detect Python executable in virtual environment
            local function get_python_path()
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

            -- Python DAP configuration
            require("dap-python").setup(get_python_path())

            -- Add Django configuration
            table.insert(dap.configurations.python, {
                type = "python",
                request = "launch",
                name = "Django",
                program = vim.fn.getcwd() .. "/manage.py",
                args = {"runserver", "--noreload"},
                django = true,
                justMyCode = false,
                console = "integratedTerminal",
                env = function()
                    local variables = {}
                    for k, v in pairs(vim.fn.environ()) do
                        variables[k] = v
                    end
                    variables["PYTHONPATH"] = vim.fn.getcwd()
                    return variables
                end,
            })

            -- Add Flask configuration
            table.insert(dap.configurations.python, {
                type = "python",
                request = "launch",
                name = "Flask",
                module = "flask",
                env = {
                    FLASK_APP = "app.py",
                    FLASK_ENV = "development",
                },
                args = {"run", "--debug"},
                jinja = true,
                justMyCode = false,
                console = "integratedTerminal",
            })

            -- Node.js/JavaScript DAP configuration
            require("dap-vscode-js").setup({
                adapters = {"pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost"},
                debugger_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter",
                debugger_cmd = {"js-debug-adapter"},
            })

            -- JavaScript/TypeScript configurations
            for _, language in ipairs({"typescript", "javascript"}) do
                dap.configurations[language] = {
                    {
                        type = "pwa-node",
                        request = "launch",
                        name = "Launch file",
                        program = "${file}",
                        cwd = "${workspaceFolder}",
                    },
                    {
                        type = "pwa-node",
                        request = "attach",
                        name = "Attach",
                        processId = require("dap.utils").pick_process,
                        cwd = "${workspaceFolder}",
                    },
                    {
                        type = "pwa-node",
                        request = "launch",
                        name = "Debug Jest Tests",
                        runtimeExecutable = "node",
                        runtimeArgs = {
                            "./node_modules/jest/bin/jest.js",
                            "--runInBand",
                        },
                        rootPath = "${workspaceFolder}",
                        cwd = "${workspaceFolder}",
                        console = "integratedTerminal",
                        internalConsoleOptions = "neverOpen",
                    },
                    {
                        type = "pwa-chrome",
                        request = "launch",
                        name = "Launch Chrome",
                        url = "http://localhost:3000",
                        webRoot = "${workspaceFolder}",
                    },
                }
            end

            -- Breakpoint signs
            vim.fn.sign_define("DapBreakpoint", {
                text = "🔴",
                texthl = "DapBreakpoint",
                linehl = "",
                numhl = ""
            })
            vim.fn.sign_define("DapBreakpointCondition", {
                text = "🟡",
                texthl = "DapBreakpointCondition",
                linehl = "",
                numhl = ""
            })
            vim.fn.sign_define("DapLogPoint", {
                text = "💬",
                texthl = "DapLogPoint",
                linehl = "",
                numhl = ""
            })
            vim.fn.sign_define("DapStopped", {
                text = "→",
                texthl = "DapStopped",
                linehl = "DapStoppedLine",
                numhl = ""
            })
            vim.fn.sign_define("DapBreakpointRejected", {
                text = "🚫",
                texthl = "DapBreakpointRejected",
                linehl = "",
                numhl = ""
            })

            -- Commands
            vim.api.nvim_create_user_command("DapToggleUI", function()
                dapui.toggle()
            end, {desc = "Toggle DAP UI"})

            vim.api.nvim_create_user_command("DapClearBreakpoints", function()
                dap.clear_breakpoints()
                vim.notify("All breakpoints cleared", vim.log.levels.INFO)
            end, {desc = "Clear all breakpoints"})
        end,
    }
}