-- Key mappings and shortcuts

local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Better up/down (wrapped lines)
keymap("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
keymap("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Move to window using the <Ctrl> hjkl keys
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- Resize window using <Ctrl> arrow keys
keymap("n", "<C-Up>", "<cmd>resize +2<cr>", opts)
keymap("n", "<C-Down>", "<cmd>resize -2<cr>", opts)
keymap("n", "<C-Left>", "<cmd>vertical resize -2<cr>", opts)
keymap("n", "<C-Right>", "<cmd>vertical resize +2<cr>", opts)

-- Move Lines
keymap("n", "<A-j>", "<cmd>m .+1<cr>==", opts)
keymap("n", "<A-k>", "<cmd>m .-2<cr>==", opts)
keymap("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", opts)
keymap("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", opts)
keymap("v", "<A-j>", ":m '>+1<cr>gv=gv", opts)
keymap("v", "<A-k>", ":m '<-2<cr>gv=gv", opts)

-- Buffer navigation
keymap("n", "<S-h>", "<cmd>bprevious<cr>", opts)
keymap("n", "<S-l>", "<cmd>bnext<cr>", opts)
keymap("n", "[b", "<cmd>bprevious<cr>", opts)
keymap("n", "]b", "<cmd>bnext<cr>", opts)

-- Clear search with <Esc>
keymap({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", opts)

-- Save file
keymap({ "i", "v", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", opts)

-- Better indenting
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Lazy
keymap("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- New file
keymap("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

-- Quit all
keymap("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })

-- Diagnostics
keymap("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
keymap("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev Diagnostic" })
keymap("n", "]d", vim.diagnostic.goto_next, { desc = "Next Diagnostic" })

-- Terminal
keymap("t", "<esc><esc>", "<c-\\><c-n>", { desc = "Enter Normal Mode" })
keymap("t", "<C-h>", "<cmd>wincmd h<cr>", { desc = "Go to left window" })
keymap("t", "<C-j>", "<cmd>wincmd j<cr>", { desc = "Go to lower window" })
keymap("t", "<C-k>", "<cmd>wincmd k<cr>", { desc = "Go to upper window" })
keymap("t", "<C-l>", "<cmd>wincmd l<cr>", { desc = "Go to right window" })

-- Toggle options
keymap("n", "<leader>uf", function()
  vim.g.format_on_save = not vim.g.format_on_save
  if vim.g.format_on_save then
    print("Format on save enabled")
  else
    print("Format on save disabled")
  end
end, { desc = "Toggle format on save" })

keymap("n", "<leader>us", function()
  vim.o.spell = not vim.o.spell
  if vim.o.spell then
    print("Spell check enabled")
  else
    print("Spell check disabled")
  end
end, { desc = "Toggle Spelling" })

keymap("n", "<leader>uw", function()
  vim.o.wrap = not vim.o.wrap
  if vim.o.wrap then
    print("Word wrap enabled")
  else
    print("Word wrap disabled")
  end
end, { desc = "Toggle Word Wrap" })

keymap("n", "<leader>ur", function()
  vim.o.relativenumber = not vim.o.relativenumber
  if vim.o.relativenumber then
    print("Relative numbers enabled")
  else
    print("Relative numbers disabled")
  end
end, { desc = "Toggle Relative Number" })