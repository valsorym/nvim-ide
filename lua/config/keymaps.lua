-- ~/.config/nvim/lua/config/keymaps.lua
-- Centralized keymaps configuration with clean structure and no duplicates.

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

-- Close all saved tabs and return to Dashboard.
local function close_saved_tabs()
    local total_tabs = vim.fn.tabpagenr("$")
    local modified_tabs = 0
    local tabs_to_close = {}

    -- Identify which tabs to close.
    for tab_nr = 1, total_tabs do
        local buflist = vim.fn.tabpagebuflist(tab_nr)
        local has_modified = false

        -- Check if any buffer in this tab is modified.
        for _, buf in ipairs(buflist) do
            if vim.bo[buf].modified then
                has_modified = true
                break
            end
        end

        if has_modified then
            modified_tabs = modified_tabs + 1
        else
            -- Mark for closing.
            table.insert(tabs_to_close, tab_nr)
        end
    end

    -- If nothing to close.
    if #tabs_to_close == 0 then
        vim.notify(
            string.format(
                "All %d tabs have unsaved changes. Nothing to close.",
                modified_tabs
            ),
            vim.log.levels.WARN
        )
        return
    end

    -- If ALL tabs are saved - show Dashboard first, then close all.
    if #tabs_to_close == total_tabs then
        vim.cmd("Dashboard")
        cleanup_orphan_buffers(false)

        vim.notify(
            string.format(
                "All %d tabs closed. Dashboard opened.",
                #tabs_to_close
            ),
            vim.log.levels.INFO
        )
        return
    end

    -- Some tabs have unsaved changes - close only saved tabs.
    local closed_count = 0
    for i = #tabs_to_close, 1, -1 do
        local tab_nr = tabs_to_close[i]
        vim.cmd(tab_nr .. "tabclose")
        closed_count = closed_count + 1
    end

    vim.notify(
        string.format(
            "Closed %d saved tabs. %d tabs with unsaved changes remain.",
            closed_count,
            modified_tabs
        ),
        vim.log.levels.WARN
    )
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

    -- ========================================================================
    -- BASIC NAVIGATION & MOVEMENT
    -- ========================================================================

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
    map("v", "<A-k>", ":m .-2<CR>", opts)
    map("x", "J", ":move '>+1<CR>gv-gv", opts)
    map("x", "K", ":move '<-2<CR>gv-gv", opts)
    map("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
    map("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)

    -- Stay in indent mode.
    map("v", "<", "<gv", opts)
    map("v", ">", ">gv", opts)
    map("x", "<", "<gv", opts)
    map("x", ">", ">gv", opts)

    -- Better paste.
    map("v", "p", '"_dP', opts)

    -- Delete without yanking (z prefix).
    map("n", "zdd", '"_dd', {desc = "Delete line without yank"})
    map("n", "zdw", '"_dw', {desc = "Delete word without yank"})
    map("n", "zD", '"_D', {desc = "Delete to end without yank"})
    map("n", "zx", '"_x', {desc = "Delete char without yank"})
    map("n", "zcc", '"_cc', {desc = "Change line without yank"})
    map("n", "zcw", '"_cw', {desc = "Change word without yank"})
    map("n", "zC", '"_C', {desc = "Change to end without yank"})
    map("v", "zd", '"_d', {desc = "Delete selection without yank"})
    map("v", "zc", '"_c', {desc = "Change selection without yank"})

    -- VSCode-style indentation with Shift+< and Shift+>.
    map("n", "<S-<>", "<<", {desc = "Outdent line"})
    map("n", "<S->>", ">>", {desc = "Indent line"})
    map("v", "<S-<>", "<gv", {desc = "Outdent selection"})
    map("v", "<S->>", ">gv", {desc = "Indent selection"})
    map("i", "<S-<>", "<C-o><<", {desc = "Outdent line (insert mode)"})
    map("i", "<S->>", "<C-o>>>", {desc = "Indent line (insert mode)"})
    map("s", "<S-<>", "<C-o><gv", {desc = "Outdent selection"})
    map("s", "<S->>", "<C-o>>gv", {desc = "Indent selection"})

    -- ========================================================================
    -- TAB NAVIGATION & MANAGEMENT
    -- ========================================================================

    -- Tab navigation with Alt keys.
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
    map("n", "<S-Left>", ":-tabmove<CR>", {desc = "Move tab left"})
    map("n", "<S-Right>", ":+tabmove<CR>", {desc = "Move tab right"})

    -- Move current tab to the end/beginning.
    map("n", "<S-A-Right>", function()
        local total = vim.fn.tabpagenr("$")
        vim.cmd("tabmove " .. total)
        vim.notify("Tab moved to end", vim.log.levels.INFO)
    end, {desc = "Move tab to end"})

    map("n", "<S-A-Left>", function()
        vim.cmd("tabmove 0")
        vim.notify("Tab moved to start", vim.log.levels.INFO)
    end, {desc = "Move tab to start"})

    -- Tab navigation with F keys.
    map("n", "<F5>", function()
        local current = vim.fn.tabpagenr()
        if current > 1 then
            vim.cmd("tabprevious")
        end
    end, {desc = "Previous tab"})

    map("n", "<F6>", function()
        local current = vim.fn.tabpagenr()
        local total = vim.fn.tabpagenr("$")
        if current < total then
            vim.cmd("tabnext")
        end
    end, {desc = "Next tab"})

    -- New tab shortcuts.
    map("n", "<C-t>", ":tabnew<CR>", {desc = "New tab"})

    -- ========================================================================
    -- FUNCTION KEYS (F1-F12)
    -- ========================================================================

    -- Disable F1 help (annoying).
    map("n", "<F1>", "<nop>", {desc = "Disabled"})
    map("i", "<F1>", "<nop>", {desc = "Disabled"})
    map("v", "<F1>", "<nop>", {desc = "Disabled"})

    -- F2 for smart save and format.
    map("n", "<F2>", function()
        local bufname = vim.api.nvim_buf_get_name(0)

        -- Check if buffer is unnamed.
        if bufname == "" or bufname:match("^%[No Name%]") then
            vim.ui.input({
                prompt = "Save as: ",
                default = vim.fn.getcwd() .. "/",
                completion = "file",
            }, function(filename)
                if filename and filename ~= "" then
                    vim.cmd("write " .. vim.fn.fnameescape(filename))
                    vim.notify("💾 Saved: " .. filename, vim.log.levels.INFO)
                end
            end)
        else
            safe_save.smart_write()
        end
    end, {desc = "Save and format file"})

    map("i", "<F2>", function()
        vim.cmd("stopinsert")

        local bufname = vim.api.nvim_buf_get_name(0)

        if bufname == "" or bufname:match("^%[No Name%]") then
            vim.ui.input({
                prompt = "Save as: ",
                default = vim.fn.getcwd() .. "/",
                completion = "file",
            }, function(filename)
                if filename and filename ~= "" then
                    vim.cmd("write " .. vim.fn.fnameescape(filename))
                    vim.notify("💾 Saved: " .. filename, vim.log.levels.INFO)
                end
                vim.cmd("startinsert")
            end)
        else
            safe_save.smart_write()
            vim.cmd("startinsert")
        end
    end, {desc = "Save and format file"})

    -- F7 for Code Inspector.
    map("n", "<F7>", function()
        if _G.CodeInspector then
            _G.CodeInspector()
        else
            vim.notify("Code Inspector not loaded", vim.log.levels.WARN)
        end
    end, {desc = "Code Inspector", silent = true})

    -- F8 for Tabs List.
    map("n", "<F8>", function()
        if _G.TabsList and _G.TabsList.show_tabs_window then
            _G.TabsList.show_tabs_window()
        end
    end, {desc = "Show tabs list", silent = true})

    -- F9 for File Explorer.
    map("n", "<F9>", function()
        if _G.NvimTreeModal then
            _G.NvimTreeModal()
        end
    end, {desc = "Open file explorer", silent = true})

    -- F10 for Buffers List.
    map("n", "<F10>", function()
        require("telescope.builtin").buffers()
    end, {desc = "Show buffers list", silent = true})

    -- ========================================================================
    -- CLEAR SEARCH & ESCAPE
    -- ========================================================================

    -- Clear search highlighting with Esc.
    map("n", "<Esc>", ":nohlsearch<CR>",
        {desc = "Clear search highlights", silent = true})

    -- ========================================================================
    -- LSP & DIAGNOSTICS (basic LSP keymaps - detailed ones in lsp.lua)
    -- ========================================================================

    -- Signature help with Ctrl+k.
    map("n", "<C-k>", vim.lsp.buf.signature_help, {desc = "Signature Help"})
    map("i", "<C-k>", vim.lsp.buf.signature_help, {desc = "Signature Help"})

    -- Diagnostic navigation.
    map("n", "[d", vim.diagnostic.goto_prev, {desc = "Previous diagnostic"})
    map("n", "]d", vim.diagnostic.goto_next, {desc = "Next diagnostic"})

    -- Quick diagnostic float.
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

    -- LSP References quickfix.
    map("n", "gL", function()
        vim.diagnostic.setloclist()
        vim.cmd("lopen")
        vim.wo.cursorline = true
        vim.wo.number = true
        vim.wo.relativenumber = false
        vim.keymap.set("n", "q", "<cmd>lclose<CR>", {
            buffer = true,
            silent = true,
        })
    end, {desc = "Open diagnostic quickfix list"})

    -- ========================================================================
    -- GIT NAVIGATION
    -- ========================================================================

    -- Git hunks navigation.
    map("n", "]c", function()
        if vim.wo.diff then return "]c" end
        vim.schedule(function()
            if package.loaded.gitsigns then
                require("gitsigns").next_hunk()
            end
        end)
        return "<Ignore>"
    end, {expr = true, desc = "Next Git hunk"})

    map("n", "[c", function()
        if vim.wo.diff then return "[c" end
        vim.schedule(function()
            if package.loaded.gitsigns then
                require("gitsigns").prev_hunk()
            end
        end)
        return "<Ignore>"
    end, {expr = true, desc = "Previous Git hunk"})

    -- ========================================================================
    -- TODO NAVIGATION
    -- ========================================================================

    -- TODO comments navigation.
    map("n", "]t", function()
        if package.loaded["todo-comments"] then
            require("todo-comments").jump_next()
        end
    end, {desc = "Next TODO"})

    map("n", "[t", function()
        if package.loaded["todo-comments"] then
            require("todo-comments").jump_prev()
        end
    end, {desc = "Previous TODO"})

    -- ========================================================================
    -- UNDO/REDO SHORTCUTS
    -- ========================================================================

    map("n", "<C-z>", "u", {desc = "Undo"})
    map("n", "<C-y>", "<C-r>", {desc = "Redo"})
    map("i", "<C-z>", "<C-o>u", {desc = "Undo (insert mode)"})
    map("i", "<C-y>", "<C-o><C-r>", {desc = "Redo (insert mode)"})

    -- ========================================================================
    -- SPECIAL BEHAVIORS
    -- ========================================================================

    -- Force LSP tab behavior for mouse clicks.
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

    -- ========================================================================
    -- UTILITY FUNCTIONS
    -- ========================================================================

    -- Manual trailing spaces cleanup.
    map("n", "<leader>dx", function()
        local save_cursor = vim.fn.getpos(".")
        vim.cmd([[%s/\s\+$//e]])
        vim.fn.setpos(".", save_cursor)
        vim.notify("Trailing spaces cleaned", vim.log.levels.INFO)
    end, {desc = "Clean Trailing Spaces"})

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

    -- ========================================================================
    -- USER COMMANDS
    -- ========================================================================

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

-- User command for closing saved tabs.
vim.api.nvim_create_user_command(
    "CloseSavedTabs",
    close_saved_tabs,
    {desc = "Close all saved tabs and return to Dashboard"}
)

-- Export functions for use in legendary.
M.close_saved_tabs = close_saved_tabs
M.smart_tab_close = smart_tab_close
M.force_close_tab = force_close_tab

return M