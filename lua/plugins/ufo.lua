-- ~/.config/nvim/lua/plugins/ufo.lua
-- Code folding with nvim-ufo and proper column width.

local foldColumn = "0" -- "auto:9"

return {
    "kevinhwang91/nvim-ufo",
    dependencies = {
        "kevinhwang91/promise-async",
        "neovim/nvim-lspconfig"
    },
    event = "VeryLazy",
    opts = {
        provider_selector = function(bufnr, filetype, buftype)
            if filetype == "dashboard"
            or filetype == "NvimTree"
            or filetype == "neo-tree"
            or buftype ~= "" then
                return "" -- disable ufo
            end
            return {"treesitter", "indent"}
        end,
        open_fold_hl_timeout = 150,
        close_fold_kinds_for_ft = {
            default = {"imports", "comment"}
        },
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
        vim.opt.foldmethod = "indent" -- or "expr"

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

        -- Keymaps for folding.
        vim.keymap.set("n", "zR", require("ufo").openAllFolds,
            {desc = "Open all folds"})
        vim.keymap.set("n", "zM", require("ufo").closeAllFolds,
            {desc = "Close all folds"})
        vim.keymap.set("n", "zr", require("ufo").openFoldsExceptKinds,
            {desc = "Open folds except kinds"})
        vim.keymap.set("n", "zm", require("ufo").closeFoldsWith,
            {desc = "Close folds with"})
        vim.keymap.set("n", "zp", function()
            local winid = require("ufo").peekFoldedLinesUnderCursor()
            if not winid then
                vim.lsp.buf.hover()
            end
        end, {desc = "Peek fold or hover"})

        -- Highlight customization for better visual appearance.
        -- Folded text.
        vim.api.nvim_set_hl(0, "Folded", {
            fg = "#a9b1d6", -- "#6c7086",
            sp = "#45475a",
            bg = "NONE",
            italic = true,
            underline = true
        })

        -- Prefix.
        vim.api.nvim_set_hl(0, "FoldedPrefix", {
            fg = "#a6e3a1", -- "#89b4fa",
            bg = "#1e1e2e",
            bold = true
        })

        -- Suffix.
        vim.api.nvim_set_hl(0, "FoldedSuffix", {
            fg = "#a6e3a1",
            bg = "#1e1e2e",
            bold = true
        })

        -- Hide fold column on special buffers (like Dashboard).
        local fold_exclude_group = vim.api.nvim_create_augroup(
            "FoldColumnExclude",
            {clear = true}
        )

        vim.api.nvim_create_autocmd(
            {"BufEnter", "BufWinEnter", "FileType"},
            {
                group = fold_exclude_group,
                callback = function()
                    local buftype = vim.bo.buftype
                    local filetype = vim.bo.filetype

                    -- Exclude special buffers
                    if buftype ~= "" or
                       filetype == "dashboard" or
                       filetype == "NvimTree" or
                       filetype == "neo-tree" or
                       filetype == "help" then
                        vim.wo.foldcolumn = "0"
                    else
                        vim.wo.foldcolumn = foldColumn
                    end
                end
            }
        )
    end
}