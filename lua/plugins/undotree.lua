-- ~/.config/nvim/lua/plugins/undotree.lua
-- Visual undo history tree.

return {
    "mbbill/undotree",
    config = function()
        vim.keymap.set("n", "<leader>xu", vim.cmd.UndotreeToggle,
            {desc = "Toggle Undotree"})

        -- Configuration
        vim.g.undotree_WindowLayout = 2
        vim.g.undotree_ShortIndicators = 1
        vim.g.undotree_SetFocusWhenToggle = 1
    end
}