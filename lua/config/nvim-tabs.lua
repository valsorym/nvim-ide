-- ~/.config/nvim/lua/config/nvim-tabs.lua
-- Smart tabs configuration with dashboard support.

local M = {}

-- Tab label generator.
local function tab_label(n, style)
    local buflist = vim.fn.tabpagebuflist(n)
    local winnr = vim.fn.tabpagewinnr(n)
    local buf = buflist[winnr]

    -- Find the first normal buffer (not NvimTree).
    for _, b in ipairs(buflist) do
        local name = vim.fn.bufname(b)
        if not name:match("NvimTree_") and name ~= "" then
            buf = b
            break
        end
    end

    local file = vim.fn.bufname(buf)
    local label = vim.fn.fnamemodify(file, ":t")

    -- Handle special cases
    if label == "" then
        local filetype = vim.bo[buf].filetype
        if filetype == "dashboard" then
            label = "Dashboard"
        else
            label = "[No Name]"
        end
    else
        local parent = vim.fn.fnamemodify(file, ":p:h:t")
        if parent ~= "" and style ~= 0 then
            if style == 2 then
                parent = parent:sub(1, 1) .. ".." .. parent:sub(-1)
            elseif style == 3 then
                parent = parent:sub(1, 1)
            elseif style == 4 and #parent > 5 then
                parent = parent:sub(1, 3) .. ".."
            end
            label = parent .. "/" .. label
        end
    end

    if vim.bo[buf].modified then
        label = label .. "*"
    end

    return string.format(" %d. %s ", n, label)
end

-- Tabline renderer.
local function tab_name(style)
    local s = ""
    local tabs = vim.fn.tabpagenr("$")
    local current = vim.fn.tabpagenr()

    -- Always show tabline if more than one tab OR if current tab is not dashboard
    local should_show = true
    if tabs == 1 then
        local buf = vim.fn.tabpagebuflist(1)[1]
        if vim.bo[buf].filetype == "Dashboard" then
            should_show = false
        end
    end

    if not should_show then
        local current_buf = vim.api.nvim_get_current_buf()
        local filetype = vim.bo[current_buf].filetype
        local bufname = vim.fn.bufname(current_buf)
        should_show = filetype ~= "Dashboard" or bufname ~= ""
    end

    if should_show then
        for i = 1, tabs do
            if i == current then
                s = s .. "%#TabLineSel#"
            else
                s = s .. "%#TabLine#"
            end
            s = s .. "%" .. i .. "T" .. tab_label(i, style) .. " ▕"
        end
        s = s .. "%#TabLineFill#%T"
    end

    return s
end

-- Public API.
function M.setup()
    vim.o.showtabline = 2
    vim.o.tabline = "%!v:lua.require'config.nvim-tabs'.render()"
end

function M.render()
    return tab_name(1) -- style 1: parent/filename
end

return M