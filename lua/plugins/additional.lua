-- Integrations with real work to do; built-in commenting, snippets and terminals need no plugins.
return {
    { "b0o/schemastore.nvim", lazy = true },
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            max_file_length = 20000, update_debounce = 200,
            signs = { add = { text = "│" }, change = { text = "│" }, delete = { text = "_" },
                topdelete = { text = "‾" }, changedelete = { text = "~" }, untracked = { text = "┆" } },
            current_line_blame = false,
            on_attach = function(buf) return not require("config.performance").is_large(buf) end,
        },
    },
    {
        "lukas-reineke/indent-blankline.nvim",
        event = { "BufReadPost", "BufNewFile" },
        main = "ibl",
        config = function()
            local hooks = require("ibl.hooks")
            hooks.register(hooks.type.ACTIVE, function(buf) return not require("config.performance").is_large(buf) end)
            require("ibl").setup({
                indent = { char = "▏" },
                scope = { enabled = false }, -- Avoid a second parser walk on every cursor move.
                exclude = { filetypes = { "help", "dashboard", "NvimTree", "TelescopePrompt", "lazy", "mason" },
                    buftypes = { "terminal", "nofile", "quickfix", "prompt" } },
            })
        end,
    },
    { "folke/flash.nvim", opts = { modes = { search = { enabled = false }, char = { enabled = false } } } },
}
