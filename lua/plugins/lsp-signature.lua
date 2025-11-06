-- ~/.config/nvim/lua/config/lsp-signature.lua
-- Show function signatures while typing.

return {
    "ray-x/lsp_signature.nvim",
    event = "VeryLazy",
    opts = {
        bind = true,
        handler_opts = {
            border = "rounded"
        },
        hint_enable = false,  -- sisable virtual text hints
        floating_window = true,
        floating_window_above_cur_line = true,

        -- Manual trigger with Ctrl+K.
        toggle_key = "<C-k>",

        -- Auto trigger when typing function arguments.
        auto_close_after = 10,  -- close after 10 seconds

        -- Don't auto-show on typing.
        always_trigger = false,

        -- Show signature on hover.
        hint_prefix = "🗊 ",

        -- Keybindings.
        extra_trigger_chars = {"(", ","},
    },
    config = function(_, opts)
        require("lsp_signature").setup(opts)
    end,
}