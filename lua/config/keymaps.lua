-- ~/.config/nvim/lua/config/keymaps.lua
-- Centralized keymaps configuration.

local M = {}

-- Smart tab close function with Dashboard support
local function smart_tab_close()
    local total_tabs = vim.fn.tabpagenr("$")
    local current_buf = vim.api.nvim_get_current_buf()
    local bufname = vim.fn.bufname(current_buf)
    local filetype = vim.bo[current_buf].filetype
    local is_modified = vim.bo[current_buf].modified

    -- If it's the last tab
    if total_tabs == 1 then
        -- Check if it's Dashboard - only Dashboard should close Neovim
        if filetype == "dashboard" then
            -- Close Neovim completely
            vim.cmd("qa")
        else
            -- For any other buffer (files, empty buffers, etc.) - open Dashboard
            vim.cmd("Dashboard")
        end
    else
        -- Multiple tabs exist - just close current tab
        vim.cmd("tabclose")
    end
end

-- Force close tab (with !)
local function force_close_tab()
    local total_tabs = vim.fn.tabpagenr("$")

    if total_tabs == 1 then
        -- Last tab - open Dashboard regardless of modifications
        vim.cmd("Dashboard")
    else
        -- Multiple tabs - force close current tab
        vim.cmd("tabclose!")
    end
end

-- Setup conditional abbreviations for command line
local function setup_conditional_abbreviations()
    vim.api.nvim_create_autocmd(
        {"BufEnter", "FileType"},
        {
            callback = function()
                local filetype = vim.bo.filetype

                if filetype == "dashboard" then
                    -- In Dashboard - remove abbreviations, allow native :q behavior
                    pcall(vim.cmd, "cunabbrev q")
                    pcall(vim.cmd, "cunabbrev wq")
                    pcall(vim.cmd, "cunabbrev WQ")
                else
                    -- In normal files - set up buffer-local abbreviations
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

    -- Tabs navigation
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

    -- Move current tab
    map("n", "<A-h>", ":-tabmove<CR>", {desc = "Move tab left"})
    map("n", "<A-l>", ":+tabmove<CR>", {desc = "Move tab right"})

    -- Create new tab
    map("n", "<leader>tn", ":tabnew<CR>", {desc = "New tab"})
    map("n", "<C-t>", ":tabnew<CR>", {desc = "New tab"})

    -- File tree modal with F9
    map(
        "n",
        "<F9>",
        function()
            _G.NvimTreeModal()
        end,
        {desc = "Open file explorer", silent = true}
    )

    -- Explorer commands
    map(
        "n",
        "<leader>ee",
        function()
            _G.NvimTreeModal()
        end,
        {desc = "Open file explorer", silent = true}
    )

    -- Buffers list with F10 and leader shortcuts
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

    -- Tabs list with F8 and leader shortcut
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

    -- Tab navigation with F keys
    map("n", "<F5>", ":tabprevious<CR>", {desc = "Previous tab"})
    map("n", "<F6>", ":tabnext<CR>", {desc = "Next tab"})

    -- Smart quit commands with Dashboard-aware logic
    map("n", "<leader>qq", smart_tab_close, {desc = "Smart close current tab"})
    map("n", "<leader>qa", ":qa<CR>", {desc = "Close all tabs and exit"})
    map("n", "<leader>qQ", force_close_tab, {desc = "Force close current tab"})
    map("n", "<leader>qA", ":qa!<CR>", {desc = "Force close all tabs and exit"})

    -- Better window navigation
    map("n", "<C-h>", "<C-w>h", {desc = "Go to left window"})
    map("n", "<C-j>", "<C-w>j", {desc = "Go to lower window"})
    map("n", "<C-k>", "<C-w>k", {desc = "Go to upper window"})
    map("n", "<C-l>", "<C-w>l", {desc = "Go to right window"})

    -- Resize windows
    map("n", "<C-Up>", ":resize +2<CR>", opts)
    map("n", "<C-Down>", ":resize -2<CR>", opts)
    map("n", "<C-Left>", ":vertical resize -2<CR>", opts)
    map("n", "<C-Right>", ":vertical resize +2<CR>", opts)

    -- Stay in indent mode
    map("v", "<", "<gv", opts)
    map("v", ">", ">gv", opts)

    -- Move text up and down
    map("v", "<A-j>", ":m .+1<CR>==", opts)
    map("v", "<A-k>", ":m .-2<CR>==", opts)
    map("x", "J", ":move '>+1<CR>gv-gv", opts)
    map("x", "K", ":move '<-2<CR>gv-gv", opts)
    map("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
    map("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)

    -- Better paste
    map("v", "p", '"_dP', opts)

    -- Yank entire buffer to clipboard
    map("n", "<leader>ya", 'ggVG"+y', {desc = "Yank entire buffer to clipboard"})

    -- Yank selection to clipboard
    map("v", "<leader>yy", '"+y', {desc = "Yank selection to clipboard"})

    -- Paste from clipboard
    map("n", "<leader>yp", '"+p', {desc = "Paste from clipboard"})
    map("v", "<leader>yp", '"+p', {desc = "Paste from clipboard"})

    -- Clear search highlighting
    map("n", "<leader>h", ":nohlsearch<CR>", {desc = "Clear highlights"})

    -- F2 for smart save and format
    map(
        "n",
        "<F2>",
        function()
            -- Save file
            vim.cmd("write")
            -- Format if formatting is available and enabled
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
            -- Exit insert mode, save and format, then return to insert mode
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

    -- Mason
    map("n", "<leader>m", ":Mason<CR>", {desc = "Open Mason"})

    -- Diagnostics with improved quickfix window
    map(
        "n",
        "<leader>xl",
        function()
            vim.diagnostic.setloclist()
            -- Open quickfix window and enable cursorline
            vim.cmd("lopen")
            vim.wo.cursorline = true
            vim.wo.number = true
            vim.wo.relativenumber = false
        end,
        {desc = "Open diagnostic quickfix list"}
    )

    -- Create user commands to replace :q, :wq, etc with smart logic
    vim.api.nvim_create_user_command(
        "Q",
        function(opts)
            local filetype = vim.bo.filetype
            if filetype == "dashboard" then
                -- In Dashboard - behave like normal :q
                if opts.bang then
                    vim.cmd("qa!")
                else
                    vim.cmd("qa")
                end
            else
                -- In normal files - use smart logic
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

    -- Setup conditional command abbreviations
    setup_conditional_abbreviations()

    -- Override :new to create new tab instead of split
    vim.cmd("cabbrev new tabnew")
end

return M
