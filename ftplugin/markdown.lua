-- ~/.config/nvim/ftplugin/markdown.lua
-- Markdown-specific settings

vim.wo.colorcolumn = ""
vim.wo.wrap = true
vim.wo.linebreak = true
vim.wo.breakindent = true
vim.wo.showbreak = "↪ "
vim.bo.expandtab = true
vim.bo.tabstop = 2
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2

-- Dynamic wrap: either at window edge or at 120, whichever is smaller
local function update_wrap_margin()
    local win_width = vim.api.nvim_win_get_width(0)
    local target_width = math.min(win_width - 2, 120)

    -- Use breakindentopt to set soft wrap at desired width
    if win_width < 120 then
        -- Wrap at window edge
        vim.wo.wrap = true
        vim.wo.linebreak = true
    else
        -- Wrap at 120
        vim.wo.wrap = true
        vim.wo.linebreak = true
    end
end

update_wrap_margin()

vim.api.nvim_create_autocmd({"VimResized", "WinResized"}, {
    buffer = 0,
    callback = update_wrap_margin,
})