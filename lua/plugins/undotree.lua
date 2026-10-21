-- ~/.config/nvim/lua/plugins/undotree.lua
-- Visual undo history tree.

return {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    config = function()
        -- Layout: left = diff, right = tree
        vim.g.undotree_WindowLayout = 2

        -- Show diff automatically when tree opens
        vim.g.undotree_DiffAutoOpen = 1
        vim.g.undotree_SetFocusWhenToggle = 1

        -- Compact visual tweaks
        vim.g.undotree_ShortIndicators = 1
        vim.g.undotree_SplitWidth = 40
        vim.g.undotree_DiffpanelHeight = 12
        vim.g.undotree_TreeNodeShape = "●" -- "●"
        vim.g.undotree_TreeVertShape = "│" -- "│"
        vim.g.undotree_TreeSplitShape = "" -- "╱"
        vim.g.undotree_TreeReturnShape = "" -- "╲"

    end,
}
