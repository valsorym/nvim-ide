-- Select existing buffers by identity; never reload unsaved text from disk.
local M = {}

function M.open()
    local current = vim.api.nvim_get_current_buf()
    local entries = {}
    for _, info in ipairs(vim.fn.getbufinfo()) do
        local buf = info.bufnr
        if vim.bo[buf].buftype == "" and (info.listed == 1 or info.changed == 1 or #info.windows > 0)
            and (info.name ~= "" or info.changed == 1 or #info.windows > 0) then
            entries[#entries + 1] = {
                buf = buf, name = info.name, modified = info.changed == 1,
                visible = #info.windows > 0, used = info.lastused or 0,
            }
        end
    end
    table.sort(entries, function(a, b)
        if (a.buf == current) ~= (b.buf == current) then return a.buf == current end
        if a.used ~= b.used then return a.used > b.used end
        return a.buf < b.buf
    end)
    if #entries == 0 then vim.notify("No open file buffers"); return end
    require("config.picker").select(entries, {
        prompt = "Open files • + unsaved • h hidden • type to filter",
        close_on_q = true,
        format_item = function(entry)
            local name = entry.name ~= "" and vim.fn.fnamemodify(entry.name, ":~:.") or "[No Name]"
            return string.format("%s %s %s %d  %s", entry.buf == current and ">" or " ",
                entry.modified and "+" or " ", entry.visible and " " or "h", entry.buf, vim.fn.strtrans(name))
        end,
    }, function(entry)
        if entry then require("config.nvim-tabs").focus_buffer(entry.buf) end
    end)
end

return M
