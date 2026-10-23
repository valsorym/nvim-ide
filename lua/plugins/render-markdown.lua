-- ~/.config/nvim/lua/plugins/render-markdown.lua
-- Render Markdown directly inside Neovim without browser.

return {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },

    opts = {
        max_file_size = 1,
        enabled = false,             -- start in raw mode by default
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
            checked = "",
            unchecked = "",
            in_progress = "",
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

        local function highlights()
            local mocha = vim.g.colors_name == "catppuccin-mocha"
            local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
            local title = vim.api.nvim_get_hl(0, { name = "Title", link = false })
            vim.api.nvim_set_hl(0, "RenderMarkdownCode", { fg = mocha and "#a6adc8" or comment.fg })
            vim.api.nvim_set_hl(0, "RenderMarkdownHeading", { fg = mocha and "#89b4fa" or title.fg, bold = true })
        end
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("MarkdownHighlights", { clear = true }), callback = highlights,
        })
        highlights()
    end
}
