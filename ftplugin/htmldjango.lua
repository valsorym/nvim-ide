-- ~/.config/nvim/ftplugin/htmldjango.lua
-- Django template settings with formatting protection.

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

-- CRITICAL: Disable all auto-formatting
vim.b.autoformat = false
vim.bo.formatexpr = ""
