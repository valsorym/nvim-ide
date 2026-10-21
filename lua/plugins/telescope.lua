-- One setup call owns file search, previews, selection and extensions.
return {
    "nvim-telescope/telescope.nvim",
    cmd = { "Telescope", "CodeInspector", "CodeInspectorGrouped" },
    dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons",
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make", cond = function() return vim.fn.executable("make") == 1 end } },
    config = function()
        local actions = require("telescope.actions")
        require("telescope").setup({
            defaults = {
                path_display = { "truncate" },
                sorting_strategy = "ascending",
                layout_config = { prompt_position = "top", width = 0.9, height = 0.8 },
                preview = { filesize_limit = 1, timeout = 200 },
                file_ignore_patterns = { "%.git/", "node_modules/", "__pycache__/", "%.venv/", "venv/" },
                mappings = {
                    i = { ["<C-j>"] = actions.move_selection_next, ["<C-k>"] = actions.move_selection_previous },
                },
            },
            pickers = {
                find_files = { mappings = { i = { ["<CR>"] = actions.select_tab_drop }, n = { ["<CR>"] = actions.select_tab_drop } }, hidden = true, find_command = { "rg", "--files", "--hidden", "--glob", "!.git/**" } },
                live_grep = { mappings = { i = { ["<CR>"] = actions.select_tab_drop }, n = { ["<CR>"] = actions.select_tab_drop } }, additional_args = { "--hidden", "--glob", "!.git/**" } },
                buffers = { sort_mru = true, mappings = { i = { ["<CR>"] = actions.select_tab_drop }, n = { ["<CR>"] = actions.select_tab_drop } } },
                oldfiles = { mappings = { i = { ["<CR>"] = actions.select_tab_drop }, n = { ["<CR>"] = actions.select_tab_drop } } },
            },
        })
        pcall(require("telescope").load_extension, "fzf")
        vim.api.nvim_create_user_command("CodeInspector", function() require("config.inspector").show(false) end, {})
        vim.api.nvim_create_user_command("CodeInspectorGrouped", function() require("config.inspector").show(true) end, {})
    end,
}
