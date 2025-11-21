-- ~/.config/nvim/lua/ui/borders.lua
-- Global floating borders + padding + markdown cleanup.

local M = {}

-- Colors.
local border_fg = "#89b4fa"
local border_bg = "#181826"

vim.api.nvim_set_hl(0, "LspSignatureActiveParameter", { underline = false, bold = false, fg = "NONE", bg = "NONE" })
vim.api.nvim_set_hl(0, "LspBorder", { fg = border_fg, bg = border_bg })
vim.api.nvim_set_hl(0, "LspFloat", { bg = border_bg })
vim.api.nvim_set_hl(0, "LspActiveParam", {
    fg = "#ffffff",
    bg = "#45475a",
    bold = true,
})

-- Cleanup markdown from pyright output.
local function cleanup_markdown(lines)
    local out = {}
    for _, line in ipairs(lines) do
        -- remove ```python or ``` or empty lines
        if not line:match("^```") and line:match("%S") then
            -- remove leading "python" hint
            if line ~= "python" then
                table.insert(out, line)
            end
        end
    end
    return out
end

-- Add horizontal padding.
local function add_padding(lines)
    local padded = {}
    for _, l in ipairs(lines) do
        table.insert(padded, " " .. l .. " ")
    end
    return padded
end

-- Override floating preview.
local orig_floating_preview = vim.lsp.util.open_floating_preview

function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
    opts = opts or {}

    -- Clean markdown.
    contents = cleanup_markdown(contents)

    -- Inner padding.
    contents = add_padding(contents)

    -- Proper popup behavior.
    opts.border = opts.border or "rounded"
    opts.focusable = false
    opts.close_events = opts.close_events or {
        "CursorMoved", "CursorMovedI",
        "BufHidden", "InsertLeave",
        "WinScrolled",
    }

    return orig_floating_preview(contents, syntax, opts, ...)
end

-- SignatureHelp popup with border.
vim.lsp.handlers["textDocument/signatureHelp"] =
    vim.lsp.with(vim.lsp.handlers.signature_help, {
        border = "rounded",
        max_width = 60,
        max_height = 12,
        focusable = false,
        close_events = { "CursorMoved", "InsertLeave", "BufHidden" },
    })

-- Close ALL floating windows on ESC.
local function close_all_floats()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local cfg = vim.api.nvim_win_get_config(win)

        -- Floating window detection:
        --    - relative ~= ""
        --    - OR has zindex
        local is_float =
            cfg.relative ~= "" or
            cfg.zindex ~= nil

        if is_float then
            pcall(vim.api.nvim_win_close, win, true)
        end
    end
end

-- Normal mode ESC.
vim.keymap.set("n", "<Esc>", function()
    close_all_floats()
    return "<Esc>"
end, { expr = true })

-- Insert mode ESC.
vim.keymap.set("i", "<Esc>", function()
    close_all_floats()
    return "<Esc>"
end, { expr = true })

return M

