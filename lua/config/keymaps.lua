-- ~/.config/nvim/lua/config/keymaps.lua
-- Centralized keymaps configuration.

local M = {}

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
        end
    else
        vim.cmd("tabclose")
    end
end

-- Force close tab (with !).
local function force_close_tab()
    local total_tabs = vim.fn.tabpagenr("$")
    if total_tabs == 1 then
        vim.cmd("Dashboard")
    else
        vim.cmd("tabclose!")
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
                    pcall(vim.cmd, "cunabbrev q")
                    pcall(vim.cmd, "cunabbrev wq")
                    pcall(vim.cmd, "cunabbrev WQ")
                else
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
                user_opts.attach_mappings = function(prompt_bufnr, map_local)
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
                        vim.cmd("tab drop " .. vim.fn.fnameescape(file))
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

        for _, name in ipairs({
            "find_files",
            "live_grep",
            "buffers",
            "git_files",
            "oldfiles",
            "grep_string",
            "lsp_workspace_symbols"
        }) do
            patch(name)
        end
    end

    -- Apply the patch once on startup.
    pcall(patch_telescope_tabdrop)

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

    -- Create new tab.
    map("n", "<leader>tn", ":tabnew<CR>", {desc = "New tab"})
    map("n", "<C-t>", ":tabnew<CR>", {desc = "New tab"})

    -- File tree modal with F9.
    map(
        "n",
        "<F9>",
        function() _G.NvimTreeModal() end,
        {desc = "Open file explorer", silent = true}
    )

    -- Explorer commands.
    map(
        "n",
        "<leader>ee",
        function() _G.NvimTreeModal() end,
        {desc = "Open file explorer", silent = true}
    )

    -- Buffers list with F10 and leader shortcuts.
    map(
        "n",
        "<F10>",
        function() require("telescope.builtin").buffers() end,
        {desc = "Show buffers list", silent = true}
    )
    map(
        "n",
        "<leader>eb",
        function() require("telescope.builtin").buffers() end,
        {desc = "Show buffers list", silent = true}
    )

    -- Tabs list with F8 and leader shortcut.
    map(
        "n",
        "<F8>",
        function()
            if _G.TabsList and _G.TabsList.show_tabs_window then
                _G.TabsList.show_tabs_window()
            else
                print("TabsList functionality not loaded yet")
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
            else
                print("TabsList functionality not loaded yet")
            end
        end,
        {desc = "Show tabs list", silent = true}
    )

    -- Tab navigation with F keys.
    map("n", "<F5>", ":tabprevious<CR>", {desc = "Previous tab"})
    map("n", "<F6>", ":tabnext<CR>", {desc = "Next tab"})

    -- Smart quit commands with Dashboard-aware logic.
    map("n", "<leader>qq", smart_tab_close, {desc = "Smart close tab"})
    map("n", "<leader>qa", ":qa<CR>", {desc = "Close all tabs and exit"})
    map("n", "<leader>qQ", force_close_tab, {desc = "Force close tab"})
    map("n", "<leader>qA", ":qa!<CR>", {desc = "Force close all and exit"})

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

    -- Stay in indent mode.
    map("v", "<", "<gv", opts)
    map("v", ">", ">gv", opts)

    -- Move text up and down.
    map("v", "<A-j>", ":m .+1<CR>==", opts)
    map("v", "<A-k>", ":m .-2<CR>==", opts)
    map("x", "J", ":move '>+1<CR>gv-gv", opts)
    map("x", "K", ":move '<-2<CR>gv-gv", opts)
    map("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
    map("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)

    -- Better paste.
    map("v", "p", '"_dP', opts)

    -- Yank entire buffer to clipboard.
    map(
        "n",
        "<leader>ya",
        'ggVG"+y',
        {desc = "Yank entire buffer to clipboard"}
    )

    -- Yank selection to clipboard.
    map("v", "<leader>yy", '"+y', {desc = "Yank selection to clipboard"})

    -- Paste from clipboard.
    map("n", "<leader>yp", '"+p', {desc = "Paste from clipboard"})
    map("v", "<leader>yp", '"+p', {desc = "Paste from clipboard"})

    -- Clear search highlighting.
    map("n", "<leader>h", ":nohlsearch<CR>", {desc = "Clear highlights"})

    -- F2 for smart save and format.
    map(
        "n",
        "<F2>",
        function()
            vim.cmd("write")
            if vim.g.format_on_save ~= false then
                vim.lsp.buf.format({async = false, timeout_ms = 2000})
            end
            print("File saved and formatted")
        end,
        {desc = "Save and format file"}
    )
    map(
        "i",
        "<F2>",
        function()
            vim.cmd("stopinsert")
            vim.cmd("write")
            if vim.g.format_on_save ~= false then
                vim.lsp.buf.format({async = false, timeout_ms = 2000})
            end
            vim.cmd("startinsert")
            print("File saved and formatted")
        end,
        {desc = "Save and format file"}
    )

    -- Mason.
    map("n", "<leader>m", ":Mason<CR>", {desc = "Open Mason"})

    -- Diagnostics with improved quickfix window.
    map(
        "n",
        "<leader>xl",
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
    map("n", "<leader>rn", vim.lsp.buf.rename, {desc = "Rename symbol"})

    -- Find/Search mappings (builtins patched to tabs above).
    map(
        "n",
        "<leader>ff",
        function() require("telescope.builtin").find_files() end,
        {desc = "Find files"}
    )
    map(
        "n",
        "<leader>fg",
        function() require("telescope.builtin").live_grep() end,
        {desc = "Live grep"}
    )
    map(
        "n",
        "<leader>fb",
        function() require("telescope.builtin").buffers() end,
        {desc = "Find buffers"}
    )
    map(
        "n",
        "<leader>fh",
        function() require("telescope.builtin").help_tags() end,
        {desc = "Help tags"}
    )
    map(
        "n",
        "<leader>fs",
        function()
            require("telescope.builtin").lsp_document_symbols()
        end,
        {desc = "Document symbols"}
    )
    map(
        "n",
        "<leader>fw",
        function()
            require("telescope.builtin").lsp_workspace_symbols()
        end,
        {desc = "Workspace symbols"}
    )

    -- Buffer management.
    map(
        "n",
        "<leader>bb",
        function() require("telescope.builtin").buffers() end,
        {desc = "List buffers"}
    )
    map("n", "<leader>bd", ":bdelete<CR>", {desc = "Delete buffer"})
    map("n", "<leader>bn", ":bnext<CR>", {desc = "Next buffer"})
    map("n", "<leader>bp", ":bprevious<CR>", {desc = "Previous buffer"})

    -- Code Inspector.
    map(
        "n",
        "<F7>",
        function()
            if _G.CodeInspector then
                _G.CodeInspector()
            else
                vim.notify(
                    "Code Inspector not loaded",
                    vim.log.levels.WARN
                )
            end
        end,
        {desc = "Code Inspector", silent = true}
    )

    map(
        "n",
        "<leader>ls",
        function()
            if _G.CodeInspector then
                _G.CodeInspector()
            else
                require("telescope.builtin").lsp_document_symbols()
            end
        end,
        {desc = "Document symbols", silent = true}
    )
    map(
        "n",
        "<leader>lg",
        function()
            if _G.CodeInspectorGrouped then
                _G.CodeInspectorGrouped()
            else
                vim.notify(
                    "Code Inspector not loaded",
                    vim.log.levels.WARN
                )
            end
        end,
        {desc = "Document symbols (grouped)", silent = true}
    )
    map(
        "n",
        "<leader>lw",
        function()
            require("telescope.builtin").lsp_workspace_symbols()
        end,
        {desc = "Workspace symbols", silent = true}
    )

    -- User commands for smart quit.
    vim.api.nvim_create_user_command(
        "Q",
        function(opts)
            local ft = vim.bo.filetype
            if ft == "dashboard" then
                if opts.bang then vim.cmd("qa!") else vim.cmd("qa") end
            else
                if opts.bang then force_close_tab() else smart_tab_close() end
            end
        end,
        {bang = true, desc = "Smart quit command"}
    )

    vim.api.nvim_create_user_command(
        "Wq",
        function(opts)
            vim.cmd("write")
            if opts.bang then force_close_tab() else smart_tab_close() end
        end,
        {bang = true, desc = "Write and smart quit"}
    )

    vim.api.nvim_create_user_command(
        "WQ",
        function(opts)
            vim.cmd("write")
            if opts.bang then force_close_tab() else smart_tab_close() end
        end,
        {bang = true, desc = "Write and smart quit"}
    )

    -- Setup conditional command abbreviations.
    setup_conditional_abbreviations()

    -- Override :new to create new tab instead of split.
    vim.cmd("cabbrev new tabnew")
end

return M
