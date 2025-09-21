-- Close all buffers in current tab
local function close_tab_buffers()
    local current_tab = vim.fn.tabpagenr()
    local buflist = vim.fn.tabpagebuflist(current_tab)
    local total_tabs = vim.fn.tabpagenr("$")

    -- Check if any buffers are modified
    local modified_buffers = {}
    for _, buf in ipairs(buflist) do
        local buf_name = vim.fn.bufname(buf)
        local buf_ft = vim.bo[buf].filetype
        -- Skip special buffers
        if buf_name ~= "" and not buf_name:match("NvimTree") and buf_ft ~= "dashboard" then
            if vim.bo[buf].modified then
                table.insert(modified_buffers, vim.fn.fnamemodify(buf_name, ":t"))
            end
        end
    end

    -- Ask about modified buffers
    if #modified_buffers > 0 then
        local files_list = table.concat(modified_buffers, ", ")
        local choice = vim.fn.confirm(
            "Save changes to: " .. files_list .. "?",
            "&Yes\n&No\n&Cancel", 1
        )
        if choice == 1 then
            vim.cmd("wa")  -- Write all
        elseif choice == 3 then
            return  -- Cancel
        end
        -- choice == 2 (No) - continue without saving
    end

    -- Close all buffers in current tab
    for _, buf in ipairs(buflist) do
        local buf_name = vim.fn.bufname(buf)
        local buf_ft = vim.bo[buf].filetype
        -- Skip special buffers
        if buf_name ~= "" and not buf_name:match("NvimTree") and buf_ft ~= "dashboard" then
            vim.api.nvim_buf_delete(buf, {force = true})
        end
    end

    -- If this was the last tab, open Dashboard
    if total_tabs == 1 then
        vim.cmd("Dashboard")
    else
        vim.cmd("tabclose")
    end
end-- ~/.config/nvim/lua/config/keymaps.lua
-- Centralized keymaps configuration with vim-way approach.

local M = {}

-- Tab naming system
_G.tab_names = _G.tab_names or {}

-- Function to set tab name
local function set_tab_name()
    local current_tab = vim.fn.tabpagenr()
    local current_name = _G.tab_names[current_tab] or ""

    vim.ui.input({
        prompt = "Tab name: ",
        default = current_name,
    }, function(input)
        if input then
            if input == "" then
                _G.tab_names[current_tab] = nil
            else
                _G.tab_names[current_tab] = input
            end
            -- Force tabline refresh
            vim.cmd("redrawtabline")
        end
    end)
end

-- Function to get tab display name for external use
function M.get_tab_display_name(tab_nr)
    if _G.tab_names[tab_nr] then
        return _G.tab_names[tab_nr]
    end

    -- Default behavior - get file name
    local buflist = vim.fn.tabpagebuflist(tab_nr)
    local winnr = vim.fn.tabpagewinnr(tab_nr)
    local buf = buflist[winnr]

    -- Find the first normal buffer (not NvimTree).
    for _, b in ipairs(buflist) do
        local name = vim.fn.bufname(b)
        if not name:match("NvimTree_") and name ~= "" then
            buf = b
            break
        end
    end

    local file = vim.fn.bufname(buf)
    local label = vim.fn.fnamemodify(file, ":t")

    -- Handle special cases
    if label == "" then
        local filetype = vim.bo[buf].filetype
        if filetype == "dashboard" then
            label = "Dashboard"
        else
            label = "[No Name]"
        end
    end

    if vim.bo[buf].modified then
        label = label .. "*"
    end

    return label
end

-- Smart buffer close function with proper vim-way logic
local function smart_close()
    local current_buf = vim.api.nvim_get_current_buf()
    local bufname = vim.fn.bufname(current_buf)
    local filetype = vim.bo[current_buf].filetype
    local is_modified = vim.bo[current_buf].modified
    local total_tabs = vim.fn.tabpagenr("$")

    -- Special case for Dashboard
    if filetype == "dashboard" then
        if total_tabs == 1 then
            vim.cmd("qa")  -- Close Neovim completely
        else
            vim.cmd("tabclose")  -- Close dashboard tab
        end
        return
    end

    -- Count how many listed buffers we have
    local listed_buffers = 0
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
            local buf_name = vim.fn.bufname(buf)
            local buf_ft = vim.bo[buf].filetype
            -- Skip special buffers
            if buf_name ~= "" and not buf_name:match("NvimTree") and buf_ft ~= "dashboard" then
                listed_buffers = listed_buffers + 1
            end
        end
    end

    -- For normal buffers - delete buffer (vim-way)
    if is_modified then
        local choice = vim.fn.confirm("Buffer has unsaved changes. Save?", "&Yes\n&No\n&Cancel", 1)
        if choice == 1 then
            vim.cmd("write")
        elseif choice == 2 then
            -- Continue to delete
        else
            -- Cancel - do nothing
            return
        end
    end

    -- If this is the last real buffer, handle specially
    if listed_buffers <= 1 then
        if total_tabs == 1 then
            -- Last buffer in last tab - open Dashboard
            vim.cmd("Dashboard")
        else
            -- Last buffer in non-last tab - close tab
            vim.cmd("tabclose")
        end
    else
        -- Multiple buffers exist - just delete current buffer
        vim.cmd("bdelete")
    end
