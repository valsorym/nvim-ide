-- Let Neovim handle per-client offset encodings, then open converted locations in tabs.
local M = {}
function M.jump(method, fallback)
    if #vim.lsp.get_clients({ bufnr = 0, method = "textDocument/" .. method }) == 0 then
        if fallback then
            vim.cmd.normal({ args = { vim.api.nvim_replace_termcodes(fallback, true, false, true) }, bang = true })
        else vim.notify("No language server supports " .. method, vim.log.levels.INFO) end
        return
    end
    local origin = vim.api.nvim_get_current_win()
    local pos = vim.api.nvim_win_get_cursor(origin)
    local from = { vim.api.nvim_get_current_buf(), pos[1], pos[2] + 1, 0 }
    local word = vim.fn.expand("<cword>")
    local function open(item)
        if not item then return end
        local filename = item.filename or (item.bufnr and vim.api.nvim_buf_get_name(item.bufnr))
        if not filename or filename == "" then return end
        local stack
        if vim.api.nvim_win_is_valid(origin) then
            stack = vim.fn.gettagstack(origin)
            vim.fn.settagstack(origin, { items = { { tagname = word, from = from } } }, "t")
        end
        -- New tabs inherit the tag stack; restore it if opening was cancelled.
        if not require("config.nvim-tabs").open(filename) then
            if stack and vim.api.nvim_win_is_valid(origin) then
                vim.fn.settagstack(origin, { items = stack.items, curidx = stack.curidx }, "r")
            end
            return
        end
        if stack and vim.api.nvim_win_is_valid(origin) and vim.api.nvim_get_current_win() ~= origin then
            -- :tab drop can reuse a window or inherit a different tab's stack.
            local destination = vim.fn.gettagstack(origin)
            vim.fn.settagstack(0, { items = destination.items, curidx = destination.curidx }, "r")
        end
        vim.api.nvim_win_set_cursor(0, { item.lnum, math.max(0, (item.col or 1) - 1) })
        vim.cmd("normal! zz")
    end
    vim.lsp.buf[method]({ on_list = function(result)
        if #result.items == 1 then open(result.items[1]) else
            vim.ui.select(result.items, { prompt = "Locations", format_item = function(item)
                return (item.filename or "") .. ":" .. item.lnum .. " " .. (item.text or "")
            end }, open)
        end
    end })
end
return M
