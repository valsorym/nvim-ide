-- Diagnostics views load only when requested; use the current Trouble API.
return {
    "folke/trouble.nvim", cmd = "Trouble",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { auto_open = false, auto_close = false, focus = true,
        win = { position = "bottom", size = 0.3, border = "rounded" },
        preview = { type = "float", relative = "editor", border = "rounded" },
    },
}
