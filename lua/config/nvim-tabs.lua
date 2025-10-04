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

-- Auto-move modified tab to the right with protection.
local function auto_move_tab_right()
    local current_tab = vim.fn.tabpagenr()
    local total_tabs = vim.fn.tabpagenr("$")

    -- Don't move if it's the only tab.
    if total_tabs <= 1 then
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

    -- Protection: don't move if tab is already in the last N positions.
    local freeze_right_tabs = 3
    local distance_from_end = total_tabs - current_tab

    if distance_from_end <= freeze_right_tabs then
        -- Tab is already close to the end, don't move
        return
    end

    -- Additional protection: only move if there are many tabs.
    -- and tab is not visible on screen.
    if total_tabs > 5 and distance_from_end > 3 then
        -- Move tab to the end.
        vim.cmd("tabmove " .. total_tabs)
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

    -- Auto-move modified tabs to the right
    local tab_group = vim.api.nvim_create_augroup(
        "SmartTabMovement",
        {clear = true}
    )

    vim.api.nvim_create_autocmd(
        {"BufModifiedSet", "TextChanged", "TextChangedI"},
        {
            group = tab_group,
            callback = function()
                -- Debounce: only move after 500ms of inactivity
                vim.defer_fn(auto_move_tab_right, 500)
            end,
            desc = "Auto-move modified tab to right"
        }
    )

    -- Close duplicate tabs when opening new files
    vim.api.nvim_create_autocmd("BufEnter", {
        group = tab_group,
        callback = function()
            vim.defer_fn(close_duplicate_tabs, 100)
        end,
        desc = "Close duplicate tabs"
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