-- ~/.config/nvim/lua/config/keymaps.lua
-- Centralized keymaps configuration with reorganized structure.

local M = {}
local safe_save = require("config.safe-save")

-- Delete buffers that are not visible in any tab.
local function cleanup_orphan_buffers(force)
    force = force or false

    -- Collect all buffers visible across tabs.
    local visible = {}
    for tab = 1, vim.fn.tabpagenr("$") do
        local bufs = vim.fn.tabpagebuflist(tab)
        for _, b in ipairs(bufs) do
            visible[b] = true
        end
    end

    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.fn.buflisted(b) == 1 and not visible[b] then
            local name = vim.fn.bufname(b)
            local bt = vim.bo[b].buftype
            local ft = vim.bo[b].filetype

            -- Skip special/utility buffers.
            local skip = bt ~= "" or name == ""
            skip = skip or ft == "dashboard" or ft == "help"
            skip = skip or ft == "NvimTree" or ft == "neo-tree" or ft == "oil"
            skip = skip or name:match("toggleterm") or name:match("^term://")

            if not skip then
                if not vim.bo[b].modified or force then
                    pcall(vim.api.nvim_buf_delete, b, {force = force})
                end
            end
        end
    end
end

-- Autoclean orphan buffers whenever a tab is closed.
local orphan_clean_group = vim.api.nvim_create_augroup(
    "OrphanBufferCleanup",
    { clear = true }
)

vim.api.nvim_create_autocmd(
    "TabClosed",
    {
        group = orphan_clean_group,
        callback = function()
            -- Defer to ensure tab state is updated before cleaning.
            vim.schedule(function()
                pcall(cleanup_orphan_buffers, false)
            end)
        end
    }
)

-- Smart tab close function with Dashboard support.
local function smart_tab_close()
    local total_tabs = vim.fn.tabpagenr("$")
    local current_buf = vim.api.nvim_get_current_buf()
    local filetype = vim.bo[current_buf].filetype

    if total_tabs == 1 then
        if filetype == "dashboard" then
            vim.cmd("qa")
        else
            vim.cmd("Dashboard")
            cleanup_orphan_buffers(false)
        end
    else
        vim.cmd("tabclose")
        cleanup_orphan_buffers(false)
    end
end

-- Force close tab (with !).
local function force_close_tab()
    local total_tabs = vim.fn.tabpagenr("$")

    if total_tabs == 1 then
        vim.cmd("Dashboard")
        cleanup_orphan_buffers(true)
    else
        vim.cmd("tabclose!")
        cleanup_orphan_buffers(true)
    end
end

-- Setup conditional abbreviations for command line.
local function setup_conditional_abbreviations()
    vim.api.nvim_create_autocmd(
        {"BufEnter", "FileType"},
        {
            callback = function()
                local filetype = vim.bo.filetype

                if filetype == "dashboard" then
                    -- In Dashboard - remove abbreviations, allow native :q behavior.
                    pcall(vim.cmd, "cunabbrev q")
                    pcall(vim.cmd, "cunabbrev wq")
                    pcall(vim.cmd, "cunabbrev WQ")
                else
                    -- In normal files - set up buffer-local abbreviations.
                    vim.cmd("cabbrev <buffer> q Q")
                    vim.cmd("cabbrev <buffer> wq Wq")
                    vim.cmd("cabbrev <buffer> WQ Wq")
                end
            end
        }
    )
end

