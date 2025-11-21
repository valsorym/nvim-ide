-- ~/.config/nvim/lua/config/lsp-ui.lua
-- Global floating borders + padding + markdown cleanup

local M = {}

-- Colors
local border_fg = "#89b4fa"
local border_bg = "#181826"

vim.api.nvim_set_hl(0, "LspSignatureActiveParameter", {
    underline = false, bold = false, fg = "NONE", bg = "NONE"
})
vim.api.nvim_set_hl(0, "LspBorder", { fg = border_fg, bg = border_bg })
vim.api.nvim_set_hl(0, "LspFloat", { bg = border_bg })
vim.api.nvim_set_hl(0, "LspActiveParam", {
    fg = "#ffffff",
    bg = "#45475a",
    bold = true,
})

-- Cleanup markdown from pyright output
local function cleanup_markdown(lines)
    local out = {}
    for _, line in ipairs(lines) do
        -- Remove ```python or ``` or empty lines
        if not line:match("^```") and line:match("%S") then
            -- Remove leading "python" hint
            if line ~= "python" then
                table.insert(out, line)
            end
        end
    end
    return out
end

-- Add horizontal padding
local function add_padding(lines)
    local padded = {}
    for _, l in ipairs(lines) do
        table.insert(padded, " " .. l .. " ")
    end
    return padded
end

-- Override floating preview - simplified version
local orig_floating_preview = vim.lsp.util.open_floating_preview

function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
    opts = opts or {}

    -- Clean markdown
    contents = cleanup_markdown(contents)

    -- Inner padding
    contents = add_padding(contents)

    -- Proper popup behavior - cleaner settings
    opts.border = opts.border or "rounded"
    opts.focusable = false
    opts.close_events = opts.close_events or {
        "CursorMoved", "CursorMovedI",
        "BufHidden", "InsertLeave",
        "WinScrolled", "FocusLost",
    }

    return orig_floating_preview(contents, syntax, opts, ...)
end

-- Close ALL floating windows on ESC - simplified for native LSP
local function close_all_floats()
    local closed_any = false
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local config = vim.api.nvim_win_get_config(win)

        -- Floating window detection
        if config.relative ~= "" then
            pcall(vim.api.nvim_win_close, win, true)
            closed_any = true
        end
    end
    return closed_any
end

-- Enhanced ESC behavior for native LSP floating windows
vim.keymap.set("n", "<Esc>", function()
    local closed_floats = close_all_floats()
    if not closed_floats then
        -- Only clear search if no floats were closed
        vim.cmd("nohlsearch")
    end
end, { expr = false, desc = "Close floats or clear search" })

-- Insert mode ESC - always close floats first, then exit insert mode
vim.keymap.set("i", "<Esc>", function()
    close_all_floats()
    return "<Esc>"
end, { expr = true, desc = "Close floats and exit insert" })

return M