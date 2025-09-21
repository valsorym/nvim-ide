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
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup(
                {
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
                        "htmldjango" -- django templates
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
                }
            )
        end
    },
    -- Fuzzy finder with vim-way behavior.
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
            local actions = require("telescope.actions")

            telescope.setup(
                {
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
                        mappings = {
                            i = {
                                ["<C-t>"] = actions.select_tab,
                                ["<C-x>"] = actions.select_horizontal,
                                ["<C-v>"] = actions.select_vertical,
                                -- <CR> opens in current window (vim default)
                            },
                            n = {
                                ["<C-t>"] = actions.select_tab,
                                ["<C-x>"] = actions.select_horizontal,
                                ["<C-v>"] = actions.select_vertical,
                                -- <CR> opens in current window (vim default)
                            }
                        }
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
                        }
                    }
                }
            )

            require("telescope").load_extension("fzf")

            -- Enhanced contextual buffer picker
            local function contextual_buffers()
                local pickers = require("telescope.pickers")
                local finders = require("telescope.finders")
                local conf = require("telescope.config").values
                local action_state = require("telescope.actions.state")

                -- Get current tab info
                local current_tab = vim.fn.tabpagenr()
                local current_tab_buffers = vim.fn.tabpagebuflist(current_tab)

                -- Create set for quick lookup
                local current_tab_buf_set = {}
                for _, buf in ipairs(current_tab_buffers) do
                    current_tab_buf_set[buf] = true
                end

                -- Get all buffers
                local all_buffers = vim.api.nvim_list_bufs()

                -- Separate current tab buffers and others
                local current_entries = {}
                local other_entries = {}

                -- Map buffer to tab for other buffers
                local buf_to_tab = {}
                for tab_nr = 1, vim.fn.tabpagenr("$") do
                    if tab_nr ~= current_tab then
                        local tab_buflist = vim.fn.tabpagebuflist(tab_nr)
                        for _, buf in ipairs(tab_buflist) do
                            buf_to_tab[buf] = tab_nr
                        end
                    end
                end

                -- Get tab names if available
                local function get_tab_name(tab_nr)
                    if _G.tab_names and _G.tab_names[tab_nr] then
                        return _G.tab_names[tab_nr]
                    end
                    -- Fallback to file name
                    local tab_buflist = vim.fn.tabpagebuflist(tab_nr)
                    local main_buf = tab_buflist[vim.fn.tabpagewinnr(tab_nr)]
                    local tab_file = vim.fn.bufname(main_buf)
                    return tab_file ~= "" and vim.fn.fnamemodify(tab_file, ":t") or ("Tab " .. tab_nr)
                end

                for _, buf in ipairs(all_buffers) do
                    -- Skip invalid and hidden buffers
                    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
                        local bufname = vim.api.nvim_buf_get_name(buf)
                        local filename = vim.fn.fnamemodify(bufname, ":t")

                        -- Skip empty names and special buffers
                        if filename ~= "" and
                           not bufname:match("NvimTree") and
                           not bufname:match("dashboard") and
                           not bufname:match("toggleterm") then

                            local is_modified = vim.bo[buf].modified
                            local display_name = filename .. (is_modified and " [+]" or "")

                            local entry = {
                                bufnr = buf,
                                filename = bufname,
                                display = display_name,
                                ordinal = filename,
                            }

                            if current_tab_buf_set[buf] then
                                -- Buffer is in current tab
                                entry.display = "● " .. display_name
                                table.insert(current_entries, entry)
                            elseif buf_to_tab[buf] then
                                -- Buffer is in another tab
                                local tab_nr = buf_to_tab[buf]
                                local tab_name = get_tab_name(tab_nr)
                                entry.display = "○ " .. display_name .. " (" .. tab_name .. ")"
                                table.insert(other_entries, entry)
                            else
                                -- Hidden buffer (not visible in any tab)
                                entry.display = "◦ " .. display_name .. " (hidden)"
                                table.insert(other_entries, entry)
                            end
                        end
                    end
                end

                -- Combine entries: current tab first, then others
                local all_entries = {}

                -- Add section header if we have current tab buffers
                if #current_entries > 0 then
                    table.insert(all_entries, {
                        display = "── Current Tab ──",
                        ordinal = "",
                        is_header = true,
                    })
                    vim.list_extend(all_entries, current_entries)
                end

                -- Add other buffers if any
                if #other_entries > 0 then
                    table.insert(all_entries, {
                        display = "── Other Tabs/Hidden ──",
                        ordinal = "",
                        is_header = true,
                    })
                    vim.list_extend(all_entries, other_entries)
                end

                if #all_entries == 0 then
                    vim.notify("No buffers found", vim.log.levels.INFO)
                    return
                end

                pickers.new({}, {
                    prompt_title = "Contextual Buffers",
                    finder = finders.new_table({
                        results = all_entries,
                        entry_maker = function(entry)
                            return {
                                value = entry,
                                display = entry.display,
                                ordinal = entry.ordinal,
                                bufnr = entry.bufnr,
                                filename = entry.filename,
                                is_header = entry.is_header,
                            }
                        end,
                    }),
                    sorter = conf.generic_sorter({}),
                    attach_mappings = function(prompt_bufnr, map)
                        local function select_buffer()
                            local selection = action_state.get_selected_entry()
                            actions.close(prompt_bufnr)

                            if selection and selection.value and not selection.is_header then
                                -- Standard vim behavior - switch to buffer in current window
                                vim.api.nvim_set_current_buf(selection.bufnr)
                            end
                        end

                        local function select_buffer_tab()
                            local selection = action_state.get_selected_entry()
                            actions.close(prompt_bufnr)

                            if selection and selection.value and not selection.is_header then
                                -- Open in new tab
                                vim.cmd("tabnew")
                                vim.api.nvim_set_current_buf(selection.bufnr)
                            end
                        end

                        map("i", "<CR>", select_buffer)
                        map("n", "<CR>", select_buffer)
                        map("i", "<C-t>", select_buffer_tab)
                        map("n", "<C-t>", select_buffer_tab)

                        -- Delete buffer
                        map("i", "<C-d>", function()
                            local selection = action_state.get_selected_entry()
                            if selection and selection.bufnr and not selection.is_header then
                                vim.api.nvim_buf_delete(selection.bufnr, {})
                                -- Refresh the picker
                                actions.close(prompt_bufnr)
                                vim.defer_fn(contextual_buffers, 100)
                            end
                        end)

                        return true
                    end,
                }):find()
            end

            -- Set up keymaps
            local builtin = require("telescope.builtin")

            vim.keymap.set("n", "<leader>ff", builtin.find_files, {desc = "Find files"})
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, {desc = "Live grep"})
            vim.keymap.set("n", "<leader>fb", contextual_buffers, {desc = "Find buffers (contextual)"})
            vim.keymap.set("n", "<leader>fh", builtin.help_tags, {desc = "Help tags"})
            vim.keymap.set("n", "<leader>fs", builtin.lsp_document_symbols, {desc = "Document symbols"})
            vim.keymap.set("n", "<leader>fw", builtin.lsp_workspace_symbols, {desc = "Workspace symbols"})
            vim.keymap.set("n", "<leader>fr", builtin.oldfiles, {desc = "Recent files"})

            -- Buffer management keymaps - make global functions
            _G.ContextualBuffers = contextual_buffers

            vim.keymap.set("n", "<leader>bb", contextual_buffers, {desc = "List buffers (contextual)"})
            vim.keymap.set("n", "<leader>eb", contextual_buffers, {desc = "Show buffers list (contextual)"})
            vim.keymap.set("n", "<F10>", contextual_buffers, {desc = "Show buffers list (contextual)"})
        end
    },
    -- Git integration.
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup(
                {
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
                        map(
                            "n",
                            "]c",
                            function()
                                if vim.wo.diff then
                                    return "]c"
                                end
                                vim.schedule(
                                    function()
                                        gs.next_hunk()
                                    end
                                )
                                return "<Ignore>"
                            end,
                            {expr = true, desc = "Next hunk"}
                        )

                        map(
                            "n",
                            "[c",
                            function()
                                if vim.wo.diff then
                                    return "[c"
                                end
                                vim.schedule(
                                    function()
                                        gs.prev_hunk()
                                    end
                                )
                                return "<Ignore>"
                            end,
                            {expr = true, desc = "Previous hunk"}
                        )

                        -- Actions.
                        map("n", "<leader>hs", gs.stage_hunk, {desc = "Stage hunk"})
                        map("n", "<leader>hr", gs.reset_hunk, {desc = "Reset hunk"})
                        map("n", "<leader>hp", gs.preview_hunk, {desc = "Preview hunk"})
                        map(
                            "n",
                            "<leader>hb",
                            function()
                                gs.blame_line {full = true}
                            end,
                            {desc = "Blame line"}
                        )
                        map("n", "<leader>tb", gs.toggle_current_line_blame, {desc = "Toggle blame"})
                        map("n", "<leader>hd", gs.diffthis, {desc = "Diff this"})
                    end
                }
            )
        end
    },
    -- Terminal integration.
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        config = function()
            require("toggleterm").setup(
                {
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
                        highlights = {
                            border = "Normal",
                            background = "Normal"
                        }
                    }
                }
            )

            -- Custom terminals.
            local Terminal = require("toggleterm.terminal").Terminal

            -- Python virtual environment terminal.
            local function get_python_venv()
                -- Check for .venv first, then venv, then fall back to system python.
                if vim.fn.isdirectory(".venv") == 1 then
                    return ".venv/bin/python"
                elseif vim.fn.isdirectory("venv") == 1 then
                    return "venv/bin/python"
                else
                    return "python3"
                end
            end

            local python =
                Terminal:new(
                {
                    cmd = get_python_venv(),
                    hidden = true,
                    direction = "float"
                }
            )

            function _PYTHON_TOGGLE()
                python:toggle()
            end

            -- Django management terminal.
            local django =
                Terminal:new(
                {
                    cmd = get_python_venv() .. " manage.py shell",
                    hidden = true,
                    direction = "float"
                }
            )

            function _DJANGO_SHELL_TOGGLE()
                django:toggle()
            end

            -- Django development server.
            local runserver =
                Terminal:new(
                {
                    cmd = get_python_venv() .. " manage.py runserver",
                    hidden = true,
                    direction = "horizontal"
                }
            )

            function _DJANGO_RUNSERVER()
                runserver:toggle()
            end

            -- Node terminal
            local node =
                Terminal:new(
                {
                    cmd = "node",
                    hidden = true,
                    direction = "float"
                }
            )

            function _NODE_TOGGLE()
                node:toggle()
            end

            -- Key mappings.
            vim.keymap.set("n", "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", {desc = "Float terminal"})
            vim.keymap.set(
                "n",
                "<leader>th",
                "<cmd>ToggleTerm direction=horizontal<cr>",
                {desc = "Horizontal terminal"}
            )
            vim.keymap.set(
                "n",
                "<leader>tv",
                "<cmd>ToggleTerm direction=vertical size=80<cr>",
                {desc = "Vertical terminal"}
            )
            vim.keymap.set("n", "<leader>tp", "<cmd>lua _PYTHON_TOGGLE()<CR>", {desc = "Python terminal"})
            vim.keymap.set("n", "<leader>td", "<cmd>lua _DJANGO_SHELL_TOGGLE()<CR>", {desc = "Django shell"})
            vim.keymap.set("n", "<leader>tr", "<cmd>lua _DJANGO_RUNSERVER()<CR>", {desc = "Django runserver"})
            vim.keymap.set("n", "<leader>tn", "<cmd>lua _NODE_TOGGLE()<CR>", {desc = "Node terminal"})
        end
    },
    -- Auto pairs.
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = function()
            require("nvim-autopairs").setup(
                {
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
                }
            )

            -- Integration with nvim-cmp.
            local cmp_autopairs = require("nvim-autopairs.completion.cmp")
            local cmp = require("cmp")
            cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
        end
    },
    -- Comment plugin.
    {
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup(
                {
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
                }
            )
        end
    },
    -- Django/Jinja2 template support.
    {
        "Glench/Vim-Jinja2-Syntax",
        ft = {"htmldjango", "html"}
    },
    -- Python virtual environment detection.
    {
        "linux-cultist/venv-selector.nvim",
        dependencies = {
            "neovim/nvim-lspconfig",
            "nvim-telescope/telescope.nvim",
            "mfussenegger/nvim-dap-python"
        },
        config = function()
            require("venv-selector").setup(
                {
                    name = {".venv", "venv"},
                    auto_refresh = true
                }
            )
            vim.keymap.set("n", "<leader>vs", "<cmd>VenvSelect<cr>", {desc = "• Python venv"})
        end
    }
}