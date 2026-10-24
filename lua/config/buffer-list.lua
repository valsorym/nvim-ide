-- Select existing buffers by identity; never reload unsaved text from disk.
local M = {}
local footer_ns = vim.api.nvim_create_namespace("OpenFilesFooter")

local function footer(picker)
    local border = picker.results_border
    if not border or not border.bufnr or not vim.api.nvim_buf_is_valid(border.bufnr) then return end
    local width = vim.api.nvim_win_get_width(picker.results_win)
    local controls = { { "ID↵", "open" }, { "text", "filter" }, { "↑↓", "move" }, { "Esc/q", "close" } }
    if width >= 88 then
        vim.list_extend(controls, { { "%", "current" }, { "+", "unsaved" }, { "h", "hidden" } })
    elseif width < 65 then
        controls = { { "ID↵", "open" }, { "Esc/q", "close" } }
    end
    local chunks = { { "[ ", "FooterDesc" } }
    for i, control in ipairs(controls) do
        if i > 1 then chunks[#chunks + 1] = { " | ", "FooterDesc" } end
        chunks[#chunks + 1] = { control[1], "FooterKey" }
        chunks[#chunks + 1] = { (width >= 110 and " - " or " ") .. control[2], "FooterDesc" }
    end
    chunks[#chunks + 1] = { " ]", "FooterDesc" }
    if width < 34 then chunks = { { "[ ID↵ | Esc/q ]", "FooterKey" } } end
    local parts = {}
    for _, chunk in ipairs(chunks) do parts[#parts + 1] = chunk[1] end
    local text = table.concat(parts)
    border:change_title(text, "S")
    local row = vim.api.nvim_buf_line_count(border.bufnr) - 1
    local line = vim.api.nvim_buf_get_lines(border.bufnr, row, row + 1, false)[1]
    local start = line:find(text, 1, true)
    vim.api.nvim_buf_clear_namespace(border.bufnr, footer_ns, 0, -1)
    if not start then return end
    local offset = start - 1
    for _, chunk in ipairs(chunks) do
        vim.api.nvim_buf_add_highlight(border.bufnr, footer_ns, chunk[2], row, offset, offset + #chunk[1])
        offset = offset + #chunk[1]
    end
end

local function id_sorter()
    local sorter = require("telescope.config").values.generic_sorter({})
    local score, highlight = sorter.scoring_function, sorter.highlighter
    -- Numeric and path queries search different fields; do not cache exclusions between them.
    sorter.discard = false
    sorter.scoring_function = function(self, prompt, line, entry, ...)
        if prompt:match("^%d+$") then return entry.value.id:find(prompt, 1, true) and 0 or -1 end
        return score(self, prompt, line, entry, ...)
    end
    if highlight then
        sorter.highlighter = function(self, prompt, display)
            if prompt:match("^%d+$") then return {} end
            return highlight(self, prompt, display)
        end
    end
    return sorter
end

function M.open()
    local current = vim.api.nvim_get_current_buf()
    local entries = {}
    for _, info in ipairs(vim.fn.getbufinfo()) do
        local buf = info.bufnr
        if vim.bo[buf].buftype == "" and vim.bo[buf].filetype ~= "dashboard"
            and (info.listed == 1 or info.changed == 1 or #info.windows > 0)
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
    local id_width = 4
    for _, entry in ipairs(entries) do id_width = math.max(id_width, #tostring(entry.buf)) end
    for _, entry in ipairs(entries) do entry.id = string.format("%0" .. id_width .. "d", entry.buf) end
    require("config.picker").select(entries, {
        prompt = "Open files",
        close_on_q = true,
        selection_caret = "› ", entry_prefix = "  ",
        layout_config = { width = 100, height = 24 },
        sorter = id_sorter(),
        ordinal = function(entry) return entry.name ~= "" and entry.name or "[No Name]" end,
        resolve_choice = function(prompt, entry, index)
            if not prompt:match("^%d+$") then return entry, index end
            if entry and entry.id:find(prompt, 1, true) then return entry, index end
            -- Enter may arrive before Telescope finishes filtering the typed digits.
            for i, candidate in ipairs(entries) do
                if candidate.id:find(prompt, 1, true) then return candidate, i end
            end
        end,
        format_item = function(entry)
            local name = entry.name ~= "" and vim.fn.fnamemodify(entry.name, ":~:.") or "[No Name]"
            local id = entry.id
            local flags = (entry.buf == current and "%" or "") .. (entry.modified and "+" or "")
                .. (not entry.visible and "h" or "")
            local text = id .. "  " .. vim.fn.strtrans(name)
            local highlights = { { { 0, #id }, "DiagnosticInfo" } }
            if flags ~= "" then
                highlights[#highlights + 1] = { { #text + 2, #text + 2 + #flags }, "Comment" }
                text = text .. "  " .. flags
            end
            return text, highlights
        end,
        on_open = function(picker, buf)
            footer(picker)
            local resize = vim.api.nvim_create_autocmd("VimResized", {
                callback = function() vim.schedule(function()
                    if not picker.closed then footer(picker) end
                end) end,
            })
            vim.api.nvim_create_autocmd("BufWipeout", { buffer = buf, once = true,
                callback = function() vim.api.nvim_del_autocmd(resize) end })
        end,
    }, function(entry)
        if entry then require("config.nvim-tabs").focus_buffer(entry.buf) end
    end)
end

return M
