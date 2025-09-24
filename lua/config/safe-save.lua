-- ~/.config/nvim/lua/config/safe-save.lua
-- Safe save: no errors on unnamed/special buffers, quiet LSP format.

local M = {}

local ico_ok, ico_err, ico_cfg = "", "", ""

-- Check if current buffer is a normal, writable file.
local function can_write()
    if vim.bo.modifiable == false then return false end
    if vim.bo.readonly == true then return false end
    local bt = vim.bo.buftype
    if bt ~= "" and bt ~= "acwrite" then return false end
    if vim.fn.bufname("%") == "" then return false end
    return true
end

-- Format only when a client supports it (avoids LSP error spam).
local function try_format(timeout)
    timeout = timeout or 800
    local ok = pcall(function()
        local bufnr = 0
        local clients = vim.lsp.get_clients({bufnr = bufnr})
        if #clients == 0 then return end
        local has = false
        for _, c in ipairs(clients) do
            if c.supports_method
                and c:supports_method("textDocument/formatting") then
                has = true
                break
            end
        end
        if has then
            vim.lsp.buf.format({async = false, timeout_ms = timeout})
        end
    end)
    return ok
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

-- Public: smart write with friendly message.
function M.smart_write()
    if not can_write() then
        say(ico_err .. "  Cannot save this buffer", vim.log.levels.WARN)
        return
    end
    -- Quiet format (only if supported).
    try_format()
    -- Silent write; suppress Vim(write) errors.
    local ok, err = pcall(vim.cmd, "silent! write")
    if not ok then
        say(ico_err .. "  Cannot save: " .. (err or ""), vim.log.levels.ERROR)
        return
    end
    say(ico_ok .. "  Saved", vim.log.levels.INFO)
end

-- Optional: guard your BufWritePre formatter if you use one.
function M.setup_format_guard()
    local grp = vim.api.nvim_create_augroup("SafeFormatGuard", {clear=true})
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = grp,
        callback = function()
            if not can_write() then return end
            try_format()
        end,
        desc = "Format only when buffer is writable and supported",
    })
end

return M