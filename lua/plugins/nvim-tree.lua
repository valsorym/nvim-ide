-- ~/.config/nvim/lua/plugins/nvim-tree.lua
-- Modal file explorer with vim-way buffer handling.

return {
    "nvim-tree/nvim-tree.lua",
    dependencies = {"nvim-tree/nvim-web-devicons"},
    config = function()
        -- Disable netrw (conflicts with nvim-tree).
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1

        -- Function to get current file path for sync.
        local function get_current_file()
            local current_buf = vim.api.nvim_get_current_buf()
            local file_path = vim.fn.bufname(current_buf)

            -- Return empty string for special buffers
            if
                file_path == "" or file_path:match("NvimTree_") or file_path:match("toggleterm") or
                    file_path:match("dashboard")
             then
                return ""
            end

            return vim.fn.fnamemodify(file_path, ":p")
        end

        -- Function to open nvim-tree as modal window with sync.
        local function open_tree_modal()
            local api = require("nvim-tree.api")

            -- Close existing tree if open.
            if api.tree.is_visible() then
                api.tree.close()
            end

            -- Open tree in modal mode.
            api.tree.open(
                {
                    current_window = false,
                    find_file = false,
                    update_root = false
                }
            )

            -- Get current file for sync.
            local current_file = get_current_file()

            -- Schedule sync after tree opens.
            vim.schedule(
                function()
                    if current_file ~= "" then
                        api.tree.find_file(current_file)
                    end
                end
            )
        end

        -- Function to change root directory.
        local function change_root_to_cwd()
            local api = require("nvim-tree.api")
            local cwd = vim.fn.getcwd()
            api.tree.change_root(cwd)
            print("Root changed to: " .. cwd)
        end

        -- Function to pick root directory.
        local function pick_root_directory()
            vim.ui.input(
                {
                    prompt = "New root directory: ",
                    default = vim.fn.getcwd(),
                    completion = "dir"
                },
                function(input)
                    if input and vim.fn.isdirectory(input) == 1 then
                        local api = require("nvim-tree.api")
                        local full_path = vim.fn.fnamemodify(input, ":p")
                        api.tree.change_root(full_path)
                        print("Root changed to: " .. full_path)
                    elseif input then
                        print("Directory does not exist: " .. input)
                    end
                end
            )
        end

        require("nvim-tree").setup(
            {
                sync_root_with_cwd = true,
                update_focused_file = {
                    enable = true,
                    update_root = false, -- don't auto-update root
                    ignore_list = {}
                },
                view = {
                    width = 80,
                    float = {
                        enable = true,
                        quit_on_focus_loss = true,
                        open_win_config = function()
                            local width = math.min(80, math.floor(vim.o.columns * 0.8))
                            local height = math.min(30, math.floor(vim.o.lines * 0.8))
                            local row = math.floor((vim.o.lines - height) / 2)
                            local col = math.floor((vim.o.columns - width) / 2)

                            return {
                                relative = "editor",
                                border = "rounded",
                                width = width,
                                height = height,
                                row = row,
                                col = col,
                                title = " File Explorer ",
                                title_pos = "center"
                            }
                        end
                    }
                },
                actions = {
                    open_file = {
                        quit_on_open = true, -- close tree after opening file
                        window_picker = {
                            enable = true -- allow window picker for splits
                        }
                    },
                    change_dir = {
                        enable = true,
                        global = false,
                        restrict_above_cwd = false
                    }
                },
                git = {
                    enable = false -- disable git integration for simplicity
                },
                diagnostics = {
                    enable = false -- disable LSP diagnostics
                },
                modified = {
                    enable = false -- disable modified indicators
                },
                filters = {
                    git_ignored = false,
                    dotfiles = false,
                    git_clean = false,
                    no_buffer = false,
                    custom = {".DS_Store"},
                    exclude = {}
                },
                renderer = {
                    add_trailing = false,
                    group_empty = false,
                    highlight_git = false,
                    full_name = false,
                    highlight_opened_files = "all",
                    highlight_modified = "none",
                    root_folder_label = function(path)
                        return vim.fn.fnamemodify(path, ":~")
                    end,
                    indent_width = 2,
                    indent_markers = {
                        enable = true,
                        inline_arrows = true,
                        icons = {
                            corner = "└",
                            edge = "│",
                            item = "│",
                            bottom = "─",
                            none = " "
                        }
                    },
                    icons = {
                        webdev_colors = true,
                        git_placement = "before",
                        modified_placement = "after",
                        padding = " ",
                        symlink_arrow = " ➛ ",
                        show = {
                            file = true,
                            folder = true,
                            folder_arrow = true,
                            git = false,
                            modified = false,
                            diagnostics = false,
                            bookmarks = false
                        },
                        glyphs = {
                            default = "",
                            symlink = "",
                            bookmark = "",
                            modified = "●",
                            folder = {
                                arrow_closed = "", -- ►
                                arrow_open = "", -- ▼
                                default = "", -- closed folder
                                open = "", -- open folder
                                empty = "", -- empty closed
                                empty_open = "", -- empty open
                                symlink = "", -- symlink folder
                                symlink_open = "" -- symlink open
                            },
                            git = {
                                unstaged = "✗",
                                staged = "✓",
                                unmerged = "",
                                renamed = "➜",
                                untracked = "★",
                                deleted = "",
                                ignored = "◌"
                            }
                        }
                    },
                    special_files = {"Cargo.toml", "Makefile", "README.md", "readme.md"}
                },
                on_attach = function(bufnr)
                    local api = require("nvim-tree.api")

                    -- Clear default mappings
                    api.config.mappings.default_on_attach(bufnr)

                    -- Enter -> expand folder or open file in current window (vim-way)
                    vim.keymap.set(
                        "n",
                        "<CR>",
                        function()
                            local node = api.tree.get_node_under_cursor()
                            if not node then
                                return
                            end

                            if node.type == "directory" then
                                -- Expand/collapse folder
                                api.node.open.edit()
                            elseif node.type == "file" then
                                local file_path = node.absolute_path

                                -- Close tree
                                api.tree.close()

                                -- Open in current window (vim default behavior)
                                vim.cmd("edit " .. vim.fn.fnameescape(file_path))
                            end
                        end,
                        {
                            buffer = bufnr,
                            desc = "Expand folder or open file"
                        }
                    )

                    -- t -> open file in new tab
                    vim.keymap.set(
                        "n",
                        "t",
                        function()
                            local node = api.tree.get_node_under_cursor()
                            if not node or node.type ~= "file" then
                                return
                            end

                            local file_path = node.absolute_path
                            api.tree.close()
                            vim.cmd("tabnew " .. vim.fn.fnameescape(file_path))
                        end,
                        {
                            buffer = bufnr,
                            desc = "Open file in new tab"
                        }
                    )

                    -- s -> open file in horizontal split
                    vim.keymap.set(
                        "n",
                        "s",
                        function()
                            local node = api.tree.get_node_under_cursor()
                            if not node or node.type ~= "file" then
                                return
                            end

                            local file_path = node.absolute_path
                            api.tree.close()
                            vim.cmd("split " .. vim.fn.fnameescape(file_path))
                        end,
                        {
                            buffer = bufnr,
                            desc = "Open file in horizontal split"
                        }
                    )

                    -- v -> open file in vertical split
                    vim.keymap.set(
                        "n",
                        "v",
                        function()
                            local node = api.tree.get_node_under_cursor()
                            if not node or node.type ~= "file" then
                                return
                            end

                            local file_path = node.absolute_path
                            api.tree.close()
                            vim.cmd("vsplit " .. vim.fn.fnameescape(file_path))
                        end,
                        {
                            buffer = bufnr,
                            desc = "Open file in vertical split"
                        }
                    )

                    -- Close tree with Escape or q
                    vim.keymap.set("n", "<Esc>", api.tree.close, {buffer = bufnr, desc = "Close tree"})
                    vim.keymap.set("n", "q", api.tree.close, {buffer = bufnr, desc = "Close tree"})

                    -- Root directory management
                    vim.keymap.set("n", "C", change_root_to_cwd, {buffer = bufnr, desc = "Change root to CWD"})
                    vim.keymap.set("n", "R", pick_root_directory, {buffer = bufnr, desc = "Pick root directory"})

                    -- Navigate up one directory level
                    vim.keymap.set(
                        "n",
                        "P",
                        api.tree.change_root_to_parent,
                        {buffer = bufnr, desc = "Parent directory"}
                    )

                    -- Refresh tree
                    vim.keymap.set("n", "r", api.tree.reload, {buffer = bufnr, desc = "Refresh"})

                    -- Create file/directory
                    vim.keymap.set("n", "a", api.fs.create, {buffer = bufnr, desc = "Create file/directory"})

                    -- Delete file/directory
                    vim.keymap.set("n", "d", api.fs.remove, {buffer = bufnr, desc = "Delete"})

                    -- Rename file/directory
                    vim.keymap.set("n", "rn", api.fs.rename, {buffer = bufnr, desc = "Rename"})

                    -- Copy file/directory
                    vim.keymap.set("n", "c", api.fs.copy.node, {buffer = bufnr, desc = "Copy"})

                    -- Cut file/directory
                    vim.keymap.set("n", "x", api.fs.cut, {buffer = bufnr, desc = "Cut"})

                    -- Paste file/directory
                    vim.keymap.set("n", "p", api.fs.paste, {buffer = bufnr, desc = "Paste"})

                    -- Toggle hidden files
                    vim.keymap.set(
                        "n",
                        "H",
                        api.tree.toggle_hidden_filter,
                        {buffer = bufnr, desc = "Toggle hidden files"}
                    )

                    -- Filter files (live filter)
                    vim.keymap.set("n", "f", api.live_filter.start, {buffer = bufnr, desc = "Filter files"})
                    vim.keymap.set("n", "F", api.live_filter.clear, {buffer = bufnr, desc = "Clear filter"})
                end
            }
        )

        -- Global function for modal tree access
        _G.NvimTreeModal = open_tree_modal

        -- Create user command for modal tree
        vim.api.nvim_create_user_command("NvimTreeModal", open_tree_modal, {desc = "Open NvimTree as modal window"})

        -- Create command for changing root
        vim.api.nvim_create_user_command(
            "NvimTreeChangeRoot",
            pick_root_directory,
            {desc = "Change NvimTree root directory"}
        )
    end
}