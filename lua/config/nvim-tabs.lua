-- ~/.config/nvim/lua/config/nvim-tabs.lua
-- Traditional tabline configuration - shows tabs only when multiple exist

local M = {}

-- Function to get tab label with buffer info
local function tab_label(tabnum)
    local buflist = vim.fn.tabpagebuflist(tabnum)
    local winnr = vim.fn.tabpagewinnr(tabnum)
    local bufnr = buflist[winnr]

    -- Get the primary buffer (skip special buffers like NvimTree)
    local primary_bufnr = nil
    for _, buf in ipairs(buflist) do
        local name = vim.fn.bufname(buf)
        local buftype = vim.bo[buf].buftype

        -- Skip special buffers
        if buftype == "" and
           not name:match("NvimTree_") and
           not name:match("toggleterm") and
           vim.bo[buf].filetype ~= "dashboard" then
            primary_bufnr = buf
            break
        end
    end

    -- If no primary buffer found, use the current one
    if not primary_bufnr then
        primary_bufnr = bufnr
    end

    local filename = vim.fn.bufname(primary_bufnr)
    local label = ""

    if filename == "" then
        local filetype = vim.bo[primary_bufnr].filetype
        if filetype == "dashboard" then
            label = "Dashboard"
        else
            label = "[No Name]"
        end
    else
        -- Show just filename, not full path
        label = vim.fn.fnamemodify(filename, ":t")

        -- If multiple buffers have same filename, add parent directory
        local all_buffers = vim.fn.getbufinfo({buflisted = 1})
        local same_name_count = 0
        for _, buf in ipairs(all_buffers) do
            local buf_filename = vim.fn.bufname(buf.bufnr)
            if buf_filename ~= "" and
               vim.fn.fnamemodify(buf_filename, ":t") == label then
                same_name_count = same_name_count + 1
            end
        end

        if same_name_count > 1 then
            local parent = vim.fn.fnamemodify(filename, ":p:h:t")
            if parent ~= "" then
                label = parent .. "/" .. label
            end
        end
    end

    -- Add modified indicator
    if vim.bo[primary_bufnr].modified then
        label = label .. " +"
    end

    -- Count total buffers in this tab
    local buffer_count = 0
    for _, buf in ipairs(buflist) do
        local buftype = vim.bo[buf].buftype
        local name = vim.fn.bufname(buf)
        if buftype == "" and
           not name:match("NvimTree_") and
           not name:match("toggleterm") then
            buffer_count = buffer_count + 1
        end
    end

    if buffer_count > 1 then
        label = label .. " (" .. buffer_count .. ")"
    end

    return string.format(" %d: %s ", tabnum, label)
end

-- Function to render tabline
local function render_tabline()
    local total_tabs = vim.fn.tabpagenr("$")
    local current_tab = vim.fn.tabpagenr()

    -- Only show tabline if more than one tab exists
    if total_tabs <= 1 then
        return ""
    end

    local tabline = ""

    for i = 1, total_tabs do
        -- Highlight current tab
        if i == current_tab then
            tabline = tabline .. "%#TabLineSel#"
        else
            tabline = tabline .. "%#TabLine#"
        end

        -- Make tab clickable
        tabline = tabline .. "%" .. i .. "T"

        -- Add tab label
        tabline = tabline .. tab_label(i)

        -- Add separator
        if i < total_tabs then
            tabline = tabline .. "%#TabLine#│"
        end
    end

    -- Fill remaining space
    tabline = tabline .. "%#TabLineFill#%T"

    -- Add close button on the right
    if total_tabs > 1 then
        tabline = tabline .. "%=%#TabLine#%999X✕ "
    end

    return tabline
end

-- Buffer navigation functions for current tab
function M.next_buffer()
    local buffers = vim.fn.getbufinfo({buflisted = 1})
    local current_buf = vim.api.nvim_get_current_buf()
    local current_index = nil

    -- Filter to only include real file buffers
    local file_buffers = {}
    for _, buf in ipairs(buffers) do
        local buftype = vim.bo[buf.bufnr].buftype
        local name = vim.fn.bufname(buf.bufnr)
        if buftype == "" and
           not name:match("NvimTree_") and
           not name:match("toggleterm") and
           vim.bo[buf.bufnr].filetype ~= "dashboard" then
            table.insert(file_buffers, buf.bufnr)
            if buf.bufnr == current_buf then
                current_index = #file_buffers
            end
        end
    end

    if #file_buffers <= 1 then
        return
    end

    local next_index = current_index and (current_index % #file_buffers) + 1 or 1
    vim.api.nvim_set_current_buf(file_buffers[next_index])
end

function M.prev_buffer()
    local buffers = vim.fn.getbufinfo({buflisted = 1})
    local current_buf = vim.api.nvim_get_current_buf()
    local current_index = nil

    -- Filter to only include real file buffers
    local file_buffers = {}
    for _, buf in ipairs(buffers) do
        local buftype = vim.bo[buf.bufnr].buftype
        local name = vim.fn.bufname(buf.bufnr)
        if buftype == "" and
           not name:match("NvimTree_") and
           not name:match("toggleterm") and
           vim.bo[buf.bufnr].filetype ~= "dashboard" then
            table.insert(file_buffers, buf.bufnr)
            if buf.bufnr == current_buf then
                current_index = #file_buffers
            end
        end
    end

    if #file_buffers <= 1 then
        return
    end

    local prev_index = current_index and
        (current_index - 2) % #file_buffers + 1 or #file_buffers
    vim.api.nvim_set_current_buf(file_buffers[prev_index])
end

-- Setup function
function M.setup()
    -- Set tabline options
    vim.o.showtabline = 1  -- Show tabline only when multiple tabs exist
    vim.o.tabline = "%!v:lua.require'config.nvim-tabs'.render()"

    -- Hide buffer line plugins if they exist
    vim.g.bufferline_show = false
end

-- Render function (called by tabline)
function M.render()
    return render_tabline()
end

return M