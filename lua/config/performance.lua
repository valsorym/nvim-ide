-- One cheap buffer classification shared by all expensive integrations.
local M = {}

function M.is_large(buf)
    buf = (not buf or buf == 0) and vim.api.nvim_get_current_buf() or buf
    return vim.b[buf].large_file == true
end

function M.apply(buf)
    if not vim.api.nvim_buf_is_valid(buf) then return end
    vim.b[buf].large_file = true
    vim.b[buf].ibl_enabled = false
    vim.b[buf].copilot_enabled = false
    vim.bo[buf].syntax = ""
    vim.bo[buf].synmaxcol = 200
    pcall(vim.treesitter.stop, buf)
    vim.diagnostic.enable(false, { bufnr = buf })
    -- Detach only this buffer: other files may share the same LSP client.
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
        vim.lsp.buf_detach_client(buf, client.id)
    end
    if package.loaded.ufo then pcall(require("ufo").detach, buf) end
    if package.loaded.gitsigns then pcall(require("gitsigns").detach, buf) end
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        vim.wo[win].foldmethod = "manual"
        vim.wo[win].foldenable = false
        vim.wo[win].spell = false
        vim.wo[win].wrap = false
    end
end

function M.check(buf)
    if not vim.api.nvim_buf_is_loaded(buf) or vim.bo[buf].buftype ~= "" then return end
    if vim.b[buf].large_file then return end
    local count = vim.api.nvim_buf_line_count(buf)
    local bytes = vim.api.nvim_buf_get_offset(buf, count)
    -- These APIs use the buffer's line index; they do not copy its contents to Lua.
    if bytes > (vim.g.nvim_ide_large_file_bytes or 1024 * 1024)
        or count > (vim.g.nvim_ide_large_file_lines or 20000) then
        M.apply(buf)
    end
end

function M.setup()
    local group = vim.api.nvim_create_augroup("LargeFiles", { clear = true })
    vim.api.nvim_create_autocmd("BufReadPre", {
        group = group,
        callback = function(args)
            local stat = vim.uv.fs_stat(args.file)
            vim.b[args.buf].large_file = stat ~= nil
                and stat.size > (vim.g.nvim_ide_large_file_bytes or 1024 * 1024)
        end,
    })
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWinEnter", "FileType" }, {
        group = group,
        callback = function(args)
            if M.is_large(args.buf) then M.apply(args.buf) else M.check(args.buf) end
        end,
    })
    -- Recheck growing buffers after an edit pause, never on each inserted character.
    vim.api.nvim_create_autocmd({ "InsertLeave", "BufWritePost" }, {
        group = group,
        callback = function(args) M.check(args.buf) end,
    })
    vim.api.nvim_create_autocmd("LspAttach", {
        group = group,
        callback = function(args)
            if M.is_large(args.buf) then
                vim.schedule(function()
                    if vim.api.nvim_buf_is_valid(args.buf) then
                        vim.lsp.buf_detach_client(args.buf, args.data.client_id)
                    end
                end)
            end
        end,
    })
    vim.api.nvim_create_user_command("LargeFileInfo", function()
        vim.notify(M.is_large(0) and "Large-file mode: parsing and LSP disabled for this buffer"
            or "Normal mode: language integrations available")
    end, { desc = "Show buffer performance mode" })
end

return M
