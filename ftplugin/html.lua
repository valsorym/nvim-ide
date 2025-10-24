-- ~/.config/nvim/ftplugin/html.lua
-- HTML settings: convert to htmldjango, no colorcolumn

vim.bo.filetype = "htmldjango"
vim.opt_local.colorcolumn = ""
vim.opt_local.wrap = false
vim.opt_local.expandtab = true
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2