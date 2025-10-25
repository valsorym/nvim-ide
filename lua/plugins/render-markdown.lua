-- ~/.config/nvim/lua/plugins/render-markdown.lua
-- Render Markdown directly inside Neovim without browser.

return {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = "VeryLazy",

    opts = {
        enabled = true,              -- start rendered by default
        render_modes = { "n", "v" }, -- show in normal & visual mode
        heading = {
            icons = { "󰎥  ", "󰎨  ", "󰎫  ", "󰎲  ", "󰎯  ", "󰎴  " },
            sign = false,
            position = "inline"
        },
        code = {
            enabled = true,
            style = "minimal",        -- or "full"
            width = "block",          -- "window" or "block"
        },
        bullet = {
            icons = { "•", "◦", "▪" },
        },
        quote = {
            icon = "┃",               -- quote bar
            repeat_linebreak = false,
        },
        checkbox = {
            checked = "",
            unchecked = "",
            in_progress = "",
        },
        emphasis = {
            italic = { enabled = true, hl = "Italic" },
            bold = { enabled = true, hl = "Bold" },
            strikethrough = { enabled = true, hl = "Comment" },
        },
    },

    config = function(_, opts)
        local render = require("render-markdown")

        -- Initialize plugin.
        render.setup(opts)

        -- Toggle rendering.
        vim.keymap.set("n", "<Leader>dr", function()
            render.toggle()
        end, { desc = "Rendering (markdown)" })

        -- Refresh rendering on write.
        vim.api.nvim_create_autocmd("BufWritePost", {
            pattern = "*.md",
            callback = function() render.refresh() end,
        })

        -- Optional highlight tuning.
        vim.api.nvim_set_hl(0, "RenderMarkdownCode", { fg = "#a6adc8" })
        vim.api.nvim_set_hl(0, "RenderMarkdownHeading", {
            fg = "#89b4fa", bold = true
        })
    end
}
