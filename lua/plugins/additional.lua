-- ~/.config/nvim/lua/plugins/additional.lua
-- Additional essential plugins for IDE functionality

return {
    -- JSON schemas for better JSON editing
    {
        "b0o/schemastore.nvim",
        lazy = true
    },

    -- Treesitter for better syntax highlighting.
    {
        "nvim-treesitter/nvim-treesitter",
        enabled = true,
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = {
                    "python", "javascript", "typescript", "vue",
                    "go", "c", "cpp",  "dockerfile", "bash", "markdown",
                    "gitignore", "htmldjango",
                    "lua", "json", "yaml", "html", "css", "scss",
                },
                sync_install = false,
                auto_install = false,
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                    disable = {}
                },
                indent = {
                    enable = true,
                    disable = {}
                }
            })
        end
    },

    -- Fuzzy finder with updated keymaps and cwd detection
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = "make"
            }
        },
        config = function()
            local telescope = require("telescope")

            telescope.setup({
                defaults = {
                    prompt_prefix = " ",
                    selection_caret = " ",
                    path_display = {"truncate"},
                    file_ignore_patterns = {
                        "node_modules", ".git/", "%.pyc", "__pycache__", ".venv",
                        "venv", ".env", "migrations/", "%.min%.js", "%.min%.css",
                        "static/admin/", "media/"
                    },
                    layout_strategy = "horizontal",
                    sorting_strategy = "ascending",
                    layout_config = {
                        prompt_position = "top",
                        width = 0.9,
                        height = 0.8,
                        preview_cutoff = 40,
                        horizontal = {
                            preview_width = 0.6,
                            results_width = 0.4
                        },
                        vertical = {
                            mirror = false
                        }
                    }
                },
                pickers = {
                    find_files = {
                        hidden = true,
                        find_command = {
                            "rg", "--files", "--hidden",
                            "--glob", "!**/.git/*",
                            "--glob", "!**/__pycache__/*",
                            "--glob", "!**/.venv/*"
                        }
                    },
                    live_grep = {
                        additional_args = function()
                            return {
                                "--hidden",
                                "--glob", "!**/.git/*",
                                "--glob", "!**/__pycache__/*",
                                "--glob", "!**/.venv/*",
                                "--glob", "!**/migrations/*"
                            }
                        end
                    },
                    buffers = {
                        sort_mru = true,
                        ignore_current_buffer = false
                    }
                }
            })

            telescope.load_extension("fzf")

            -- Helper function to get project root.
            local function get_project_root()
                -- First, try to get nvim-tree root if it's available.
                local has_nvim_tree, nvim_tree_api = pcall(require,
                    "nvim-tree.api")
                if has_nvim_tree then
                    local tree = nvim_tree_api.tree
                    if tree.is_visible() then
                        local root_node = tree.get_root()
                        if root_node and root_node.absolute_path then
                            return root_node.absolute_path
                        end
                    end
                end

                -- Second, try current working directory.
                local cwd = vim.fn.getcwd()
                if cwd and cwd ~= "" then
                    return cwd
                end

                -- Fallback to current buffer's directory.
                local bufname = vim.api.nvim_buf_get_name(0)
                if bufname == "" then
                    return vim.fn.getcwd()
                end

                local bufdir = vim.fn.fnamemodify(bufname, ":p:h")

                -- Search for common project root markers.
                local root_markers = {
                    ".git", "package.json", "pyproject.toml",
                    "setup.py", "Cargo.toml", "go.mod"
                }

                local current = bufdir
                while current ~= "/" do
                    for _, marker in ipairs(root_markers) do
                        if vim.fn.isdirectory(current .. "/" .. marker) == 1 or
                        vim.fn.filereadable(current .. "/" .. marker) == 1 then
                            return current
                        end
                    end
                    current = vim.fn.fnamemodify(current, ":h")
                end

                return bufdir
            end
        end
    },

    -- Git integration with updated keymaps.
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup({
                signs = {
                    add = {text = "│"},
                    change = {text = "│"},
                    delete = {text = "_"},
                    topdelete = {text = "‾"},
                    changedelete = {text = "~"},
                    untracked = {text = "┆"}
                },
                signcolumn = true,
                numhl = false,
                linehl = false,
                word_diff = false,
                watch_gitdir = {interval = 1000, follow_files = true},
                attach_to_untracked = true,
                current_line_blame = false,
                current_line_blame_opts = {
                    virt_text = true,
                    virt_text_pos = "eol",
                    delay = 1000,
                    ignore_whitespace = false
                },
                preview_config = {
                    border = "single",
                    style = "minimal",
                    relative = "cursor",
                    row = 0,
                    col = 1
                },
                on_attach = function(bufnr)
                    local gs = package.loaded.gitsigns
                    local function map(mode, l, r, o)
                        o = o or {}
                        o.buffer = bufnr
                        vim.keymap.set(mode, l, r, o)
                    end

                    map("n", "]c", function()
                        if vim.wo.diff then return "]c" end
                        vim.schedule(gs.next_hunk)
                        return "<Ignore>"
                    end, {expr = true, desc = "Next hunk"})

                    map("n", "[c", function()
                        if vim.wo.diff then return "[c" end
                        vim.schedule(gs.prev_hunk)
                        return "<Ignore>"
                    end, {expr = true, desc = "Previous hunk"})

                    -- Updated git keymaps using <leader>g prefix
                    map("n", "<leader>gs", gs.stage_hunk, {desc = "Stage hunk"})
                    map("n", "<leader>gr", gs.reset_hunk, {desc = "Reset hunk"})
                    map("n", "<leader>gp", gs.preview_hunk, {desc = "Preview hunk"})
                    map("n", "<leader>gb", function()
                        gs.blame_line({full = true})
                    end, {desc = "Blame line"})
                    map("n", "<leader>gt", gs.toggle_current_line_blame,
                        {desc = "Toggle blame"})
                    map("n", "<leader>gd", gs.diffthis, {desc = "Diff this"})
                end
            })
        end
    },

    -- Terminal integration with updated keymaps
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        config = function()
            require("toggleterm").setup({
                size = 20,
                open_mapping = [[<c-\>]],
                hide_numbers = true,
                shade_terminals = true,
                shading_factor = 2,
                start_in_insert = true,
                insert_mappings = true,
                persist_size = true,
                direction = "float",
                close_on_exit = true,
                shell = vim.o.shell,
                float_opts = {
                    border = "curved",
                    winblend = 0,
                    highlights = {border = "Normal", background = "Normal"}
                }
            })

            local Terminal = require("toggleterm.terminal").Terminal

            local function get_python_venv()
                if vim.fn.isdirectory(".venv") == 1 then
                    return ".venv/bin/python"
                elseif vim.fn.isdirectory("venv") == 1 then
                    return "venv/bin/python"
                else
                    return "python3"
                end
            end

            local python = Terminal:new({
                cmd = get_python_venv(),
                hidden = true,
                direction = "float"
            })

            function _PYTHON_TOGGLE() python:toggle() end

            local django = Terminal:new({
                cmd = get_python_venv() .. " manage.py shell",
                hidden = true,
                direction = "float"
            })

            function _DJANGO_SHELL_TOGGLE() django:toggle() end

            local runserver = Terminal:new({
                cmd = get_python_venv() .. " manage.py runserver",
                hidden = true,
                direction = "horizontal"
            })

            function _DJANGO_RUNSERVER() runserver:toggle() end

            local node = Terminal:new({
                cmd = "node",
                hidden = true,
                direction = "float"
            })

            function _NODE_TOGGLE() node:toggle() end

            -- Updated terminal keymaps using <leader>xt prefix
            vim.keymap.set("n", "<leader>xtf",
                "<cmd>ToggleTerm direction=float<cr>",
                {desc = "Float terminal"})
            vim.keymap.set("n", "<leader>xth",
                "<cmd>ToggleTerm direction=horizontal<cr>",
                {desc = "Horizontal terminal"})
            vim.keymap.set("n", "<leader>xtv",
                "<cmd>ToggleTerm direction=vertical size=80<cr>",
                {desc = "Vertical terminal"})
            vim.keymap.set("n", "<leader>xtp", "<cmd>lua _PYTHON_TOGGLE()<CR>",
                {desc = "Python terminal"})
            vim.keymap.set("n", "<leader>xtd", "<cmd>lua _DJANGO_SHELL_TOGGLE()<CR>",
                {desc = "Django shell"})
            vim.keymap.set("n", "<leader>xtr", "<cmd>lua _DJANGO_RUNSERVER()<CR>",
                {desc = "Django runserver"})
            vim.keymap.set("n", "<leader>xtn", "<cmd>lua _NODE_TOGGLE()<CR>",
                {desc = "Node terminal"})
        end
    },

    -- Auto pairs
    {
        "windwp/nvim-autopairs",
        enabled = true,
        event = "InsertEnter",
        config = function()
            require("nvim-autopairs").setup({
                disable_filetype = { "TelescopePrompt", "spectre_panel" },
                disable_in_macro = false,
                disable_in_visualblock = false,
                disable_in_replace_mode = true,
                ignored_next_char = [=[[%w%%%'%[%"%.%`%$]]=],
                enable_moveright = true,
                enable_afterquote = false,
                enable_check_bracket_line = false,
                enable_bracket_in_quote = false,
                check_ts = false,
                map_cr = false,
                map_bs = false,
            })

            local cmp_ap = require("nvim-autopairs.completion.cmp")
            local cmp = require("cmp")
            cmp.event:on("confirm_done", cmp_ap.on_confirm_done())

            local npairs = require("nvim-autopairs")
            npairs.clear_rules()
        end
    },

    -- Comment plugin
    {
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup({
                toggler = {line = "gcc", block = "gbc"},
                opleader = {line = "gc", block = "gb"},
                extra = {above = "gcO", below = "gco", eol = "gcA"},
                mappings = {basic = true, extra = true},
                pre_hook = nil,
                post_hook = nil
            })
        end
    },

    -- Python virtual environment detection with updated keymap
    {
        "linux-cultist/venv-selector.nvim",
        dependencies = {
            "neovim/nvim-lspconfig",
            "nvim-telescope/telescope.nvim",
        },
        config = function()
            require("venv-selector").setup({
                name = {".venv", "venv"},
                auto_refresh = true
            })
            -- Updated keymap using <leader>c prefix for code-related actions
            vim.keymap.set("n", "<leader>vc", "<cmd>VenvSelect<cr>",
                {desc = "Select Python venv"})
        end
    },

    -- Indent guides
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        config = function()
            local hooks = require("ibl.hooks")

            hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
                vim.api.nvim_set_hl(0, "IblIndent", { fg = "#2a2a37" })
                vim.api.nvim_set_hl(0, "IblScope", { fg = "#485093" })
            end)

            require("ibl").setup({
                indent = {
                    char = "▏",
                    tab_char = "▏",
                    highlight = "IblIndent",
                },
                scope = {
                    enabled = true,
                    show_start = false,
                    show_end = false,
                    highlight = "IblScope",
                    include = {
                        node_type = {
                            ["*"] = {
                                "class", "return_statement", "function", "method",
                                "^if", "^while", "jsx_element", "^for", "^object",
                                "^table", "block", "arguments", "if_statement",
                                "else_clause", "jsx_self_closing_element",
                                "try_statement", "catch_clause", "import_statement",
                                "operation_type",
                            },
                        },
                    },
                },
                exclude = {
                    filetypes = {
                        "help", "alpha", "dashboard", "neo-tree", "NvimTree",
                        "Trouble", "trouble", "lazy", "mason", "notify",
                        "toggleterm", "lazyterm",
                    },
                    buftypes = {
                        "terminal", "nofile", "quickfix", "prompt",
                    },
                },
            })
        end
    },

    -- Flash.nvim - quick navigation with updated keymaps
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        config = function()
            require("flash").setup({
                labels = "asdfghjklqwertyuiopzxcvbnm",
                search = {
                    multi_window = true,
                    forward = true,
                    wrap = true,
                },
                jump = {
                    jumplist = true,
                    pos = "start",
                    history = false,
                    register = false,
                    nohlsearch = false,
                },
                modes = {
                    search = {
                        enabled = true,
                    },
                    char = {
                        enabled = true,
                        jump_labels = false,
                    },
                },
            })
        end,
        keys = {
            { "<leader>fs", mode = { "n", "x", "o" },
              function() require("flash").jump() end, desc = "Flash Jump" },
            { "<leader>fS", mode = { "n", "x", "o" },
              function() require("flash").treesitter() end, desc = "Flash Treesitter" },
            { "<leader>fr", mode = "o",
              function() require("flash").remote() end, desc = "Flash Remote" },
            { "<leader>fR", mode = { "o", "x" },
              function() require("flash").treesitter_search() end, desc = "Flash Search" },
        },
    },
}