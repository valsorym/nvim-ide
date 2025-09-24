-- ~/.config/nvim/lua/plugins/notifications.lua
-- Add inner padding via custom renderer wrapper.

return {
    "rcarriga/nvim-notify",
    keys = {
        {
            "<leader>un",
            function()
                require("notify").dismiss({silent = true, pending = true})
            end,
            desc = "Dismiss all notifications",
        },
    },
    opts = function()
        -- Build a padded renderer around a base renderer.
        -- pad_h: blank lines top/bottom; pad_w: spaces left/right.
        local function make_padded_renderer(pad_h, pad_w, base_name)
            pad_h = pad_h or 0
            pad_w = pad_w or 1
            base_name = base_name or "minimal"
            local base = require("notify.render")[base_name]
            return function(bufnr, notif, hl, conf)
                -- Render with the base renderer first.
                base(bufnr, notif, hl, conf)
                -- Then add padding around the content.
                local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                local sp = string.rep(" ", pad_w)
                for i, l in ipairs(lines) do
                    lines[i] = sp .. (l or "") .. sp
                end
                for _ = 1, pad_h do
                    table.insert(lines, 1, "")
                    table.insert(lines, "")
                end
                vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
            end
        end

        -- Try to match background to Normal hl; fallback to black.
        local function bg_hex(name, fallback)
            local ok, hl = pcall(vim.api.nvim_get_hl, 0, {name = name})
            if ok and hl and hl.bg then
                return string.format("#%06x", hl.bg)
            end
            return fallback
        end

        local icons = {
            ERROR = "", WARN = "", INFO = "", DEBUG = "", TRACE = "󰛕",
        }

        -- Tune padding here:
        local PAD_H, PAD_W = 1, 2
        local padded = make_padded_renderer(PAD_H, PAD_W, "minimal")

        return {
            timeout = 3000,
            fps = 60,
            level = 2,
            icons = icons,
            minimum_width = 44,
            max_height = function() return math.floor(vim.o.lines * 0.75) end,
            max_width = function() return math.floor(vim.o.columns * 0.75) end,
            background_colour = bg_hex("Normal", "#000000"),
            render = padded, -- <- add inner padding
            stages = "fade_in_slide_out",
            top_down = true,
            on_open = function(win)
                vim.api.nvim_win_set_config(win, {zindex = 200})
                pcall(vim.api.nvim_set_option_value, "winhl",
                    "Normal:NormalFloat,FloatBorder:FloatBorder",
                    {scope = "local", win = win})
                pcall(vim.api.nvim_set_option_value, "winblend", 0,
                    {scope = "local", win = win})
            end,
        }
    end,
    config = function(_, opts)
        local notify = require("notify")
        notify.setup(opts)
        if not pcall(require, "noice") then
            vim.notify = notify
        end
    end,
}