function M.setup()
    local map = vim.keymap.set
    local opts = {noremap = true, silent = true}

    -- Enable mouse support for LSP navigation
    vim.opt.mouse = "a"
    vim.opt.mousemodel = "extend"

    -- Use system clipboard for all yanks/pastes by default
    vim.opt.clipboard = "unnamedplus"

    -- Patch Telescope builtins to open results in tabs.
    local function patch_telescope_tabdrop()
        local ok, builtin = pcall(require, "telescope.builtin")
        if not ok then
            return
        end
        local actions = require("telescope.actions")
        local state = require("telescope.actions.state")

        local function wrap(fn)
            return function(user_opts)
                user_opts = user_opts or {}
                local prev_attach = user_opts.attach_mappings
                user_opts.attach_mappings =
                    function(prompt_bufnr, map_local)
                        if prev_attach then
                            prev_attach(prompt_bufnr, map_local)
                        end
                        local function select_tab()
                            local e = state.get_selected_entry()
                            if not e then
                                return
                            end
                            local file = e.path or e.filename or e.value
                            if (not file or file == "") and e.bufnr then
                                file = vim.api.nvim_buf_get_name(e.bufnr)
                            end
                            if not file or file == "" then
                                return actions.select_default(prompt_bufnr)
                            end
                            actions.close(prompt_bufnr)

                            -- Check if the current tab is Dashboard.
                            local current_buf = vim.api.nvim_get_current_buf()
                            local current_filetype = vim.bo[current_buf].filetype
                            local current_name = vim.fn.bufname(current_buf)

                            if current_filetype == "dashboard" or
                            (current_name == "" and not vim.bo[current_buf].modified) then
                                -- Replace the current tab instead of creating a new one.
                                vim.cmd("edit " .. vim.fn.fnameescape(file))
                            else
                                -- Use tab drop for other cases.
                                vim.cmd("tab drop " .. vim.fn.fnameescape(file))
                            end

                            local ln = e.lnum or e.row or 1
                            local cl = math.max((e.col or 1) - 1, 0)
                            pcall(vim.api.nvim_win_set_cursor, 0, {ln, cl})
                            vim.cmd("normal! zz")
                        end
                        actions.select_default:replace(select_tab)
                        map_local("i", "<CR>", select_tab)
                        map_local("n", "<CR>", select_tab)
                        return true
                    end
                return fn(user_opts)
            end
        end

        local function patch(name)
            if type(builtin[name]) == "function" then
                builtin[name] = wrap(builtin[name])
            end
        end

        for _, name in ipairs(
            {
                "find_files",
                "live_grep",
                "buffers",
                "git_files",
                "oldfiles",
                "grep_string",
                "lsp_workspace_symbols"
            }
        ) do
            patch(name)
        end
    end

    -- Apply the patch once on startup.
    pcall(patch_telescope_tabdrop)

    -- BASIC NAVIGATION & WINDOW MANAGEMENT

    -- Better window navigation.
    map("n", "<C-h>", "<C-w>h", {desc = "Go to left window"})
    map("n", "<C-j>", "<C-w>j", {desc = "Go to lower window"})
    map("n", "<C-k>", "<C-w>k", {desc = "Go to upper window"})
    map("n", "<C-l>", "<C-w>l", {desc = "Go to right window"})

    -- Resize windows.
    map("n", "<C-Up>", ":resize +2<CR>", opts)
    map("n", "<C-Down>", ":resize -2<CR>", opts)
    map("n", "<C-Left>", ":vertical resize -2<CR>", opts)
    map("n", "<C-Right>", ":vertical resize +2<CR>", opts)

    -- Move text up and down.
    map("v", "<A-j>", ":m .+1<CR>==", opts)
    map("v", "<A-k>", ":m .-2<CR>==", opts)
    map("x", "J", ":move '>+1<CR>gv-gv", opts)
    map("x", "K", ":move '<-2<CR>gv-gv", opts)
    map("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
    map("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)

    -- Stay in indent mode.
    map("v", "<", "<gv", opts)
    map("v", ">", ">gv", opts)

    -- Better paste.
    map("v", "p", '"_dP', opts)

    -- TAB NAVIGATION

    -- Tabs navigation.
    map("n", "<A-Left>", ":tabprevious<CR>", {desc = "Previous tab"})
    map("n", "<A-Right>", ":tabnext<CR>", {desc = "Next tab"})
    map("n", "<A-1>", "1gt", {desc = "Go to tab 1"})
    map("n", "<A-2>", "2gt", {desc = "Go to tab 2"})
    map("n", "<A-3>", "3gt", {desc = "Go to tab 3"})
    map("n", "<A-4>", "4gt", {desc = "Go to tab 4"})
    map("n", "<A-5>", "5gt", {desc = "Go to tab 5"})
    map("n", "<A-6>", "6gt", {desc = "Go to tab 6"})
    map("n", "<A-7>", "7gt", {desc = "Go to tab 7"})
    map("n", "<A-8>", "8gt", {desc = "Go to tab 8"})
    map("n", "<A-9>", "9gt", {desc = "Go to tab 9"})

    -- Move current tab.
    map("n", "<A-h>", ":-tabmove<CR>", {desc = "Move tab left"})
    map("n", "<A-l>", ":+tabmove<CR>", {desc = "Move tab right"})

    -- Tab navigation with F keys.
    map("n", "<F5>", ":tabprevious<CR>", {desc = "Previous tab"})
    map("n", "<F6>", ":tabnext<CR>", {desc = "Next tab"})

    -- WORKSPACE / SESSIONS (<leader>w)

    map("n", "<leader>wq", smart_tab_close, {desc = "Smart close tab"})
    map("n", "<leader>wA", ":qa<CR>", {desc = "Close all tabs and exit"})
    map("n", "<leader>wQ", force_close_tab, {desc = "Force close tab"})

    -- EXPLORER / TREE / BUFFERS (<leader>e)

    -- File tree modal with F9.
    map(
        "n",
        "<F9>",
        function()
            if _G.NvimTreeModal then
                _G.NvimTreeModal()
            end
        end,
        {desc = "Open file explorer", silent = true}
    )

    -- Explorer commands.
    map(
        "n",
        "<leader>ee",
        function()
            if _G.NvimTreeModal then
                _G.NvimTreeModal()
            end
        end,
        {desc = "Open file explorer", silent = true}
    )

    -- Buffers list with F10.
    map(
        "n",
        "<F10>",
        function()
            require("telescope.builtin").buffers()
        end,
        {desc = "Show buffers list", silent = true}
    )

    map(
        "n",
        "<leader>eb",
        function()
            require("telescope.builtin").buffers()
        end,
        {desc = "Show buffers list", silent = true}
    )

    -- Tabs list with F8.
    map(
        "n",
        "<F8>",
        function()
            if _G.TabsList and _G.TabsList.show_tabs_window then
                _G.TabsList.show_tabs_window()
            end
        end,
        {desc = "Show tabs list", silent = true}
    )

    map(
        "n",
        "<leader>et",
        function()
            if _G.TabsList and _G.TabsList.show_tabs_window then
                _G.TabsList.show_tabs_window()
            end
        end,
        {desc = "Show tabs list", silent = true}
    )

    -- Buffer management (moved to <leader>e)
    map("n", "<leader>ed", ":bdelete<CR>", {desc = "Delete buffer"})
    map("n", "<leader>en", ":bnext<CR>", {desc = "Next buffer"})
    map("n", "<leader>ep", ":bprevious<CR>", {desc = "Previous buffer"})

    -- New tab
    map("n", "<leader>eT", ":tabnew<CR>", {desc = "New tab"})
    map("n", "<C-t>", ":tabnew<CR>", {desc = "New tab"})

    -- CODE / LSP / DIAGNOSTICS (<leader>c)

    -- Code Inspector with F7.
    map(
        "n",
        "<F7>",
        function()
            if _G.CodeInspector then
                _G.CodeInspector()
            else
                vim.notify("Code Inspector not loaded", vim.log.levels.WARN)
            end
        end,
        {desc = "Code Inspector", silent = true}
    )

    -- LSP Symbols shortcuts (moved to <leader>c).
    map(
        "n",
        "<leader>cs",
        function()
            if _G.CodeInspector then
                _G.CodeInspector()
            else
                require("telescope.builtin").lsp_document_symbols()
            end
        end,
        {desc = "Document symbols", silent = true}
    )

    -- Grouped view.
    map(
        "n",
        "<leader>cg",
        function()
            if _G.CodeInspectorGrouped then
                _G.CodeInspectorGrouped()
            else
                vim.notify("Code Inspector not loaded", vim.log.levels.WARN)
            end
        end,
        {desc = "Document symbols (grouped)", silent = true}
    )

    -- Workspace symbols.
    map(
        "n",
        "<leader>cw",
        function()
            require("telescope.builtin").lsp_workspace_symbols()
        end,
        {desc = "Workspace symbols", silent = true}
    )

    -- -- Diagnostics (moved from <leader>x to <leader>c)
    map(
        "n",
        "<leader>cc",
        function()
            local diagnostic_opts = {
                focusable = false,
                close_events = {"BufLeave", "CursorMoved", "InsertEnter", "FocusLost"},
                border = "rounded",
                source = "always",
                prefix = " ",
                scope = "line"
            }
            vim.diagnostic.open_float(nil, diagnostic_opts)
        end,
        {desc = "Show line diagnostics"}
    )

    map(
        "n",
        "gL",
        function()
            vim.diagnostic.setloclist()
            vim.cmd("lopen")
            vim.wo.cursorline = true
            vim.wo.number = true
            vim.wo.relativenumber = false
        end,
        {desc = "Open diagnostic quickfix list"}
    )

    map("n", "gl", function()
        local diagnostic_opts = {
            focusable = false,
            close_events = {"BufLeave", "CursorMoved", "InsertEnter", "FocusLost"},
            border = "rounded",
            source = "always",
            prefix = " ",
            scope = "line"
        }
        vim.diagnostic.open_float(nil, diagnostic_opts)
    end, {desc = "Show line diagnostics"})

    -- Diagnostic navigation.
    map("n", "[d", vim.diagnostic.goto_prev,
        {desc = "Previous diagnostic"})
    map("n", "]d", vim.diagnostic.goto_next,
        {desc = "Next diagnostic"})

    -- Diagnostics quickfix (moved to <leader>c).
    map(
        "n",
        "<leader>cl",
        function()
            vim.diagnostic.setloclist()
            vim.cmd("lopen")
            vim.wo.cursorline = true
            vim.wo.number = true
            vim.wo.relativenumber = false
        end,
        {desc = "Open diagnostic quickfix list"}
    )

    -- LSP Code Actions and Rename.
    map("n", "<leader>ca", vim.lsp.buf.code_action, {desc = "Code action"})
    map("n", "<leader>cr", vim.lsp.buf.rename, {desc = "Rename Symbol"})

    -- Format.
    map("n", "<leader>cf", function()
        vim.lsp.buf.format({async = true})
    end, {desc = "Format buffer"})

    -- Sort Python imports.
    map(
        "n", "<leader>ci",
        function()
            vim.cmd("write")
            local function get_python_executable()
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
            local py = get_python_executable()
            local exe = py:gsub("/python$", "/isort")
            local args = table.concat({
                "--profile","black","--line-length","79",
                "--multi-line","3","--trailing-comma"
            }, " ")
            if vim.fn.executable(exe) == 1 then
                vim.cmd("!" .. exe .. " " .. args .. " %")
            else
                vim.cmd("!isort " .. args .. " %")
            end
            vim.cmd("edit!")
        end,
        {desc = "Sort Python Imports"}
    )

    -- SYSTEM / CONFIG / TOOLS (<leader>x)

    -- Clear search highlighting (moved to <leader>x).
    map("n", "<leader>xh", ":nohlsearch<CR>", {desc = "Clear highlights"})

    -- Mason (moved to <leader>x).
    map("n", "<leader>xm", ":Mason<CR>", {desc = "Open Mason"})

    -- Config reload (moved to <leader>x).
    map("n", "<leader>xr", function()
        local current_file = vim.fn.expand("%:p")
        local config_dir = vim.fn.stdpath("config")

        if current_file:match("^" .. vim.pesc(config_dir)) then
            -- If we're in a config file, reload it specifically
            local reload_path = current_file
            if vim.fn.filereadable(reload_path) then
                local ok, err = pcall(dofile, reload_path)
                if ok then
                    vim.notify("Reloaded: " .. vim.fn.fnamemodify(reload_path, ":t"),
                        vim.log.levels.INFO)
                else
                    vim.notify("Error: " .. tostring(err), vim.log.levels.ERROR)
                end
            end
        else
            -- General config reload
            vim.cmd("source " .. config_dir .. "/init.lua")
            vim.notify("Config reloaded", vim.log.levels.INFO)
        end
    end, {desc = "Reload config"})

    -- YANK / CLIPBOARD (<leader>y)

    -- Yank entire buffer to clipboard.
    map(
        "n",
        "<leader>ya",
        'ggVG"+y',
        {desc = "Yank entire buffer to clipboard"}
    )

    -- Yank selection to clipboard
    map("v", "<leader>yy", '"+y', {desc = "Yank selection to clipboard"})

    -- Paste from clipboard.
    map("n", "<leader>yp", '"+p', {desc = "Paste from clipboard"})
    map("v", "<leader>yp", '"+p', {desc = "Paste from clipboard"})

    -- SAVE AND FORMAT

    -- F2 for smart save and format.
    map("n", "<F2>", function()
        safe_save.smart_write()
    end, {desc = "Save and format file"})

    map("i", "<F2>", function()
        vim.cmd("stopinsert")
        safe_save.smart_write()
        vim.cmd("startinsert")
    end, {desc = "Save and format file"})

    -- FORCE LSP TAB BEHAVIOR

    -- Force LSP tab behavior for mouse clicks (global fallback)
    map("n", "<C-LeftMouse>", function()
        if _G.LspDefinitionInTab then
            _G.LspDefinitionInTab()
        else
            vim.lsp.buf.definition()
        end
    end, {desc = "Go to definition (mouse)"})

    -- Reassigning ZZ for smart behavior.
    map("n", "ZZ", function()
        if vim.bo.modified then
            vim.cmd("write")
        end
        smart_tab_close()
    end, {desc = "Save and smart close tab"})

    -- DISABLED KEYS

    -- Disable F1 help (annoying).
    map("n", "<F1>", "<nop>", {desc = "Disabled"})
    map("i", "<F1>", "<nop>", {desc = "Disabled"})
    map("v", "<F1>", "<nop>", {desc = "Disabled"})

    -- Manual trailing spaces cleanup.
    map("n", "<leader>dx", function()
        local save_cursor = vim.fn.getpos(".")
        vim.cmd([[%s/\s\+$//e]])
        vim.fn.setpos(".", save_cursor)
        vim.notify("Trailing spaces cleaned", vim.log.levels.INFO)
    end, {desc = "Clean Trailing Spaces"})

    -- USER COMMANDS
    -- Auto-clean trailing spaces on save
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("TrailingSpaces", { clear = true }),
        pattern = "*",
        callback = function()
            if vim.bo.binary then return end
            local save_cursor = vim.fn.getpos(".")
            vim.cmd([[%s/\s\+$//e]])
            vim.fn.setpos(".", save_cursor)
        end,
    })

    -- Toggle trailing spaces visibility
    map("n", "<leader>dt", function()
        if vim.opt.list:get() then
            vim.opt.list = false
            vim.notify("Trailing spaces hidden", vim.log.levels.INFO)
        else
            vim.opt.list = true
            vim.opt.listchars = { trail = "·" }
            vim.notify("Trailing spaces visible", vim.log.levels.INFO)
        end
    end, {desc = "Toggle Trailing Spaces"})

    -- Smart quit commands with Dashboard-aware logic.
    vim.api.nvim_create_user_command(
        "Q",
        function(opts)
            local filetype = vim.bo.filetype
            if filetype == "dashboard" then
                if opts.bang then
                    vim.cmd("qa!")
                else
                    vim.cmd("qa")
                end
            else
                if opts.bang then
                    force_close_tab()
                else
                    smart_tab_close()
                end
            end
        end,
        {bang = true, desc = "Smart quit command"}
    )

    vim.api.nvim_create_user_command(
        "Wq",
        function(opts)
            vim.cmd("write")
            if opts.bang then
                force_close_tab()
            else
                smart_tab_close()
            end
        end,
        {bang = true, desc = "Write and smart quit"}
    )

    vim.api.nvim_create_user_command(
        "WQ",
        function(opts)
            vim.cmd("write")
            if opts.bang then
                force_close_tab()
            else
                smart_tab_close()
            end
        end,
        {bang = true, desc = "Write and smart quit"}
    )

    -- Setup conditional command abbreviations.
    setup_conditional_abbreviations()

    -- Override :new to create new tab instead of split.
    vim.cmd("cabbrev new tabnew")
end

return M