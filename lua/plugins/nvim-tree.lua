-- ~/.config/nvim/lua/plugins/nvim-tree.lua
-- Smart file explorer with tabs mode.

return {
    "nvim-tree/nvim-tree.lua",
    dependencies = {"nvim-tree/nvim-web-devicons"},
    config = function()
        -- disable netrw (conflicts with nvim-tree)
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1

        -- Global variable to track current mode
        _G.nvim_tree_mode = "files" -- "files" or "tabs"

        -- Function to get list of open tabs with their files
        local function get_open_tabs()
            local tabs = {}
            for tab_nr = 1, vim.fn.tabpagenr("$") do
                local buflist = vim.fn.tabpagebuflist(tab_nr)
                local winnr = vim.fn.tabpagewinnr(tab_nr)
                local buf = buflist[winnr]

                -- Find the first normal buffer (not NvimTree)
                for _, b in ipairs(buflist) do
                    local name = vim.fn.bufname(b)
                    if not name:match("NvimTree_") and name ~= "" then
                        buf = b
                        break
                    end
                end

                local file_path = vim.fn.bufname(buf)
                local file_name = vim.fn.fnamemodify(file_path, ":t")

                if file_name == "" then
                    file_name = "[No Name]"
                end

                -- Mark modified files
                if vim.bo[buf].modified then
                    file_name = file_name .. "*"
                end

                -- Mark current tab
                local is_current = (tab_nr == vim.fn.tabpagenr())

                table.insert(
                    tabs,
                    {
                        tab_nr = tab_nr,
                        file_name = file_name,
                        file_path = file_path,
                        is_current = is_current,
                        is_modified = vim.bo[buf].modified
                    }
                )
            end
            return tabs
        end

        -- Function to create tabs list buffer content
        local function create_tabs_content()
            local tabs = get_open_tabs()
            local lines = {}

            -- Header
            table.insert(lines, "")
            table.insert(lines, " OPEN TABS")
            table.insert(lines, " ─────────")
            table.insert(lines, "")

            -- Tab entries
            for _, tab in ipairs(tabs) do
                local prefix = tab.is_current and "▶ " or "  "
                local line = string.format("%s%d. %s", prefix, tab.tab_nr, tab.file_name)
                table.insert(lines, line)
            end

            if #tabs == 0 then
                table.insert(lines, "  No open tabs")
            end

            return lines, tabs
        end

        -- Function to show tabs in nvim-tree window
        local function show_tabs_mode()
            local api = require("nvim-tree.api")
            if not api.tree.is_visible() then
                return
            end

            -- Get nvim-tree window and buffer
            local tree_winid = api.tree.winid()
            if not tree_winid or tree_winid == -1 then
                return
            end

            -- Create or get tabs buffer
            local tabs_bufnr = vim.fn.bufnr("NvimTree_Tabs", true)

            -- Set buffer options
            vim.bo[tabs_bufnr].buftype = "nofile"
            vim.bo[tabs_bufnr].bufhidden = "wipe"
            vim.bo[tabs_bufnr].swapfile = false
            vim.bo[tabs_bufnr].filetype = "nvimtree_tabs"

            -- Generate content
            local content, tabs_data = create_tabs_content()

            -- Set content
            vim.api.nvim_buf_set_lines(tabs_bufnr, 0, -1, false, content)

            -- Make buffer read-only
            vim.bo[tabs_bufnr].modifiable = false

            -- Switch to tabs buffer in tree window
            vim.api.nvim_win_set_buf(tree_winid, tabs_bufnr)

            -- Set up keymaps for tabs mode
            vim.keymap.set(
                "n",
                "<CR>",
                function()
                    local line_nr = vim.fn.line(".")
                    local line_content = vim.fn.getline(line_nr)

                    -- Extract tab number from line
                    local tab_nr = line_content:match("^%s*▶?%s*(%d+)%.")
                    if tab_nr then
                        tab_nr = tonumber(tab_nr)
                        vim.cmd(tab_nr .. "tabnext")
                    end
                end,
                {buffer = tabs_bufnr, desc = "Switch to tab"}
            )

            -- Close tab with 'd'
            vim.keymap.set(
                "n",
                "d",
                function()
                    local line_nr = vim.fn.line(".")
                    local line_content = vim.fn.getline(line_nr)

                    local tab_nr = line_content:match("^%s*▶?%s*(%d+)%.")
                    if tab_nr then
                        tab_nr = tonumber(tab_nr)
                        if vim.fn.tabpagenr("$") > 1 then
                            vim.cmd(tab_nr .. "tabclose")
                            -- Refresh tabs view
                            vim.defer_fn(
                                function()
                                    if _G.nvim_tree_mode == "tabs" then
                                        show_tabs_mode()
                                    end
                                end,
                                50
                            )
                        end
                    end
                end,
                {buffer = tabs_bufnr, desc = "Close tab"}
            )
        end

        -- Function to toggle between modes
        local function toggle_tree_mode()
            if _G.nvim_tree_mode == "files" then
                _G.nvim_tree_mode = "tabs"
                show_tabs_mode()
            else
                _G.nvim_tree_mode = "files"
                local api = require("nvim-tree.api")
                api.tree.reload()
            end
        end

        require("nvim-tree").setup(
            {
                sync_root_with_cwd = true,
                update_focused_file = {
                    enable = true,
                    update_root = true
                },
                view = {
                    width = 30,
                    side = "left"
                },
                actions = {
                    open_file = {
                        quit_on_open = false
                    }
                },
                git = {
                    enable = false -- disable git integration completely
                },
                diagnostics = {
                    enable = false -- disable LSP diagnostics
                },
                modified = {
                    enable = false -- disable modified indicators
                },
                filters = {
                    git_ignored = false
                },
                renderer = {
                    icons = {
                        show = {
                            file = true,
                            folder = true,
                            folder_arrow = true,
                            git = false, -- hide git status icons
                            modified = false, -- hide modified indicators
                            diagnostics = false, -- hide diagnostic icons
                            bookmarks = false -- hide bookmark icons
                        },
                        glyphs = {
                            git = {
                                unstaged = "",
                                staged = "",
                                unmerged = "",
                                renamed = "",
                                untracked = "",
                                deleted = "",
                                ignored = ""
                            }
                        }
                    },
                    special_files = {}, -- don't highlight special files
                    -- Add custom root folder title
                    root_folder_label = function(path)
                        local mode_indicator = _G.nvim_tree_mode == "tabs" and "[TABS]" or "[FILES]"
                        return mode_indicator .. " " .. vim.fn.fnamemodify(path, ":t")
                    end
                },
                on_attach = function(bufnr)
                    local api = require("nvim-tree.api")
                    api.config.mappings.default_on_attach(bufnr)

                    -- Toggle between files and tabs mode with 't'.
                    vim.keymap.set("n", "t", toggle_tree_mode, {buffer = bufnr, desc = "Toggle Files/Tabs mode"})

                    -- Enter -> expand folder or open file in new tab.
                    vim.keymap.set(
                        "n",
                        "<CR>",
                        function()
                            local api = require("nvim-tree.api")
                            local node = api.tree.get_node_under_cursor()
                            if not node then
                                return
                            end

                            if node.type == "directory" then
                                -- expand/collapse folder
                                api.node.open.edit()
                            elseif node.type == "file" then
                                local file_path = node.absolute_path
                                local found = false

                                -- search for tab with this file
                                for tab_nr = 1, vim.fn.tabpagenr("$") do
                                    local buflist = vim.fn.tabpagebuflist(tab_nr)
                                    for _, bufnr_tab in ipairs(buflist) do
                                        local buf_name = vim.fn.bufname(bufnr_tab)
                                        if buf_name == file_path then
                                            -- file already open → switch to its tab
                                            vim.cmd(tab_nr .. "tabnext")
                                            found = true
                                            break
                                        end
                                    end
                                    if found then
                                        break
                                    end
                                end

                                if not found then
                                    -- file not open → open in new tab
                                    vim.cmd("tabnew " .. vim.fn.fnameescape(file_path))

                                    -- reopen tree in new tab (sync with file)
                                    vim.schedule(
                                        function()
                                            vim.cmd("NvimTreeFindFile")
                                        end
                                    )
                                end

                                -- ensure focus goes to file window, not tree
                                vim.schedule(
                                    function()
                                        local side = require("nvim-tree").config.view.side
                                        if side == "left" then
                                            vim.cmd("wincmd l")
                                        else
                                            vim.cmd("wincmd h")
                                        end
                                    end
                                )
                            end
                        end,
                        {buffer = bufnr, desc = "Expand folder or open file in new tab"}
                    )
                end
            }
        )

        -- Auto-refresh tabs mode when tabs change
        local tabs_refresh_group = vim.api.nvim_create_augroup("NvimTreeTabsRefresh", {clear = true})

        vim.api.nvim_create_autocmd(
            {"TabEnter", "TabLeave", "TabClosed", "TabNew"},
            {
                group = tabs_refresh_group,
                callback = function()
                    -- Small delay to let vim finish tab operations
                    vim.defer_fn(
                        function()
                            if _G.nvim_tree_mode == "tabs" then
                                local api = require("nvim-tree.api")
                                if api.tree.is_visible() then
                                    show_tabs_mode()
                                end
                            end
                        end,
                        50
                    )
                end
            }
        )

        -- Refresh tabs when buffer is modified/saved
        vim.api.nvim_create_autocmd(
            {"BufWritePost", "TextChanged", "TextChangedI"},
            {
                group = tabs_refresh_group,
                callback = function()
                    if _G.nvim_tree_mode == "tabs" then
                        vim.defer_fn(
                            function()
                                local api = require("nvim-tree.api")
                                if api.tree.is_visible() then
                                    show_tabs_mode()
                                end
                            end,
                            100
                        )
                    end
                end
            }
        )

        -- Auto-create empty buffer if only NvimTree is left
        vim.api.nvim_create_autocmd(
            "BufEnter",
            {
                nested = true,
                callback = function()
                    if #vim.api.nvim_list_wins() == 1 and vim.bo.filetype == "NvimTree" then
                        -- just create empty buffer, do not reopen tree
                        vim.cmd("enew")
                    end
                end
            }
        )
    end
}
