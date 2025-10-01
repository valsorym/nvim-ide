-- ~/.config/nvim/lua/plugins/ufo.lua
-- Code folding with nvim-ufo and proper column width.

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
        fold_virt_text_handler = function(virtText, lnum, endLnum, width,
                                          truncate)
            local newVirtText = {}
            local foldedLines = endLnum - lnum

            -- More informative suffix with line count
            local suffix = (" 󰁂 %d lines "):format(foldedLines)
            local sufWidth = vim.fn.strdisplaywidth(suffix)
            local targetWidth = width - sufWidth
            local curWidth = 0

            for _, chunk in ipairs(virtText) do
                local chunkText = chunk[1]
                local hlGroup = chunk[2]
                local chunkWidth = vim.fn.strdisplaywidth(chunkText)

                if curWidth + chunkWidth < targetWidth then
                    table.insert(newVirtText, {chunkText, hlGroup})
                    curWidth = curWidth + chunkWidth
                else
                    -- Add ellipsis for better visual truncation
                    chunkText = truncate(chunkText,
                        targetWidth - curWidth - 1)
                    if chunkText ~= "" then
                        table.insert(newVirtText,
                            {chunkText .. "…", hlGroup})
                    end
                    break
                end
            end

            -- Custom highlight group for suffix
            table.insert(newVirtText, {suffix, "FoldSuffix"})
            return newVirtText
        end
    },
    config = function(_, opts)
        -- Fold settings
        vim.opt.foldcolumn = '1'
        vim.opt.foldlevel = 99
        vim.opt.foldlevelstart = 99
        vim.opt.foldenable = true
        vim.opt.foldmethod = "expr"

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

        -- Highlight customization for better visual appearance
        vim.api.nvim_set_hl(0, "Folded", {
            fg = "#a9b1d6",
            bg = "NONE",
            italic = true
        })
        vim.api.nvim_set_hl(0, "FoldColumn", {
            fg = "#5e5e5e",
            bg = "NONE"
        })
        vim.api.nvim_set_hl(0, "FoldSuffix", {
            fg = "#9ece6a",
            bg = "NONE",
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
                        vim.wo.foldcolumn = "auto:9"
                    end
                end
            }
        )
    end
}