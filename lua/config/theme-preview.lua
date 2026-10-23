-- Dashboard lines include full-screen padding; previews need their own geometry.
local M = {}
local namespace = vim.api.nvim_create_namespace("nvim_ide_theme_preview")

function M.dashboard(source)
    local original = vim.api.nvim_buf_get_lines(source, 0, -1, false)
    local columns = vim.o.columns
    local marks = vim.api.nvim_buf_get_extmarks(source, -1, 0, -1, { details = true })
    local header = { ["╭"] = true, ["│"] = true, ["╰"] = true }
    return require("telescope.previewers").new_buffer_previewer({
        title = "Dashboard",
        get_buffer_by_name = function() return "nvim-ide://theme-dashboard" end,
        define_preview = function(self, _, status)
            local win = status.layout.preview.winid
            local width, height = vim.api.nvim_win_get_width(win), vim.api.nvim_win_get_height(win)
            local compact = width < 72
            local rows, mapping, shifts = {}, {}, {}
            local compact_title = false
            local offset = math.floor((width - columns) / 2)
            for row, line in ipairs(original) do
                local leading = #(line:match("^%s*") or "")
                local body = line:sub(leading + 1)
                if compact and header[body:sub(1, 3)] then
                    if not compact_title then
                        rows[#rows + 1] = string.rep(" ", math.max(0, math.floor((width - 8) / 2))) .. "NVIM IDE"
                        compact_title = true
                    end
                else
                    local padding = math.max(0, leading + offset)
                    rows[#rows + 1] = body ~= "" and (string.rep(" ", padding) .. body) or ""
                    mapping[row - 1], shifts[row - 1] = #rows - 1, padding - leading
                end
            end
            local first, last = 1, #rows
            while first < last and rows[first] == "" do first = first + 1 end
            while last > first and rows[last] == "" do last = last - 1 end
            local top = math.max(0, math.floor((height - (last - first + 1)) / 2))
            local output = {}
            for _ = 1, top do output[#output + 1] = "" end
            for row = first, last do output[#output + 1] = rows[row] end
            local buf = self.state.bufnr
            vim.bo[buf].modifiable = true
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
            vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
            for _, mark in ipairs(marks) do
                local row, col, details = mark[2], mark[3], mark[4]
                local mapped = mapping[row]
                if mapped and mapped >= first - 1 and mapped <= last - 1 then
                    local target = mapped - first + 1 + top
                    local start = math.max(0, math.min(#output[target + 1], col + shifts[row]))
                    if details.hl_group then
                        local finish = details.end_row == row and math.min(#output[target + 1], (details.end_col or #original[row + 1]) + shifts[row]) or #output[target + 1]
                        if finish > start then
                            vim.api.nvim_buf_set_extmark(buf, namespace, target, start, { end_col = finish, hl_group = details.hl_group })
                        end
                    end
                    if details.virt_text then
                        vim.api.nvim_buf_set_extmark(buf, namespace, target, start,
                            { virt_text = details.virt_text, virt_text_pos = details.virt_text_pos or "eol" })
                    end
                end
            end
            vim.bo[buf].modified, vim.bo[buf].modifiable = false, false
            vim.wo[win].wrap, vim.wo[win].number, vim.wo[win].relativenumber = false, false, false
            vim.api.nvim_win_set_cursor(win, { 1, 0 })
        end,
    })
end

return M
