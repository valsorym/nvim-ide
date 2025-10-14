-- ~/.config/nvim/lua/plugins/undotree.lua
-- Visual undo history tree.

return {
    "mbbill/undotree",
    event = "VeryLazy",
    keys = {
        { "<leader>xu", vim.cmd.UndotreeToggle, desc = "Toggle Undotree" },
    },
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

        -- Ensure persistent undo is enabled
        local undodir = vim.fn.stdpath("data") .. "/undo"
        if vim.fn.isdirectory(undodir) == 0 then
            vim.fn.mkdir(undodir, "p")
        end
        vim.o.undofile = true
        vim.o.undodir = undodir

        -- Optional: focus on latest change when Undotree opens
        vim.api.nvim_create_autocmd("User", {
            pattern = "UndotreeToggle",
            callback = function()
                pcall(vim.cmd, "normal! g;")
            end,
        })
    end,
}