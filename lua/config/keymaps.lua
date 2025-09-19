-- ~/.config/nvim/lua/config/keymaps.lua
-- Centralized keymaps.

local M = {}

function M.setup()
    local map = vim.keymap.set
    local opts = {noremap = true, silent = true}

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

    -- File tree toggle with F9.
    map(
        "n",
        "<F9>",
        function()
            require("nvim-tree.api").tree.toggle()
        end,
        {desc = "Toggle file tree", silent = true}
    )

    -- Sync tree with current file.
    map(
        "n",
        "<leader>ef",
        function()
            require("nvim-tree.api").tree.find_file()
        end,
        {desc = "Find current file in tree", silent = true}
    )

    -- Tab navigation with F keys.
    map("n", "<F5>", ":tabprevious<CR>", {desc = "Previous tab"})
    map("n", "<F6>", ":tabnext<CR>", {desc = "Next tab"})

    -- Global quit commands - close all tabs and exit.
    map("n", "<leader>qq", ":qa<CR>", {desc = "Quit all and exit"})
    map("n", "<leader>qQ", ":qa!<CR>", {desc = "Force quit all and exit"})

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

    -- Yank entire buffer to clipboard
    map("n", "<leader>ya", "ggVG\"+y",
        { desc = "Yank entire buffer to clipboard" })

    -- Yank selection to clipboard
    map("v", "<leader>yy", '"+y',
        { desc = "Yank selection to clipboard" })

    -- Paste from clipboard
    map("n", "<leader>yp", '"+p',
        { desc = "Paste from clipboard" })
    map("v", "<leader>yp", '"+p',
        { desc = "Paste from clipboard" })


    -- Clear search highlighting.
    map("n", "<leader>h", ":nohlsearch<CR>", {desc = "Clear highlights"})

    -- F2 for smart save and format
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

    -- Diagnostics.
    map("n", "<leader>q", vim.diagnostic.setloclist, {desc = "Open diagnostic quickfix list"})
end

return M
