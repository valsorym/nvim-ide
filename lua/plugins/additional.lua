-- ~/.config/nvim/lua/plugins/additional.lua
-- Additional essential plugins for IDE functionality - Vim way approach

return {
    -- JSON schemas for better JSON editing
    {
        "b0o/schemastore.nvim",
        lazy = true
    },

    -- Treesitter for better syntax highlighting
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = {
                    "python",
                    "javascript",
                    "typescript",
                    "vue",
                    "html",
                    "css",
                    "scss",
                    "go",
                    "c",
                    "cpp",
                    "lua",
                    "json",
                    "yaml",
                    "dockerfile",
                    "bash",
                    "markdown",
                    "gitignore",
                    "htmldjango"
                },
                sync_install = false,
                auto_install = true,
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false
                },
                indent = {
                    enable = true
                }
            })
        end
    },

    -- Fuzzy finder with buffer-focused configuration
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
            require("telescope").setup({
                defaults = {
                    prompt_prefix = " ",
                    selection_caret = " ",
                    path_display = {"truncate"},
                    file_ignore_patterns = {
                        "node_modules",
                        ".git/",
                        "*.pyc",
                        "__pycache__",
                        ".venv",
                        "venv",
                        ".env",
                        "migrations/",
                        "*.min.js",
                        "*.min.css",
                        "static/admin/",
                        "media/"
                    },
                    layout_config = {
                        horizontal = {
                            prompt_position = "top",
                            preview_width = 0.55,
                            results_width = 0.8,
                        },
                        vertical = {
                            mirror = false,
                        },
                        width = 0.87,
                        height = 0.80,
                        preview_cutoff = 120,
                    },
                    sorting_strategy = "ascending",
                },
                pickers = {
                    find_files = {
                        hidden = true,
                        find_command = {
                            "rg",
                            "--files",
                            "--hidden",
                            "--glob",
                            "!**/.git/*",
                            "--glob",
                            "!**/__pycache__/*",
                            "--glob",
                            "!**/.venv/*"
                        }
                    },
                    live_grep = {
                        additional_args = function()
                            return {
                                "--hidden",
                                "--glob",
                                "!**/.git/*",
                                "--glob",
                                "!**/__pycache__/*",
                                "--glob",
                                "!**/.venv/*",
                                "--glob",
                                "!**/migrations/*"
                            }
                        end
                    },
                    buffers = {
                        theme = "dropdown",
                        previewer = false,
                        initial_mode = "normal",
                        mappings = {
                            i = {
                                ["<C-d>"] = "delete_buffer",
                            },
                            n = {
                                ["dd"] = "delete_buffer",
                            }
                        }
                    },
                }
            })

            require("telescope").load_extension("fzf")

            -- Traditional Vim-style mappings
            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<leader>ff", builtin.find_files,
                {desc = "Find files"})
            vim.keymap.set("n", "<leader>fg", builtin.live_grep,
                {desc = "Live grep"})
            vim.keymap.set("n", "<leader>fb", builtin.buffers,
                {desc = "Find buffers"})
            vim.keymap.set("n", "<leader>fh", builtin.help_tags,
                {desc = "Help tags"})
            vim.keymap.set("n", "<leader>fs", builtin.lsp_document_symbols,
                {desc = "Document symbols"})
            vim.keymap.set("n", "<leader>fw", builtin.lsp_workspace_symbols,
                {desc = "Workspace symbols"})

            -- Quick buffer switcher
            vim.keymap.set("n", "<leader><leader>", builtin.buffers,
                {desc = "Switch buffers"})
        end
    },

    -- Git integration
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
                watch_gitdir = {
                    interval = 1000,
                    follow_files = true
                },
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

                    local function map(mode, l, r, opts)
                        opts = opts or {}
                        opts.buffer = bufnr
                        vim.keymap.set(mode, l, r, opts)
                    end

                    -- Navigation
                    map("n", "]c", function()
                        if vim.wo.diff then
                            return "]c"
                        end
                        vim.schedule(function()
                            gs.next_hunk()
                        end)
                        return "<Ignore>"
                    end, {expr = true, desc = "Next hunk"})

                    map("n", "[c", function()
                        if vim.wo.diff then
                            return "[c"
                        end
                        vim.schedule(function()
                            gs.prev_hunk()
                        end)
                        return "<Ignore>"
                    end, {expr = true, desc = "Previous hunk"})

                    -- Actions
                    map("n", "<leader>hs", gs.stage_hunk, {desc = "Stage hunk"})
                    map("n", "<leader>hr", gs.reset_hunk, {desc = "Reset hunk"})
                    map("n", "<leader>hp", gs.preview_hunk, {desc = "Preview hunk"})
                    map("n", "<leader>hb", function()
                        gs.blame_line {full = true}
                    end, {desc = "Blame line"})
                    map("n", "<leader>tb", gs.toggle_current_line_blame,
                        {desc = "Toggle blame"})
                    map("n", "<leader>hd", gs.diffthis, {desc = "Diff this"})
                end
            })
        end
    },

    -- Terminal integration
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        config = function()
            require("toggleterm").setup({
                size = function(term)
                    if term.direction == "horizontal" then
                        return 15
                    elseif term.direction == "vertical" then
                        return vim.o.columns * 0.4
                    end
                end,
                open_mapping = [[<c-\>]],
                hide_numbers = true,
                shade_terminals = true,
                shading_factor = 2,
                start_in_insert = true,
                insert_mappings = true,
                persist_size = true,
                direction = "horizontal",  -- Default to horizontal split
                close_on_exit = true,
                shell = vim.o.shell,
                float_opts = {
                    border = "curved",
                    winblend = 0,
                    highlights = {
                        border = "Normal",
                        background = "Normal"
                    }
                }
            })

            -- Custom terminals
            local Terminal = require("toggleterm.terminal").Terminal

            -- Python virtual environment terminal
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
                direction = "horizontal"
            })

            function _PYTHON_TOGGLE()
                python:toggle()
            end

            -- Django management terminal
            local django = Terminal:new({
                cmd = get_python_venv() .. " manage.py shell",
                hidden = true,
                direction = "horizontal"
            })

            function _DJANGO_SHELL_TOGGLE()
                django:toggle()
            end

            -- Django development server
            local runserver = Terminal:new({
                cmd = get_python_venv() .. " manage.py runserver",
                hidden = true,
                direction = "horizontal"
            })

            function _DJANGO_RUNSERVER()
                runserver:toggle()
            end

            -- Node terminal
            local node = Terminal:new({
                cmd = "node",
                hidden = true,
                direction = "horizontal"
            })

            function _NODE_TOGGLE()
                node:toggle()
            end

            -- Key mappings - traditional terminal approach
            vim.keymap.set("n", "<leader>th",
                "<cmd>ToggleTerm direction=horizontal<cr>",
                {desc = "Horizontal terminal"})
            vim.keymap.set("n", "<leader>tv",
                "<cmd>ToggleTerm direction=vertical size=80<cr>",
                {desc = "Vertical terminal"})
            vim.keymap.set("n", "<leader>tf",
                "<cmd>ToggleTerm direction=float<cr>",
                {desc = "Float terminal"})
            vim.keymap.set("n", "<leader>tp",
                "<cmd>lua _PYTHON_TOGGLE()<CR>",
                {desc = "Python terminal"})
            vim.keymap.set("n", "<leader>td",
                "<cmd>lua _DJANGO_SHELL_TOGGLE()<CR>",
                {desc = "Django shell"})
            vim.keymap.set("n", "<leader>tr",
                "<cmd>lua _DJANGO_RUNSERVER()<CR>",
                {desc = "Django runserver"})
            vim.keymap.set("n", "<leader>tn",
                "<cmd>lua _NODE_TOGGLE()<CR>",
                {desc = "Node terminal"})
        end
    },

    -- Auto pairs
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = function()
            require("nvim-autopairs").setup({
                check_ts = true,
                ts_config = {
                    lua = {"string", "source"},
                    javascript = {"string", "template_string"},
                    java = false
                },
                disable_filetype = {"TelescopePrompt", "spectre_panel"},
                fast_wrap = {
                    map = "<M-e>",
                    chars = {"{", "[", "(", '"', "'"},
                    pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
                    offset = 0,
                    end_key = "$",
                    keys = "qwertyuiopzxcvbnmasdfghjkl",
                    check_comma = true,
                    highlight = "PmenuSel",
                    highlight_grey = "LineNr"
                }
            })

            -- Integration with nvim-cmp
            local cmp_autopairs = require("nvim-autopairs.completion.cmp")
            local cmp = require("cmp")
            cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
        end
    },

    -- Comment plugin
    {
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup({
                toggler = {
                    line = "gcc",
                    block = "gbc"
                },
                opleader = {
                    line = "gc",
                    block = "gb"
                },
                extra = {
                    above = "gcO",
                    below = "gco",
                    eol = "gcA"
                },
                mappings = {
                    basic = true,
                    extra = true
                },
                pre_hook = nil,
                post_hook = nil
            })
        end
    },

    -- Django/Jinja2 template support
    {
        "Glench/Vim-Jinja2-Syntax",
        ft = {"htmldjango", "html"}
    },

    -- Python virtual environment detection
    {
        "linux-cultist/venv-selector.nvim",
        dependencies = {
            "neovim/nvim-lspconfig",
            "nvim-telescope/telescope.nvim",
            "mfussenegger/nvim-dap-python"
        },
        config = function()
            require("venv-selector").setup({
                name = {".venv", "venv"},
                auto_refresh = true
            })
            vim.keymap.set("n", "<leader>vs", "<cmd>VenvSelect<cr>",
                {desc = "Select Python venv"})
        end
    },

    -- Buffer delete without losing window layout
    {
        "famiu/bufdelete.nvim",
        config = function()
            vim.keymap.set("n", "<leader>bd", ":Bdelete<CR>",
                {desc = "Delete buffer (keep window)"})
            vim.keymap.set("n", "<leader>bD", ":Bdelete!<CR>",
                {desc = "Force delete buffer (keep window)"})
        end
    }
}