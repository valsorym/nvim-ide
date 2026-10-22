-- ~/.config/nvim/lua/plugins/ufo.lua
-- Code folding with nvim-ufo and proper column width.

local foldColumn = "0" -- "auto:9"

return {
    "kevinhwang91/nvim-ufo",
    dependencies = {
        "kevinhwang91/promise-async",
    },
    event = { "BufReadPost", "BufNewFile" },
    opts = {
        provider_selector = function(bufnr, filetype, buftype)
            if require("config.performance").is_large(bufnr) or filetype == "dashboard"
            or filetype == "NvimTree"
            or filetype == "neo-tree"
            or buftype ~= "" then
                return "" -- disable ufo
            end
            return {"treesitter", "indent"}
        end,
        open_fold_hl_timeout = 150,
        preview = {
            win_config = {
                border = {"", "─", "", "", "", "─", "", ""},
                winhighlight = "Normal:Folded",
                winblend = 0
            },
            mappings = {
                scrollU = "<C-u>",
                scrollD = "<C-d>",
                jumpTop = "[",
                jumpBot = "]"
            }
        },
        fold_virt_text_handler = function(virtText, lnum, endLnum,
                                          width, truncate)
            local newVirtText = {}
            local foldedLines = endLnum - lnum
            local prefix = "" --"󰞷  "

            local suffix = (" 󰁂  %d lines"):format(foldedLines)
            local sufWidth = vim.fn.strdisplaywidth(suffix)
            local targetWidth = width - sufWidth -
                vim.fn.strdisplaywidth(prefix)
            local curWidth = 0

            -- Prefix.
            table.insert(newVirtText, {prefix, "FoldedPrefix"})

            for _, chunk in ipairs(virtText) do
                local chunkText = chunk[1]
                local chunkWidth = vim.fn.strdisplaywidth(chunkText)

                if curWidth + chunkWidth < targetWidth then
                    -- Use Folded group with background.
                    table.insert(newVirtText, {chunkText, "Folded"})
                    curWidth = curWidth + chunkWidth
                else
                    chunkText = truncate(chunkText, targetWidth - curWidth - 1)
                    if chunkText ~= "" then
                        table.insert(newVirtText,
                            {chunkText .. "…", "Folded"})
                    end
                    break
                end
            end

            -- Suffix with background.
            table.insert(newVirtText, {suffix, "FoldedSuffix"})

            -- Use background to fill the rest of the width.
            local fillWidth = width - curWidth -
                vim.fn.strdisplaywidth(prefix) - sufWidth
            if fillWidth > 0 then
                table.insert(newVirtText,
                    {string.rep(" ", fillWidth), "Folded"})
            end

            return newVirtText
        end
    },
    config = function(_, opts)
        -- Fold settings
        vim.opt.foldcolumn = '0'
        vim.opt.foldlevel = 99
        vim.opt.foldlevelstart = 99
        vim.opt.foldenable = true
        vim.opt.foldmethod = "manual"

        -- Custom fold icons: »/◈/◉ for closed, ⌄/◇/◌ for open.
        vim.opt.fillchars = {
            foldopen = "◌",
            foldclose = "◉",
            foldsep = "│",
            fold = " ",
            eob = " "
        }

        -- Setup nvim-ufo.
        require("ufo").setup(opts)

        local function highlights()
            local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
            local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
            local ok = vim.api.nvim_get_hl(0, { name = "DiagnosticOk", link = false })
            local mocha = vim.g.colors_name == "catppuccin-mocha"
            vim.api.nvim_set_hl(0, "Folded", { fg = mocha and "#a9b1d6" or normal.fg,
                sp = comment.fg, italic = true, underline = true })
            for _, name in ipairs({ "FoldedPrefix", "FoldedSuffix" }) do
                vim.api.nvim_set_hl(0, name, { fg = mocha and "#a6e3a1" or ok.fg, bg = normal.bg, bold = true })
            end
        end
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("FoldHighlights", { clear = true }), callback = highlights,
        })
        highlights()

    end,
}
