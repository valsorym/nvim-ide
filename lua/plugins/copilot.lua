-- Optional completion; enabled only by an explicit command.
return {
    "github/copilot.vim", cmd = { "Copilot", "CopilotToggle" },
    init = function()
        vim.g.copilot_enabled = 0
        vim.g.copilot_no_tab_map = true
        vim.g.copilot_no_maps = true
    end,
    config = function()
        vim.api.nvim_create_user_command("CopilotToggle", function()
            local enabled = vim.g.copilot_enabled == 1
            vim.g.copilot_enabled = enabled and 0 or 1
            vim.cmd(enabled and "Copilot disable" or "Copilot enable")
        end, {})
        -- Do not steal Tab, newline, backspace or the completion menu's Ctrl-N/P.
        vim.keymap.set("i", "<C-g><C-y>", function() return vim.fn["copilot#Accept"]("") end,
            { expr = true, replace_keycodes = false, desc = "Accept Copilot suggestion" })
        for key, fn in pairs({ ["<C-n>"] = "Next", ["<C-p>"] = "Previous", ["<C-e>"] = "Dismiss" }) do
            vim.keymap.set("i", "<C-g>" .. key, function() vim.fn["copilot#" .. fn]() end,
                { desc = "Copilot " .. fn })
        end
    end,
}
