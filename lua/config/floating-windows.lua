-- ~/.config/nvim/lua/config/floating-windows.lua
-- Unified floating window configuration for consistent UI.

local M = {}

-- Define unified border style with proper borders
M.border_style = {
    { "╭", "FloatBorder" },
    { "─", "FloatBorder" },
    { "╮", "FloatBorder" },
    { "│", "FloatBorder" },
    { "╯", "FloatBorder" },
    { "─", "FloatBorder" },
    { "╰", "FloatBorder" },
    { "│", "FloatBorder" },
}

-- Unified floating window configuration
M.config = {
    -- Border style - consistent across all floating windows
    border = "rounded",

    -- Window transparency
    winblend = 0,

    -- Focus behavior
    focusable = false,

    -- Auto-close events
    close_events = {
        "CursorMoved",
        "CursorMovedI",
        "BufLeave",
        "BufHidden",
        "InsertEnter",
        "InsertLeave",
        "FocusLost",
        "WinScrolled"
    },

    -- Positioning
    relative = "cursor",
    anchor = "NE",

    -- Styling
    style = "minimal",
    noautocmd = true,
}

-- LSP-specific floating window configuration
M.lsp_config = vim.tbl_deep_extend("force", M.config, {
    source = "always",
    prefix = " ",
    header = "",
    format = function(diagnostic)
        return string.format("%s: %s", diagnostic.source, diagnostic.message)
    end,
})

-- Telescope floating window configuration
M.telescope_config = {
    borderchars = {
        prompt  = { "─", "│", " ", "│", "╭", "╮", "│", "│" },
        results = { "─", "│", "─", "│", "├", "┤", "╯", "╰" },
        preview = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
    },
    layout_config = {
        width = 0.8,
        height = 0.8,
        preview_cutoff = 120,
    },
}

-- Which-key floating window configuration
M.which_key_config = {
    window = {
        border = "rounded",
        position = "bottom",
        margin = { 1, 0, 1, 0 },
        padding = { 1, 2, 1, 2 },
        winblend = 0,
    },
}

-- Apply unified configuration to all floating windows
function M.setup()
    -- Set up highlight groups for consistent theming
    vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
            -- Get the exact background color of Normal text
            local normal_bg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Normal")), "bg")
            local normal_fg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Normal")), "fg")

            -- If background is empty, get it from terminal/gui background
            if normal_bg == "" or normal_bg == "NONE" then
                normal_bg = vim.o.background == "dark" and "#1e1e2e" or "#eff1f5"
            end

            -- Floating window background EXACTLY matches editor background
            vim.api.nvim_set_hl(0, "NormalFloat", {
                bg = normal_bg,  -- Force exact same background
                fg = normal_fg,  -- Same text color
            })

            -- Border color (visible but harmonious)
            vim.api.nvim_set_hl(0, "FloatBorder", {
                fg = normal_fg,  -- Border uses text color
                bg = normal_bg,  -- Border background same as editor
            })

            -- Popup menu (autocompletion) also matches
            vim.api.nvim_set_hl(0, "Pmenu", {
                bg = normal_bg,
                fg = normal_fg,
            })

            vim.api.nvim_set_hl(0, "PmenuSel", {
                bg = vim.o.background == "dark" and "#414559" or "#d0d1d4",
                fg = normal_fg,
            })
        end,
    })

    -- Set up LSP floating windows
    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
        vim.lsp.handlers.hover, M.lsp_config
    )

    vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
        vim.lsp.handlers.signature_help, M.lsp_config
    )

    -- Configure diagnostic floating windows
    vim.diagnostic.config({
        float = M.lsp_config,
        virtual_text = false,
        signs = true,
        underline = false,
        update_in_insert = false,
        severity_sort = true,
    })

    -- Trigger highlight setup for current colorscheme
    vim.cmd("doautocmd ColorScheme")
end

-- Utility function to create a consistent floating window
function M.create_float_window(config)
    local default_config = vim.tbl_deep_extend("force", M.config, config or {})

    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, default_config)

    -- Set window-local options for consistency
    vim.api.nvim_win_set_option(win, "winblend", 0)  -- No transparency
    vim.api.nvim_win_set_option(win, "wrap", false)
    vim.api.nvim_win_set_option(win, "cursorline", true)

    -- Force the window to use NormalFloat highlight
    vim.api.nvim_win_set_option(win, "winhighlight", "Normal:NormalFloat,FloatBorder:FloatBorder")

    return buf, win
end

return M