end

-- Force close tab (with !).
local function force_close_tab()
    local total_tabs = vim.fn.tabpagenr("$")

    if total_tabs == 1 then
        -- Last tab - open Dashboard regardless of modifications.
        vim.cmd("Dashboard")
    else
        -- Multiple tabs - force close current tab.
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

-- Clean up tab names when tabs are closed
local function cleanup_tab_names()
    local max_tab = vim.fn.tabpagenr("$")
    for tab_nr, _ in pairs(_G.tab_names) do
        if tab_nr > max_tab then
            _G.tab_names[tab_nr] = nil
        end
    end
end

function M.setup()
    local map = vim.keymap.set
    local opts = {noremap = true, silent = true}

    -- BUFFER NAVIGATION (primary workflow)
    map("n", "<leader>bn", ":bnext<CR>", {desc = "Next buffer"})
    map("n", "<leader>bp", ":bprevious<CR>", {desc = "Previous buffer"})
    map("n", "<leader>bd", ":bdelete<CR>", {desc = "Delete buffer"})
    map("n", "<leader>bD", ":bdelete!<CR>", {desc = "Force delete buffer"})

    -- Quick buffer navigation with Alt keys
    map("n", "<A-j>", ":bnext<CR>", {desc = "Next buffer"})
    map("n", "<A-k>", ":bprevious<CR>", {desc = "Previous buffer"})

    -- Tab navigation (secondary, for layout management)
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

    -- Tab naming
    map("n", "<leader>tr", set_tab_name, {desc = "Rename current tab"})

    -- File tree modal with F9.
    map(
        "n",
        "<F9>",
        function()
            _G.NvimTreeModal()
        end,
        {desc = "Open file explorer", silent = true}
    )

    -- Explorer commands.
    map(
        "n",
        "<leader>ee",
        function()
            _G.NvimTreeModal()
        end,
        {desc = "Open file explorer", silent = true}
    )

    -- Buffers list with F10 and leader shortcuts.
    map(
        "n",
        "<F10>",
        function()
            if _G.ContextualBuffers then
                _G.ContextualBuffers()
            else
                require("telescope.builtin").buffers()
            end
        end,
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

    -- Smart quit commands with proper vim-way buffer logic
    map("n", "<leader>qq", smart_close, {desc = "Close current buffer"})
    map("n", "<leader>qa", close_tab_buffers, {desc = "Close all buffers in current tab"})
    map("n", "<leader>qA", ":qa<CR>", {desc = "Close all tabs (exit Neovim)"})
    map("n", "<leader>qQ", ":bdelete!<CR>", {desc = "Force close current buffer"})
    map("n", "<leader>q!", ":qa!<CR>", {desc = "Force exit Neovim"})

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
    map("n", "<leader>ya", 'ggVG"+y', {desc = "Yank entire buffer to clipboard"})

    -- Yank selection to clipboard
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
            -- Save file.
            vim.cmd("write")
            -- Format if formatting is available and enabled.
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
            -- Exit insert mode, save and format, then return to insert mode.
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
            -- Open quickfix window and enable cursorline.
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

    -- Find/Search mappings (handled by telescope in additional.lua)
    map("n", "<leader>ff", function()
        require("telescope.builtin").find_files()
    end, {desc = "Find files"})

    map("n", "<leader>fg", function()
        require("telescope.builtin").live_grep()
    end, {desc = "Live grep"})

    map("n", "<leader>fh", function()
        require("telescope.builtin").help_tags()
    end, {desc = "Help tags"})

    map("n", "<leader>fs", function()
        require("telescope.builtin").lsp_document_symbols()
    end, {desc = "Document symbols"})

    map("n", "<leader>fw", function()
        require("telescope.builtin").lsp_workspace_symbols()
    end, {desc = "Workspace symbols"})

    -- Buffer management (vim-way primary workflow)
    map("n", "<leader>bb", function()
        -- Use contextual buffers if available, otherwise fallback
        if _G.ContextualBuffers then
            _G.ContextualBuffers()
        else
            require("telescope.builtin").buffers()
        end
    end, {desc = "List buffers"})

    -- Code Inspector with F7.
    map("n", "<F7>", function()
        if _G.CodeInspector then
            _G.CodeInspector()
        else
            vim.notify("Code Inspector not loaded", vim.log.levels.WARN)
        end
    end, {desc = "Code Inspector", silent = true})

    -- LSP Symbols shortcuts.
    map("n", "<leader>ls", function()
        if _G.CodeInspector then
            _G.CodeInspector()
        else
            require("telescope.builtin").lsp_document_symbols()
        end
    end, {desc = "Document symbols", silent = true})

    -- Grouped view.
    map("n", "<leader>lg", function()
        if _G.CodeInspectorGrouped then
            _G.CodeInspectorGrouped()
        else
            vim.notify("Code Inspector not loaded", vim.log.levels.WARN)
        end
    end, {desc = "Document symbols (grouped)", silent = true})

    -- Workspace symbols.
    map("n", "<leader>lw", function()
        require("telescope.builtin").lsp_workspace_symbols()
    end, {desc = "Workspace symbols", silent = true})

    -- Create user commands with proper vim-way logic
    vim.api.nvim_create_user_command(
        "Q",
        function(opts)
            local filetype = vim.bo.filetype
            if filetype == "dashboard" then
                -- In Dashboard - close Neovim
                if opts.bang then
                    vim.cmd("qa!")
                else
                    vim.cmd("qa")
                end
            else
                -- Normal buffer - close current buffer
                if opts.bang then
                    vim.cmd("bdelete!")
                else
                    smart_close()
                end
            end
        end,
        {bang = true, desc = "Close current buffer"}
    )

    vim.api.nvim_create_user_command(
        "Qa",
        function(opts)
            -- Close all buffers in current tab
            if opts.bang then
                -- Force close all buffers in tab
                local buflist = vim.fn.tabpagebuflist()
                for _, buf in ipairs(buflist) do
                    local buf_name = vim.fn.bufname(buf)
                    local buf_ft = vim.bo[buf].filetype
                    if buf_name ~= "" and not buf_name:match("NvimTree") and buf_ft ~= "dashboard" then
                        vim.api.nvim_buf_delete(buf, {force = true})
                    end
                end
                local total_tabs = vim.fn.tabpagenr("$")
                if total_tabs == 1 then
                    vim.cmd("Dashboard")
                else
                    vim.cmd("tabclose")
                end
            else
                close_tab_buffers()
            end
        end,
        {bang = true, desc = "Close all buffers in current tab"}
    )

    vim.api.nvim_create_user_command(
        "QA",
        function(opts)
            -- Close all tabs (exit Neovim)
            if opts.bang then
                vim.cmd("qa!")
            else
                vim.cmd("qa")
            end
        end,
        {bang = true, desc = "Exit Neovim (close all tabs)"}
    )

    vim.api.nvim_create_user_command(
        "Wq",
        function(opts)
            vim.cmd("write")
            if opts.bang then
                vim.cmd("bdelete!")
            else
                smart_close()
            end
        end,
        {bang = true, desc = "Write and close buffer"}
    )

    vim.api.nvim_create_user_command(
        "WQ",
        function(opts)
            vim.cmd("write")
            if opts.bang then
                vim.cmd("bdelete!")
            else
                smart_close()
            end
        end,
        {bang = true, desc = "Write and close buffer"}
    )

    -- Tab naming commands
    vim.api.nvim_create_user_command("TabRename", set_tab_name, {desc = "Rename current tab"})
    vim.api.nvim_create_user_command("TabClearName", function()
        local current_tab = vim.fn.tabpagenr()
        _G.tab_names[current_tab] = nil
        vim.cmd("redrawtabline")
        print("Tab name cleared")
    end, {desc = "Clear current tab name"})

    -- Setup conditional command abbreviations.
    setup_conditional_abbreviations()

    -- Override :new to create new tab instead of split.
    vim.cmd("cabbrev new tabnew")

    -- Set up autocmds for tab name cleanup
    vim.api.nvim_create_augroup("TabNaming", { clear = true })
    vim.api.nvim_create_autocmd("TabClosed", {
        group = "TabNaming",
        callback = cleanup_tab_names,
    })
end

return M