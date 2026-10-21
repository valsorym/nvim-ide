-- RST decoration is buffer-local and visits only the visible lines.
local M = {}
local ns = vim.api.nvim_create_namespace("rst-render")
local timer = vim.uv.new_timer()
local group = vim.api.nvim_create_augroup("RstRender", { clear = true })

function M.render(buf)
    if not vim.api.nvim_buf_is_valid(buf) then return end
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    if not vim.b[buf].rst_render or require("config.performance").is_large(buf) then return end
    local seen = {}
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        local first, last = unpack(vim.api.nvim_win_call(win, function()
            return { math.max(0, vim.fn.line("w0") - 2), math.min(vim.api.nvim_buf_line_count(buf), vim.fn.line("w$") + 1) }
        end))
        local lines = vim.api.nvim_buf_get_lines(buf, first, last, false)
        for i, line in ipairs(lines) do
            local row = first + i - 1
            if not seen[row] then
                seen[row] = true
                local next_line = lines[i + 1] or ""
                if line:match("%S") and next_line:match("^[=~`%-%^#]+%s*$") then
                    vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
                        virt_text = { { "󰎥  ", "Title" } }, virt_text_pos = "inline",
                        end_row = row + 1, hl_group = "Title",
                    })
                elseif line:match("^%s*[%-%*%+]%s+") then
                    local indent = line:match("^%s*")
                    vim.api.nvim_buf_set_extmark(buf, ns, row, #indent, {
                        virt_text = { { "•", "Special" } }, virt_text_pos = "overlay",
                    })
                elseif line:match("^%s*%.%.%s+[%w%-]+::") then
                    vim.api.nvim_buf_set_extmark(buf, ns, row, 0, { end_row = row + 1, hl_group = "Special" })
                end
                for start_pos, _, end_pos in line:gmatch("()``(.-)``()") do
                    vim.api.nvim_buf_set_extmark(buf, ns, row, start_pos - 1, { end_col = end_pos - 1, hl_group = "String" })
                end
            end
        end
    end
end

local function refresh()
    timer:stop()
    timer:start(80, 0, vim.schedule_wrap(function()
        local seen = {}
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.b[buf].rst_render and not seen[buf] then M.render(buf); seen[buf] = true end
        end
    end))
end
vim.api.nvim_create_autocmd({ "WinScrolled", "BufWinEnter", "TextChanged", "InsertLeave", "ColorScheme" }, {
    group = group, callback = refresh,
})
vim.api.nvim_create_autocmd("VimLeavePre", { group = group, once = true, callback = function()
    timer:stop(); timer:close()
end })
function M.toggle()
    local buf = vim.api.nvim_get_current_buf()
    vim.b[buf].rst_render = not vim.b[buf].rst_render
    M.render(buf)
end
return M
