-- ~/.config/nvim/ftplugin/htmldjango.lua
-- Django template settings.

-- 4 spaces indentation
vim.opt_local.expandtab = true
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4

-- Django comment strings (prefer {# #} for inline)
vim.opt_local.commentstring = "{# %s #}"

-- Enable auto-indent
vim.opt_local.autoindent = true
vim.opt_local.smartindent = true

-- Django-specific keymaps for comments
local map = vim.keymap.set
local opts = {buffer = true, silent = true}

-- Normal comment: {# comment #}
map("n", "<leader>cc", function()
    local line = vim.api.nvim_get_current_line()
    local new_line = "{# " .. line .. " #}"
    vim.api.nvim_set_current_line(new_line)
end, vim.tbl_extend("force", opts, {desc = "Django inline comment"}))

-- Block comment: {% comment %} ... {% endcomment %}
map("n", "<leader>cb", function()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, {"{% comment %}"})
    vim.api.nvim_buf_set_lines(0, row + 1, row + 1, false, {"{% endcomment %}"})
    vim.api.nvim_win_set_cursor(0, {row + 1, 0})
end, vim.tbl_extend("force", opts, {desc = "Django block comment"}))

-- Visual mode: wrap selection in {% comment %}
map("v", "<leader>cb", function()
    -- Get visual selection range
    local start_line = vim.fn.line("'<")
    local end_line = vim.fn.line("'>")

    -- Add {% comment %} before
    vim.api.nvim_buf_set_lines(0, start_line - 1, start_line - 1, false, {"{% comment %}"})

    -- Add {% endcomment %} after (adjust for new line)
    vim.api.nvim_buf_set_lines(0, end_line + 1, end_line + 1, false, {"{% endcomment %}"})

    vim.cmd("normal! gv")
end, vim.tbl_extend("force", opts, {desc = "Django block comment (visual)"}))

-- HTML comment: <!-- comment -->
map("n", "<leader>ch", function()
    local line = vim.api.nvim_get_current_line()
    local new_line = "<!-- " .. line .. " -->"
    vim.api.nvim_set_current_line(new_line)
end, vim.tbl_extend("force", opts, {desc = "HTML comment"}))