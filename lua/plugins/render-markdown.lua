-- ~/.config/nvim/lua/plugins/render-markdown.lua
-- Render Markdown directly inside Neovim without browser.

return {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = "VeryLazy",

    opts = {
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

        -- Unified toggle rendering for Markdown/RST.
        vim.keymap.set("n", "<Leader>dr", function()
            local ft = vim.bo.filetype
            if ft == "markdown" then
                render.toggle()
            elseif ft == "rst" or ft == "restructuredtext" then
                -- Call RST toggle if available.
                if _G.rst_render_toggle then
                    _G.rst_render_toggle()
                else
                    vim.notify("RST renderer not loaded", vim.log.levels.WARN)
                end
            else
                vim.notify("No renderer available for ." .. ft, vim.log.levels.WARN)
            end
        end, { desc = "Toggle Rendering (Markdown/RST)" })

        -- Optional highlight tuning.
        vim.api.nvim_set_hl(0, "RenderMarkdownCode", { fg = "#a6adc8" })
        vim.api.nvim_set_hl(0, "RenderMarkdownHeading", {
            fg = "#89b4fa", bold = true
        })
    end
}