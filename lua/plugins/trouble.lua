-- ~/.config/nvim/lua/plugins/trouble.lua
-- Enhanced diagnostics and error display with Trouble.nvim

return {
    "folke/trouble.nvim",
    dependencies = {"nvim-tree/nvim-web-devicons"},
    cmd = "Trouble",
    keys = {
        {"<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)"},
        {"<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)"},
        {"<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)"},
        {"<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)"},
        {"<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)"},
        {"<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP Definitions / references / ... (Trouble)"},
        {"<leader>xL", "<cmd>Trouble lsp_document_symbols toggle win.position=right<cr>", desc = "Document Symbols (Trouble)"},
        {"<leader>xr", "<cmd>Trouble lsp_references toggle<cr>", desc = "LSP References (Trouble)"},
    },
    opts = {
        position = "bottom", -- position of the list can be: bottom, top, left, right
        height = 10, -- height of the trouble list when position is top or bottom
        width = 50, -- width of the list when position is left or right
        icons = true, -- use devicons for filenames
        mode = "workspace_diagnostics", -- "workspace_diagnostics", "document_diagnostics", "quickfix", "lsp_references", "loclist"
        severity = nil, -- nil (ALL) or vim.diagnostic.severity.ERROR | WARN | INFO | HINT
        fold_open = "", -- icon used for open folds
        fold_closed = "", -- icon used for closed folds
        group = true, -- group results by file
        padding = true, -- add an extra new line on top of the list
        cycle_results = true, -- cycle item list when reaching beginning or end of list
        action_keys = { -- key mappings for actions in the trouble list
            close = "q", -- close the list
            cancel = "<esc>", -- cancel the preview and get back to your last window / buffer / cursor
            refresh = "r", -- manually refresh
            jump = {"<cr>", "<tab>", "<2-leftmouse>"}, -- jump to the diagnostic or open / close folds
            open_split = {"<c-x>"}, -- open buffer in new split
            open_vsplit = {"<c-v>"}, -- open buffer in new vsplit
            open_tab = {"<c-t>"}, -- open buffer in new tab
            jump_close = {"o"}, -- jump to the diagnostic and close the list
            toggle_mode = "m", -- toggle between "workspace" and "document" diagnostics mode
            switch_severity = "s", -- switch "diagnostics" severity filter level to HINT / INFO / WARN / ERROR
            toggle_preview = "P", -- toggle auto_preview
            hover = "K", -- opens a small popup with the full multiline message
            preview = "p", -- preview the diagnostic location
            open_code_href = "c", -- if present, open a URI with more information about the diagnostic error
            close_folds = {"zM", "zm"}, -- close all folds
            open_folds = {"zR", "zr"}, -- open all folds
            toggle_fold = {"zA", "za"}, -- toggle fold of current file
            previous = "k", -- previous item
            next = "j", -- next item
            help = "?" -- help menu
        },
        multiline = true, -- render multi-line messages
        indent_lines = true, -- add an indent guide below the fold icons
        win_config = {border = "single"}, -- window configuration for floating windows. See |nvim_open_win()|.
        auto_open = false, -- automatically open the list when you have diagnostics
        auto_close = false, -- automatically close the list when you have no diagnostics
        auto_preview = true, -- automatically preview the location of the diagnostic. <esc> to close preview and go back to last window
        auto_fold = false, -- automatically fold a file trouble list at creation
        auto_jump = {"lsp_definitions"}, -- for the given modes, automatically jump if there is only a single result
        include_declaration = {
            "lsp_references",
            "lsp_implementations",
            "lsp_definitions"
        }, -- for the given modes, include the declaration of the current symbol in the results
        signs = {
            -- icons / text used for a diagnostic
            error = "",
            warning = "",
            hint = "",
            information = "",
            other = "",
        },
        use_diagnostic_signs = false -- enabling this will use the signs defined in your lsp client
    },
    config = function(_, opts)
        require("trouble").setup(opts)

        -- Auto-open trouble when there are diagnostics
        vim.api.nvim_create_autocmd("DiagnosticChanged", {
            callback = function()
                local trouble = require("trouble")
                local diagnostics = vim.diagnostic.get(0)

                -- Only auto-open if there are errors
                local has_errors = false
                for _, diag in ipairs(diagnostics) do
                    if diag.severity == vim.diagnostic.severity.ERROR then
                        has_errors = true
                        break
                    end
                end

                -- Don't auto-open, just provide easy access
                -- if has_errors and not trouble.is_open() then
                --     trouble.open("workspace_diagnostics")
                -- end
            end,
        })

        -- Integration with LSP handlers to use Trouble for references
        local function trouble_references()
            require("trouble").open("lsp_references")
        end

        -- Override default LSP reference handler
        vim.lsp.handlers["textDocument/references"] = function(_, result, ctx, config)
            if not result or vim.tbl_isempty(result) then
                vim.notify("No references found", vim.log.levels.INFO)
                return
            end

            -- Store results in quickfix list and open trouble
            vim.fn.setqflist({}, " ", {
                title = "LSP References",
                items = vim.lsp.util.locations_to_items(result, vim.lsp.get_client_by_id(ctx.client_id).offset_encoding)
            })
            require("trouble").open("quickfix")
        end

        -- Custom command for quick diagnostic summary
        vim.api.nvim_create_user_command("DiagnosticSummary", function()
            local diagnostics = vim.diagnostic.get()
            local counts = {
                error = 0,
                warn = 0,
                info = 0,
                hint = 0
            }

            for _, diag in ipairs(diagnostics) do
                if diag.severity == vim.diagnostic.severity.ERROR then
                    counts.error = counts.error + 1
                elseif diag.severity == vim.diagnostic.severity.WARN then
                    counts.warn = counts.warn + 1
                elseif diag.severity == vim.diagnostic.severity.INFO then
                    counts.info = counts.info + 1
                elseif diag.severity == vim.diagnostic.severity.HINT then
                    counts.hint = counts.hint + 1
                end
            end

            print(string.format("Diagnostics: %d errors, %d warnings, %d info, %d hints",
                counts.error, counts.warn, counts.info, counts.hint))

            if counts.error > 0 or counts.warn > 0 then
                require("trouble").open("workspace_diagnostics")
            end
        end, {desc = "Show diagnostic summary and open Trouble if needed"})

        -- Command to toggle between workspace and document diagnostics
        vim.api.nvim_create_user_command("TroubleToggleMode", function()
            local trouble = require("trouble")
            if trouble.is_open() then
                trouble.close()
            end
            -- Toggle between modes
            local current_mode = trouble.get_mode()
            if current_mode == "workspace_diagnostics" then
                trouble.open("document_diagnostics")
            else
                trouble.open("workspace_diagnostics")
            end
        end, {desc = "Toggle between workspace and document diagnostics in Trouble"})
    end,
}