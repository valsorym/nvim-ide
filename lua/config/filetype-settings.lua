-- ~/.config/nvim/lua/config/filetype-settings.lua
-- Indentation lives in ftplugin/*.lua; window profiles must follow the buffer.

local M = {}
local line_width = require("config.line-width")

function M.setup()
    vim.opt.colorcolumn = ""
    vim.opt.wrap = false
    vim.opt.expandtab = true
    vim.opt.tabstop = 4
    vim.opt.shiftwidth = 4
    vim.opt.softtabstop = 4
    -- C-style smartindent treats leading # as preprocessor directives in every language.
    vim.opt.smartindent = false
    vim.opt.autoindent = true

    local views, applied = {}, {}
    local options = { "wrap", "linebreak", "breakindent", "showbreak", "colorcolumn" }
    local function apply(buf, win)
        if vim.bo[buf].buftype ~= "" then
            vim.wo[win].colorcolumn = ""
            return
        end
        local prose = line_width.is_prose(buf)
        if prose then
            -- Soft wrapping changes only the display, even with EditorConfig.
            vim.bo[buf].textwidth = 0
            vim.bo[buf].wrapmargin = 0
            vim.bo[buf].formatoptions = vim.bo[buf].formatoptions:gsub("[ta]", "")
        end
        local saved = views[win] and views[win][buf]
        local ft = vim.bo[buf].filetype
        local settings = saved and saved.filetype == ft and vim.deepcopy(saved.settings) or {
            wrap = prose, linebreak = prose, breakindent = prose,
            showbreak = prose and "↪ " or "", colorcolumn = line_width.column(buf),
        }
        if saved and settings.colorcolumn == saved.column then
            settings.colorcolumn = line_width.column(buf)
        end
        if prose then settings.colorcolumn = "" end
        for name, value in pairs(settings) do vim.wo[win][name] = value end
        applied[win] = applied[win] or {}
        applied[win][buf] = ft
    end
    local group = vim.api.nvim_create_augroup("BufferWindowOptions", { clear = true })
    vim.api.nvim_create_autocmd("BufWinLeave", { group = group, callback = function(args)
        if vim.bo[args.buf].buftype ~= "" then return end
        -- :only can close a different window; the current one may show another file.
        for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
            views[win] = views[win] or {}
            local saved = {}
            for _, name in ipairs(options) do saved[name] = vim.wo[win][name] end
            views[win][args.buf] = { filetype = vim.bo[args.buf].filetype, settings = saved,
                column = line_width.column(args.buf) }
        end
    end })
    vim.api.nvim_create_autocmd("BufWinEnter", { group = group, callback = function(args)
        local win = vim.api.nvim_get_current_win()
        apply(args.buf, win)
    end })
    vim.api.nvim_create_autocmd("WinClosed", { group = group, callback = function(args)
        local win = tonumber(args.match)
        views[win], applied[win] = nil, nil
    end })
    vim.api.nvim_create_autocmd("BufWipeout", { group = group, callback = function(args)
        for _, buffers in pairs(views) do buffers[args.buf] = nil end
        for _, buffers in pairs(applied) do buffers[args.buf] = nil end
    end })

    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        callback = function(args)
            -- Run after native ftplugins and EditorConfig, including :setfiletype.
            vim.schedule(function()
                if not vim.api.nvim_buf_is_valid(args.buf) then return end
                for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
                    if not applied[win] or applied[win][args.buf] ~= vim.bo[args.buf].filetype then
                        apply(args.buf, win)
                    end
                end
            end)
        end,
    })
end

-- Utility functions for indentation conversion
function M.tabs_to_spaces()
    vim.cmd("setlocal expandtab")
    vim.cmd("retab")
    print("Converted tabs to spaces")
end

function M.spaces_to_tabs()
    vim.cmd("setlocal noexpandtab")
    vim.cmd("retab!")
    print("Converted spaces to tabs")
end

function M.show_indent_info()
    local bufnr = vim.api.nvim_get_current_buf()
    local expandtab = vim.bo[bufnr].expandtab
    local tabstop = vim.bo[bufnr].tabstop
    local shiftwidth = vim.bo[bufnr].shiftwidth
    local softtabstop = vim.bo[bufnr].softtabstop
    local filetype = vim.bo[bufnr].filetype
    local wrap = vim.wo.wrap
    local colorcolumn = vim.wo.colorcolumn

    print(string.format(
        "File: %s | wrap: %s | cc: %s | expandtab: %s | " ..
        "tab: %d | shift: %d | soft: %d",
        filetype,
        wrap and "true" or "false",
        colorcolumn,
        expandtab and "true" or "false",
        tabstop,
        shiftwidth,
        softtabstop
    ))
end

function M.setup_commands()
    vim.api.nvim_create_user_command("TabsToSpaces",
        M.tabs_to_spaces,
        {desc = "Convert tabs to spaces in current buffer"}
    )

    vim.api.nvim_create_user_command("SpacesToTabs",
        M.spaces_to_tabs,
        {desc = "Convert spaces to tabs in current buffer"}
    )

    vim.api.nvim_create_user_command("IndentInfo",
        M.show_indent_info,
        {desc = "Show current indentation settings"}
    )

    vim.api.nvim_create_user_command("Indent2", function()
        vim.opt_local.expandtab = true
        vim.opt_local.tabstop = 2
        vim.opt_local.shiftwidth = 2
        vim.opt_local.softtabstop = 2
        print("Set indentation to 2 spaces")
    end, {desc = "Set indentation to 2 spaces"})

    vim.api.nvim_create_user_command("Indent4", function()
        vim.opt_local.expandtab = true
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.softtabstop = 4
        print("Set indentation to 4 spaces")
    end, {desc = "Set indentation to 4 spaces"})

    vim.api.nvim_create_user_command("IndentTab", function()
        vim.opt_local.expandtab = false
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.softtabstop = 0
        print("Set indentation to tabs")
    end, {desc = "Set indentation to tabs"})
end

return M
