-- ~/.config/nvim/lua/plugins/project.lua
-- Project management with automatic root detection

return {
    "ahmedkhalf/project.nvim",
    dependencies = {"nvim-telescope/telescope.nvim"},
    event = "VimEnter",
    keys = {
        {"<leader>fp", "<cmd>Telescope projects<cr>", desc = "Find Projects"},
        {"<leader>pr", "<cmd>ProjectRoot<cr>", desc = "Go to Project Root"},
        {"<leader>pp", "<cmd>Telescope projects<cr>", desc = "Switch Project"},
    },
    config = function()
        require("project_nvim").setup({
            -- Detection methods. Order matters - first match wins.
            detection_methods = { "lsp", "pattern" },

            -- Patterns to detect project root
            patterns = {
                ".git",
                "_darcs",
                ".hg",
                ".bzr",
                ".svn",
                "Makefile",
                "package.json",
                "pyproject.toml",
                "setup.py",
                "setup.cfg",
                "requirements.txt",
                "Pipfile",
                "poetry.lock",
                "composer.json",
                "Cargo.toml",
                "go.mod",
                "mix.exs",
                "CMakeLists.txt",
                ".project", -- Generic project marker
            },

            -- Table of lsp clients to ignore by name
            ignore_lsp = {},

            -- Don't calculate root dir on every buffer enter
            exclude_dirs = {},

            -- Show hidden files in telescope
            show_hidden = false,

            -- When set to false, you will get a message when project.nvim changes your directory
            silent_chdir = true,

            -- What scope to change the directory, valid options are
            -- * global (default)
            -- * tab
            -- * win
            scope_chdir = 'global',

            -- Path where project.nvim will store the project history for use in telescope
            datapath = vim.fn.stdpath("data"),
        })

        -- Telescope integration
        require('telescope').load_extension('projects')

        -- Commands for project management
        vim.api.nvim_create_user_command('ProjectRoot', function()
            local root = require("project_nvim.utils").get_project_root()
            if root then
                vim.cmd("cd " .. root)
                print("Changed to project root: " .. root)
            else
                print("No project root found")
            end
        end, {desc = "Change to project root directory"})

        vim.api.nvim_create_user_command('ProjectInfo', function()
            local root = require("project_nvim.utils").get_project_root()
            local cwd = vim.fn.getcwd()

            print("Current directory: " .. cwd)
            if root then
                print("Project root: " .. root)
                if root ~= cwd then
                    print("Use :ProjectRoot to change to project root")
                end
            else
                print("No project root detected")
            end

            -- Show detected patterns
            local patterns = require("project_nvim.config").options.patterns
            print("Detection patterns: " .. table.concat(patterns, ", "))
        end, {desc = "Show project information"})

        -- Auto-open project files in tabs (integration with existing tab logic)
        local function open_project_file_in_tab(file)
            local current_buf = vim.api.nvim_get_current_buf()
            local current_filetype = vim.bo[current_buf].filetype
            local current_name = vim.fn.bufname(current_buf)

            if current_filetype == "dashboard" or
               (current_name == "" and not vim.bo[current_buf].modified) then
                -- Replace dashboard/empty buffer
                vim.cmd("edit " .. vim.fn.fnameescape(file))
            else
                -- Open in new tab using tab drop
                vim.cmd("tab drop " .. vim.fn.fnameescape(file))
            end
        end

        -- Project-specific commands
        local function setup_project_commands()
            -- Django specific
            vim.api.nvim_create_user_command('DjangoManage', function(opts)
                local root = require("project_nvim.utils").get_project_root()
                if root and vim.fn.filereadable(root .. "/manage.py") == 1 then
                    local cmd = "cd " .. root .. " && python manage.py " .. (opts.args or "")
                    vim.cmd("split")
                    vim.cmd("terminal " .. cmd)
                else
                    print("manage.py not found in project root")
                end
            end, {
                nargs = "*",
                desc = "Run Django management command"
            })

            -- Package.json scripts
            vim.api.nvim_create_user_command('NpmRun', function(opts)
                local root = require("project_nvim.utils").get_project_root()
                if root and vim.fn.filereadable(root .. "/package.json") == 1 then
                    local cmd = "cd " .. root .. " && npm run " .. (opts.args or "")
                    vim.cmd("split")
                    vim.cmd("terminal " .. cmd)
                else
                    print("package.json not found in project root")
                end
            end, {
                nargs = "*",
                desc = "Run npm script"
            })

            -- Python virtual environment activation
            vim.api.nvim_create_user_command('ActivateVenv', function()
                local root = require("project_nvim.utils").get_project_root()
                if not root then
                    print("No project root found")
                    return
                end

                local venv_paths = {
                    root .. "/.venv/bin/activate",
                    root .. "/venv/bin/activate"
                }

                for _, venv_path in ipairs(venv_paths) do
                    if vim.fn.filereadable(venv_path) == 1 then
                        local cmd = "source " .. venv_path
                        vim.cmd("split")
                        vim.cmd("terminal " .. cmd .. " && $SHELL")
                        print("Activated virtual environment: " .. venv_path)
                        return
                    end
                end

                print("No virtual environment found in project")
            end, {desc = "Activate Python virtual environment"})

            -- Git operations in project root
            vim.api.nvim_create_user_command('GitStatus', function()
                local root = require("project_nvim.utils").get_project_root()
                if root and vim.fn.isdirectory(root .. "/.git") == 1 then
                    vim.cmd("cd " .. root)
                    vim.cmd("split")
                    vim.cmd("terminal git status")
                else
                    print("Not a git repository")
                end
            end, {desc = "Show git status in project root"})
        end

        setup_project_commands()

        -- Auto-setup project when opening Neovim
        vim.api.nvim_create_autocmd("VimEnter", {
            callback = function()
                -- Wait for project.nvim to detect root
                vim.defer_fn(function()
                    local root = require("project_nvim.utils").get_project_root()
                    if root then
                        -- Optional: Auto-change to project root
                        -- vim.cmd("cd " .. root)

                        -- Set up project-specific settings
                        local function setup_project_env()
                            -- Python project setup
                            if vim.fn.filereadable(root .. "/manage.py") == 1 then
                                vim.g.project_type = "django"
                            elseif vim.fn.filereadable(root .. "/setup.py") == 1 or
                                   vim.fn.filereadable(root .. "/pyproject.toml") == 1 then
                                vim.g.project_type = "python"
                            elseif vim.fn.filereadable(root .. "/package.json") == 1 then
                                vim.g.project_type = "nodejs"
                            elseif vim.fn.filereadable(root .. "/Cargo.toml") == 1 then
                                vim.g.project_type = "rust"
                            elseif vim.fn.filereadable(root .. "/go.mod") == 1 then
                                vim.g.project_type = "go"
                            end
                        end

                        setup_project_env()
                    end
                end, 500)
            end
        })

        -- Integration with existing LSP configuration to respect project root
        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(args)
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                local project_root = require("project_nvim.utils").get_project_root()

                if project_root and client then
                    -- Ensure LSP respects project boundaries
                    if client.config.root_dir and client.config.root_dir ~= project_root then
                        -- Optional: restart LSP with correct root
                        -- This can be aggressive, so disabled by default
                        -- vim.lsp.stop_client(client.id)
                        -- vim.defer_fn(function()
                        --     vim.cmd("LspStart")
                        -- end, 100)
                    end
                end
            end
        })

        -- Project templates (optional)
        local project_templates = {
            django = {
                files = {
                    "manage.py",
                    "requirements.txt",
                    "settings.py"
                },
                setup_cmd = "python -m venv .venv && source .venv/bin/activate && pip install django"
            },
            flask = {
                files = {
                    "app.py",
                    "requirements.txt"
                },
                setup_cmd = "python -m venv .venv && source .venv/bin/activate && pip install flask"
            },
            nodejs = {
                files = {
                    "package.json",
                    "index.js"
                },
                setup_cmd = "npm init -y && npm install"
            }
        }

        -- Command to create new project from template
        vim.api.nvim_create_user_command('ProjectNew', function(opts)
            local template = opts.args
            if not template or template == "" then
                print("Available templates: " .. table.concat(vim.tbl_keys(project_templates), ", "))
                return
            end

            local tmpl = project_templates[template]
            if not tmpl then
                print("Unknown template: " .. template)
                return
            end

            vim.ui.input({prompt = "Project name: "}, function(name)
                if name and name ~= "" then
                    local project_dir = vim.fn.getcwd() .. "/" .. name
                    vim.fn.mkdir(project_dir, "p")
                    vim.cmd("cd " .. project_dir)

                    -- Create template files
                    for _, file in ipairs(tmpl.files) do
                        vim.fn.writefile({""}, project_dir .. "/" .. file)
                    end

                    print("Created project: " .. name)
                    print("Setup command: " .. tmpl.setup_cmd)
                end
            end)
        end, {
            nargs = "?",
            desc = "Create new project from template"
        })
    end,
}