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

-- Tabline renderer with fully balanced scroll window.
local function tab_name(style)
    local tabs = vim.fn.tabpagenr("$")
    local current = vim.fn.tabpagenr()

    -- Determine visibility.
    local should_show = true
    if tabs == 1 then
        local buf = vim.fn.tabpagebuflist(1)[1]
        if vim.bo[buf].filetype == "Dashboard" then
            should_show = false
        end
    end
    if not should_show then
        local buf = vim.api.nvim_get_current_buf()
        should_show = vim.bo[buf].filetype ~= "Dashboard"
    end
    if not should_show then
        return ""
    end

    -- Layout parameters.
    local visible_width = vim.o.columns
    local tab_est_width = 25
    local reserved = 8 -- space for indicators
    local max_tabs_visible = math.floor((visible_width - reserved) / tab_est_width)

    local start_tab, end_tab
    if tabs <= max_tabs_visible then
        start_tab = 1
        end_tab = tabs
    else
        local context_left = math.floor(max_tabs_visible / 2)
        local context_right = max_tabs_visible - context_left - 1
        start_tab = math.max(1, current - context_left)
        end_tab = math.min(tabs, current + context_right)

        -- Compensation if there is a left indicator.
        if start_tab > 1 then
            start_tab = start_tab + 0 -- keep as is
        end
        -- Compensation if there is a right indicator.
        if end_tab < tabs then
            local visible = end_tab - start_tab + 1
            if visible < max_tabs_visible then
                end_tab = math.min(tabs, start_tab + max_tabs_visible - 1)
            end
        end
        -- Adjust left if still not enough tabs are visible.
        if end_tab - start_tab + 1 < max_tabs_visible and start_tab > 1 then
            start_tab = math.max(1, end_tab - max_tabs_visible + 1)
        end
    end

    local parts = {}

    -- Left indicator.
    if start_tab > 1 then
        -- Show only if there are hidden tabs on the left.
        if current > start_tab then
            table.insert(parts, "%#TabLineFill#<" .. (start_tab - 1) .. " ")
        else
            table.insert(parts, "%#TabLineFill# ") -- empty space without arrow
        end
    else
        table.insert(parts, "%#TabLineFill# ")
    end

    -- Tabs.
    for i = start_tab, end_tab do
        table.insert(parts, i == current and "%#TabLineSel#" or "%#TabLine#")
        table.insert(parts, "%" .. i .. "T" .. tab_label(i, style))
        if i < end_tab then
            table.insert(parts, " |")
        end
    end

    -- Right indicator.
    if end_tab < tabs then
        table.insert(parts, "%#TabLineFill# " .. (tabs - end_tab) .. ">")
    end

    -- Close tab targets, but do NOT fill full width.
    table.insert(parts, "%T")
    table.insert(parts, "%#TabLineFill#")
    local line = table.concat(parts, "")
    line = line:gsub("%s+$", "") -- remove trailing spaces
    return line
end

-- Auto-move modified tab to the right with fixed logic.
local function auto_move_tab_right()
    local current_tab = vim.fn.tabpagenr()
    local total_tabs = vim.fn.tabpagenr("$")

    -- Don't move if there are 3 or fewer tabs total
    if total_tabs <= 3 then
        return
    end

    -- Check if current tab has modified buffers.
    local buflist = vim.fn.tabpagebuflist(current_tab)
    local has_modified = false

    for _, buf in ipairs(buflist) do
        if vim.bo[buf].modified then
            has_modified = true
            break
        end
    end

    if not has_modified then
        return
    end

    -- Calculate position from end (1-based indexing).
    -- Position 1 from end = last tab, position 2 = second to last, etc.
    local position_from_end = total_tabs - current_tab + 1

    -- If tab is in position 4 or further from end (i.e., not in last 3 positions)
    -- then move it to the end.
    if position_from_end >= 4 then
        vim.cmd("tabmove")  -- move to end (no argument = move to last position)
    end
end

-- Close duplicate tabs (scan from right to left).
local function close_duplicate_tabs()
    local seen_buffers = {}
    local tabs_to_close = {}

    -- Scan from right to left.
    for i = vim.fn.tabpagenr("$"), 1, -1 do
        local buflist = vim.fn.tabpagebuflist(i)
        local duplicate_found = false

        for _, buf in ipairs(buflist) do
            local bufname = vim.fn.bufname(buf)
            -- Skip special buffers.
            if bufname ~= ""
                and not bufname:match("NvimTree_")
                and not bufname:match("^term://") then

                if seen_buffers[buf] then
                    duplicate_found = true
                    break
                else
                    seen_buffers[buf] = true
                end
            end
        end

        if duplicate_found then
            table.insert(tabs_to_close, i)
        end
    end

    -- Close duplicates.
    for _, tab in ipairs(tabs_to_close) do
        pcall(vim.cmd, "tabclose " .. tab)
    end
end

-- Public API.
function M.setup()
    vim.o.showtabline = 2
    vim.o.tabline = "%!v:lua.require'config.nvim-tabs'.render()"

    -- Auto-move modified tabs to the right.
    local tab_group = vim.api.nvim_create_augroup(
        "SmartTabMovement",
        {clear = true}
    )

    vim.api.nvim_create_autocmd(
        {"BufModifiedSet", "TextChanged", "TextChangedI"},
        {
            group = tab_group,
            callback = function()
                -- Debounce: only move after 500ms of inactivity.
                vim.defer_fn(auto_move_tab_right, 500)
            end,
            desc = "Auto-move modified tab to right"
        }
    )

    -- Close duplicate tabs when opening new files.
    vim.api.nvim_create_autocmd("BufEnter", {
        group = tab_group,
        callback = function()
            vim.defer_fn(close_duplicate_tabs, 100)
        end,
        desc = "Close duplicate tabs"
    })

    -- Update tabline when switching tabs to show active tab.
    vim.api.nvim_create_autocmd("TabEnter", {
        group = tab_group,
        callback = function()
            vim.cmd("redrawtabline")
        end,
        desc = "Update tabline scroll position"
    })
end

function M.move_tab_right()
    local current = vim.fn.tabpagenr()
    vim.cmd("tabmove " .. current)
end

function M.move_tab_left()
    local current = vim.fn.tabpagenr()
    if current > 1 then
        vim.cmd("tabmove " .. (current - 2))
    end
end

function M.force_move_tab_last()
    vim.cmd("tabmove " .. vim.fn.tabpagenr("$"))
end

function M.render()
    return tab_name(1) -- style 1: parent/filename
end

return M