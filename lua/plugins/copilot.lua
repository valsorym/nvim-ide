-- ~/.config/nvim/lua/plugins/copilot.lua
-- Optional GitHub Copilot with toggle functionality and status indicator.

return {
    {
        "github/copilot.vim",
        lazy = true,  -- don't load by default
        cmd = {
            "Copilot",
            "CopilotEnable",
            "CopilotDisable",
            "CopilotToggle",
            "CopilotStatus",
            "CopilotSetup",
            "CopilotAuth",
            "CopilotSignOut",
        },
        -- keys = {
        --     { "<leader>coo", "<cmd>CopilotToggle<CR>", desc = "Toggle Copilot" },
        --     { "<leader>cos", "<cmd>CopilotStatus<CR>", desc = "Copilot Status" },
        --     { "<leader>coa", "<cmd>CopilotAuth<CR>", desc = "Copilot Auth" },
        -- },
        init = function()
            -- Disable Copilot by default.
            vim.g.copilot_enabled = 0

            -- Don't show annoying messages when not configured.
            vim.g.copilot_no_tab_map = true
            vim.g.copilot_assume_mapped = true

            -- Custom keymaps when Copilot is active.
            vim.g.copilot_tab_fallback = ""
        end,
        config = function()
            -- Custom toggle command.
            vim.api.nvim_create_user_command("CopilotToggle", function()
                if vim.g.copilot_enabled == 1 then
                    vim.g.copilot_enabled = 0
                    vim.cmd("Copilot disable")
                    vim.notify("🤖 Copilot disabled", vim.log.levels.INFO)
                else
                    vim.g.copilot_enabled = 1
                    vim.cmd("Copilot enable")
                    vim.notify("🤖 Copilot enabled", vim.log.levels.INFO)
                end

                -- Refresh status line.
                vim.cmd("redrawstatus")
            end, { desc = "Toggle GitHub Copilot" })

            -- Setup command for first-time configuration.
            vim.api.nvim_create_user_command("CopilotSetup", function()
                vim.notify("🔧 Setting up Copilot...", vim.log.levels.INFO)
                vim.cmd("Copilot setup")
            end, { desc = "Setup GitHub Copilot" })

            -- Custom keybindings when Copilot is enabled.
            vim.keymap.set("i", "<C-J>", function()
                if vim.g.copilot_enabled == 1 then
                    return vim.fn["copilot#Accept"]("")
                else
                    return "<C-J>"
                end
            end, { expr = true, replace_keycodes = false, desc = "Accept Copilot suggestion" })

            vim.keymap.set("i", "<C-H>", function()
                if vim.g.copilot_enabled == 1 then
                    return vim.fn["copilot#Dismiss"]()
                else
                    return "<C-H>"
                end
            end, { expr = true, replace_keycodes = false, desc = "Dismiss Copilot suggestion" })

            -- Alternative suggestions.
            vim.keymap.set("i", "<C-N>", function()
                if vim.g.copilot_enabled == 1 then
                    return vim.fn["copilot#Next"]()
                else
                    return "<C-N>"
                end
            end, { expr = true, replace_keycodes = false, desc = "Next Copilot suggestion" })

            vim.keymap.set("i", "<C-P>", function()
                if vim.g.copilot_enabled == 1 then
                    return vim.fn["copilot#Previous"]()
                else
                    return "<C-P>"
                end
            end, { expr = true, replace_keycodes = false, desc = "Previous Copilot suggestion" })
        end,
    }
}