-- ~/.config/nvim/lua/config/safe-save.lua
-- Safe save: friendly messages, LSP-aware formatting.

local M = {}

-- Icons
local ico_ok, ico_err, ico_fmt = "", "", ""

-- Check if current buffer is a normal, writable file.
local function can_write()
    -- Not modifiable buffer
    if vim.bo.modifiable == false then
        return false, "Buffer is not modifiable"
    end
    -- Readonly file
    if vim.bo.readonly == true then
        return false, "File is readonly"
    end
    -- Special buftypes should not be written
    local bt = vim.bo.buftype
    if bt ~= "" and bt ~= "acwrite" then
        return false, "Special buffer (type: " .. bt .. ")"
    end
    -- Unnamed buffer
    if vim.fn.bufname("%") == "" then
        return false, "Unnamed buffer"
    end
    return true, nil
end

-- Notify helper (falls back to :echo).
local function say(msg, level)
    level = level or vim.log.levels.WARN
    if vim.notify then
        vim.notify(msg, level)
    else
        local hl = (level == vim.log.levels.ERROR) and "ErrorMsg"
            or (level == vim.log.levels.INFO) and "MoreMsg"
            or "WarningMsg"
        vim.api.nvim_echo({{msg, hl}}, false, {})
    end
end

-- Try format when supported. Returns (supported, formatted_ran).
local function try_format(timeout)
    timeout = timeout or 800
    local supported, ran = false, false

    local ok = pcall(function()
        local bufnr = 0
        local clients = vim.lsp.get_clients({bufnr = bufnr})
        if #clients == 0 then return end
        for _, c in ipairs(clients) do
            if c.supports_method
                and c:supports_method("textDocument/formatting") then
                supported = true
                break
            end
        end
        if supported then
            vim.lsp.buf.format({async = false, timeout_ms = timeout})
            ran = true
        end
    end)

    -- If pcall failed, do not treat as formatted.
    if not ok then ran = false end
    return supported, ran
end

-- Public: smart write with friendly messages.
function M.smart_write()
    local ok_can, reason = can_write()
    if not ok_can then
        say(ico_err .. "  Cannot save: " .. reason, vim.log.levels.WARN)
        return
    end

    -- LSP format only if user did not disable it.
    local did_support, did_format = false, false
    if vim.g.format_on_save ~= false then
        did_support, did_format = try_format()
    end

    -- Silent write; suppress Vim(write) errors.
    local okw, errw = pcall(vim.cmd, "silent! write")
    if not okw then
        say(ico_err .. "  Cannot save: " .. (errw or ""),
            vim.log.levels.ERROR)
        return
    end

    -- Success messages.
    if did_format then
        say(ico_ok .. "  Saved and formated", vim.log.levels.INFO)
    else
        say(ico_ok .. "  Saved", vim.log.levels.INFO)
    end
end

-- Optional: guard a BufWritePre hook if you prefer auto-format.
function M.setup_format_guard()
    local grp = vim.api.nvim_create_augroup("SafeFormatGuard", {clear = true})
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = grp,
        callback = function()
            local ok_can = select(1, can_write())
            if not ok_can then return end
            if vim.g.format_on_save ~= false then
                try_format()
            end
        end,
        desc = "Format only when buffer is writable and supported",
    })
end

return M
