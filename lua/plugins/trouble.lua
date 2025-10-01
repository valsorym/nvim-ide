-- ~/.config/nvim/lua/plugins/trouble.lua
-- Lean Trouble setup: sane defaults, safe toggles, no LSP overrides.

return {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",

    -- Keymaps focus on fast toggles without changing global handlers.
    keys = {
        {
            "<leader>cC",
            "<cmd>Trouble diagnostics toggle<cr>",
            desc = "Diagnostics (WS)"
        },
        {
            "<leader>cc",
            "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
            desc = "Diagnostics (Buf)"
        },
        {
            "<leader>cl",
            "<cmd>Trouble loclist toggle<cr>",
            desc = "Location List"
        },
        {
            "<leader>cq",
            "<cmd>Trouble qflist toggle<cr>",
            desc = "Quickfix List"
        },
        {
            "<leader>cs",
            "<cmd>Trouble symbols toggle focus=false<cr>",
            desc = "Symbols"
        },
        {
            "<leader>cw",
            "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
            desc = "LSP (defs/refs/…)"
        },
        {
            "<leader>cL",
            "<cmd>Trouble lsp_document_symbols toggle win.position=right<cr>",
            desc = "Document Symbols"
        },
        {
            "<leader>cr",
            "<cmd>Trouble lsp_references toggle<cr>",
            desc = "LSP References"
        },
        {
            "<leader>cT",
            "<cmd>TroubleToggleMode<cr>",
            desc = "Toggle WS/Buf"
        },
        {
            "<leader>cS",
            "<cmd>DiagnosticSummary<cr>",
            desc = "Diag summary"
        },
    },

    -- Keep UI minimal; compute height at runtime in config().
    opts = {
        position = "bottom",
        height = 12,
        width = 50,
        mode = "workspace_diagnostics",
        severity = nil, -- nil = all
        group = true,
        padding = true,
        cycle_results = true,
        multiline = true,
        indent_lines = true,
        win = { border = "single" },
        auto_open = false,
        auto_close = false,
        auto_preview = true,
        auto_fold = false,
        auto_jump = { "lsp_definitions" },
        include_declaration = {
            "lsp_references",
            "lsp_implementations",
            "lsp_definitions"
        },
        -- Ultra-minimal icon set to avoid visual noise.
        icons = {
            indent = {
                top = "│ ",
                middle = "├╴",
                last = "└╴",
                fold_open = " ",
                fold_closed = " ",
                ws = "  ",
            },
            folder_closed = " ",
            folder_open = " ",
            kinds = {
                Array = " ",
                Boolean = " ",
                Class = " ",
                Constant = " ",
                Constructor = " ",
                Enum = " ",
                EnumMember = " ",
                Event = " ",
                Field = " ",
                File = " ",
                Function = " ",
                Interface = " ",
                Key = " ",
                Method = " ",
                Module = " ",
                Namespace = " ",
                Null = " ",
                Number = " ",
                Object = " ",
                Operator = " ",
                Package = " ",
                Property = " ",
                String = " ",
                Struct = " ",
                TypeParameter = " ",
                Variable = " ",
            },
        },
        signs = {
            error = "",
            warning = "",
            hint = "",
            information = "",
            other = "",
        },
        use_diagnostic_signs = false,
        -- Action keys kept close to defaults, with quick jump behavior.
        action_keys = {
            close = "q",
            cancel = "<esc>",
            refresh = "r",
            jump = { "<cr>", "<tab>", "<2-leftmouse>" },
            open_split = { "<c-x>" },
            open_vsplit = { "<c-v>" },
            open_tab = { "<c-t>" },
            jump_close = { "o" },
            toggle_mode = "m",
            switch_severity = "s",
            toggle_preview = "P",
            hover = "K",
            preview = "p",
            open_code_href = "c",
            close_folds = { "zM", "zm" },
            open_folds = { "zR", "zr" },
            toggle_fold = { "zA", "za" },
            previous = "k",
            next = "j",
            help = "?",
        },
    },

    config = function(_, opts)
        local trouble = require("trouble")

        -- Fit height to editor size (bounded 8..16 lines).
        local function calc_height()
            local h = math.floor(vim.o.lines * 0.30)
            h = math.max(8, math.min(h, 16))
            return h
        end
        opts.height = calc_height()
        trouble.setup(opts)

        -- Reopen in same mode on :VimResized to apply new height.
        vim.api.nvim_create_autocmd("VimResized", {
            callback = function()
                if not trouble.is_open() then return end
                local mode = trouble.get_mode()
                trouble.close()
                -- reapply height on reopen
                require("trouble").setup(
                    vim.tbl_extend("force", opts, { height = calc_height() })
                )
                trouble.open(mode)
            end,
        })

        -- Simple toggle commands (no global LSP handler overrides).
        local function toggle_doc()
            if trouble.is_open()
                and trouble.get_mode() == "document_diagnostics" then
                trouble.close()
            else
                trouble.open("document_diagnostics")
            end
        end

        local function toggle_ws()
            if trouble.is_open()
                and trouble.get_mode() == "workspace_diagnostics" then
                trouble.close()
            else
                trouble.open("workspace_diagnostics")
            end
        end

        vim.api.nvim_create_user_command(
            "TroubleToggleDoc",
            toggle_doc,
            { desc = "Toggle document diagnostics" }
        )
        vim.api.nvim_create_user_command(
            "TroubleToggleWs",
            toggle_ws,
            { desc = "Toggle workspace diagnostics" }
        )

        -- Quick summary + open best view.
        vim.api.nvim_create_user_command(
            "DiagnosticSummary",
            function()
                local diags = vim.diagnostic.get()
                local c = { err = 0, warn = 0, info = 0, hint = 0 }
                for _, d in ipairs(diags) do
                    if d.severity == vim.diagnostic.severity.ERROR then
                        c.err = c.err + 1
                    elseif d.severity == vim.diagnostic.severity.WARN then
                        c.warn = c.warn + 1
                    elseif d.severity == vim.diagnostic.severity.INFO then
                        c.info = c.info + 1
                    elseif d.severity == vim.diagnostic.severity.HINT then
                        c.hint = c.hint + 1
                    end
                end
                print(
                    string.format(
                        "Diagnostics: %dE %dW %dI %dH",
                        c.err, c.warn, c.info, c.hint
                    )
                )
                if c.err > 0 or c.warn > 0 then
                    trouble.open("workspace_diagnostics")
                end
            end,
            { desc = "Show diag summary and open Trouble if needed" }
        )

        -- Toggle between WS/Buf with a single command.
        vim.api.nvim_create_user_command(
            "TroubleToggleMode",
            function()
                if not trouble.is_open() then
                    trouble.open("workspace_diagnostics")
                    return
                end
                local mode = trouble.get_mode()
                if mode == "workspace_diagnostics" then
                    trouble.open("document_diagnostics")
                else
                    trouble.open("workspace_diagnostics")
                end
            end,
            { desc = "Toggle WS/Buf diagnostics" }
        )

        -- Optional: lightweight auto-open hint, without forcing the UI.
        vim.api.nvim_create_autocmd("DiagnosticChanged", {
            callback = function() end,
        })
    end,
}
