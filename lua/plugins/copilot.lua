-- ~/.config/nvim/lua/plugins/copilot.lua
-- Optional GitHub Copilot with toggle functionality and status indicator.

return {
    -- {
    --     "CopilotC-Nvim/CopilotChat.nvim",
    --     branch = "main",
    --     dependencies = {
    --         { "github/copilot.vim" },
    --         { "nvim-lua/plenary.nvim" },
    --     },
    --     config = function()
    --         require("CopilotChat").setup({
    --             debug = false, -- enable debugging
    --             window = {
    --                 layout = "float",
    --                 width = 0.8,
    --                 height = 0.8,
    --                 relative = "editor",
    --                 border = {
    --                     { "╭", "FloatBorder" },
    --                     { "─", "FloatBorder" },
    --                     { "╮", "FloatBorder" },
    --                     { "│", "FloatBorder" },
    --                     { "╯", "FloatBorder" },
    --                     { "─", "FloatBorder" },
    --                     { "╰", "FloatBorder" },
    --                     { "│", "FloatBorder" },
    --                 },
    --                 title = "─ 🤖✨ Copilot Chat ",
    --                 -- Alternative title with title_pos = "center":
    --                 -- title = string.rep("─", math.max(0, math.floor((vim.o.columns * 0.8 - 14) / 2) - 0)) .. " Copilot Chat " .. string.rep("─", math.max(0, math.floor((vim.o.columns * 0.8 - 14) / 2) - 0)),
    --             },
    --             mappings = {
    --                 close = {
    --                     normal = 'q',
    --                     insert = '<C-c>'
    --                 },
    --             },
    --         })

    --         vim.api.nvim_create_autocmd("FileType", {
    --             pattern = "copilot-chat",
    --             callback = function()
    --                 -- Override q for normal mode to close window.
    --                 vim.keymap.set("n", "q", function()
    --                     vim.cmd("close")
    --                     vim.schedule(function()
    --                         vim.cmd("wincmd =")
    --                         vim.cmd("redraw!")
    --                     end)
    --                 end, { buffer = true })

    --                 -- Override Esc for normal mode to close window.
    --                 -- [!] We use Esc in chat to change input mode.
    --                 -- vim.keymap.set("n", "<Esc>", function()
    --                 --     vim.cmd("close")
    --                 --     vim.schedule(function()
    --                 --         vim.cmd("wincmd =")
    --                 --         vim.cmd("redraw!")
    --                 --     end)
    --                 -- end, { buffer = true })
    --             end,
    --         })
    --     end,
    -- },
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
        --     { "<leader>co", "<cmd>CopilotToggle<CR>", desc = "Toggle Copilot" },
        --     { "<leader>cs", "<cmd>CopilotStatus<CR>", desc = "Copilot Status" },
        --     { "<leader>ca", "<cmd>CopilotAuth<CR>", desc = "Copilot Auth" },
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