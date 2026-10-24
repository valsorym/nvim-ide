-- Keep one-file-per-tab navigation while leaving native splits and commands usable.
local M = {}

local function main_buffer(tab)
    local win = vim.api.nvim_tabpage_get_win(tab)
    local buf = vim.api.nvim_win_get_buf(win)
    for _, candidate in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
        local b = vim.api.nvim_win_get_buf(candidate)
        if vim.bo[b].buftype == "" and vim.api.nvim_buf_get_name(b) ~= "" then return b end
    end
    return buf
end

function M.render()
    local tabs = vim.api.nvim_list_tabpages()
    local current = vim.fn.tabpagenr()
    local visible = math.max(1, math.floor((vim.o.columns - 8) / 25))
    local first = math.max(1, math.min(current - math.floor(visible / 2), #tabs - visible + 1))
    local last = math.min(#tabs, first + visible - 1)
    local parts = { "%#TabLineFill# " }
    if first > 1 then parts[#parts + 1] = "<" .. (first - 1) .. " " end
    for i = first, last do
        local buf = main_buffer(tabs[i])
        local name = vim.api.nvim_buf_get_name(buf)
        local label = name == "" and (vim.bo[buf].filetype == "dashboard" and "Dashboard" or "[No Name]")
            or vim.fn.fnamemodify(name, ":h:t") .. "/" .. vim.fn.fnamemodify(name, ":t")
        -- A percent in a filename must never become a statusline directive.
        label = label:gsub("%%", "%%%%") .. (vim.bo[buf].modified and "*" or "")
        parts[#parts + 1] = (i == current and "%#TabLineSel#" or "%#TabLine#")
            .. "%" .. i .. "T " .. i .. ". " .. label .. " "
        if i < last then parts[#parts + 1] = "|" end
    end
    parts[#parts + 1] = "%T%#TabLineFill#" .. (last < #tabs and " " .. (#tabs - last) .. ">" or "")
    return table.concat(parts)
end

function M.open(path)
    -- :tab drop selects the actual window, including a file shown in a split.
    local origin = vim.api.nvim_get_current_win()
    local existing, visible = {}, {}
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
        existing[tab] = true
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do visible[vim.api.nvim_win_get_buf(win)] = true end
    end
    local swap_seen = false
    local handler = vim.api.nvim_create_autocmd("SwapExists", { callback = function() swap_seen = true end })
    local ok, err = pcall(vim.cmd, "tab drop " .. vim.fn.fnameescape(path))
    vim.api.nvim_del_autocmd(handler)
    -- SwapExists handlers can also cancel silently, without raising E325.
    local cancelled = swap_seen and vim.api.nvim_get_current_buf() ~= vim.fn.bufnr(path)
    if ok and not cancelled then return true end
    -- Cancelling the native swap-file prompt is an ordinary aborted open, not a Lua error.
    if cancelled or tostring(err):find("E325:", 1, true) or tostring(err):find("E322:", 1, true) then
        for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
            if not existing[tab] then
                local disposable = true
                for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    local name = vim.api.nvim_buf_get_name(buf)
                    if not visible[buf] and (vim.bo[buf].modified
                        or (name ~= "" and name ~= vim.fn.fnamemodify(path, ":p"))) then disposable = false end
                end
                if disposable then vim.cmd(vim.api.nvim_tabpage_get_number(tab) .. "tabclose") end
            end
        end
        if vim.api.nvim_win_is_valid(origin) then vim.api.nvim_set_current_win(origin) end
        vim.notify("Opening cancelled: a swap file exists. Reopen to choose read-only access or recovery.", vim.log.levels.WARN)
        return false
    end
    vim.notify(tostring(err), vim.log.levels.ERROR)
    return false
end

function M.new()
    if vim.bo.filetype == "dashboard" or
        (vim.api.nvim_buf_get_name(0) == "" and not vim.bo.modified) then
        vim.cmd("enew")
    else
        vim.cmd("tablast | tabnew")
    end
end

function M.focus_buffer(buf)
    if not vim.api.nvim_buf_is_valid(buf) then
        vim.notify("This buffer was closed; reopen the file list", vim.log.levels.WARN)
        return false
    end
    -- Find the exact split/tab, including unnamed buffers and duplicate filenames.
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        if vim.api.nvim_win_get_config(win).relative == "" then
            local ok, err = pcall(vim.api.nvim_set_current_win, win)
            if not ok then vim.notify(tostring(err), vim.log.levels.ERROR) end
            return ok
        end
    end
    if not vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf) ~= "" then
        return M.open(vim.api.nvim_buf_get_name(buf))
    end
    local ok, err = pcall(vim.cmd, "tab sbuffer " .. buf)
    if not ok then vim.notify(tostring(err), vim.log.levels.ERROR) end
    return ok
end

function M.close(force)
    local tab = vim.api.nvim_get_current_tabpage()
    local buffers = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if not buffers[buf] and vim.bo[buf].modified then
            if not force then
                local choice = vim.fn.confirm("Save " .. (vim.fn.bufname(buf) ~= "" and vim.fn.bufname(buf) or "[No Name]") .. "?",
                    "&Save\n&Discard\n&Cancel", 3)
                if choice == 3 or choice == 0 then return end
                if choice == 1 then
                    local ok, err = require("config.safe-save").write_buffer(buf)
                    if not ok then vim.notify(err, vim.log.levels.ERROR); return end
                end
            end
        end
        buffers[buf] = vim.api.nvim_buf_get_changedtick(buf)
    end
    if not vim.api.nvim_tabpage_is_valid(tab) then return false end
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].modified and buffers[buf] ~= vim.api.nvim_buf_get_changedtick(buf) then
            vim.notify("Tab changed while confirming; close it again to review changes", vim.log.levels.WARN)
            return false
        end
    end
    local ok, err = pcall(function()
        vim.api.nvim_set_current_tabpage(tab)
        if #vim.api.nvim_list_tabpages() > 1 then
            vim.cmd(vim.api.nvim_tabpage_get_number(tab) .. "tabclose!")
        else
            vim.cmd("enew!")
            vim.cmd("Dashboard")
        end
    end)
    if not ok then vim.notify(tostring(err), vim.log.levels.ERROR); return false end
    -- Clean only buffers from this tab, never unrelated hidden unsaved work.
    for buf, tick in pairs(buffers) do
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "" and #vim.fn.win_findbuf(buf) == 0
            and (not vim.bo[buf].modified or vim.api.nvim_buf_get_changedtick(buf) == tick) then
            pcall(vim.api.nvim_buf_delete, buf, { force = true })
        end
    end
    return true
end

function M.close_saved()
    local tabs = vim.api.nvim_list_tabpages()
    for i = #tabs, 1, -1 do
        local clean = true
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabs[i])) do
            if vim.bo[vim.api.nvim_win_get_buf(win)].modified then clean = false end
        end
        if clean and #vim.api.nvim_list_tabpages() > 1 then
            vim.cmd(vim.api.nvim_tabpage_get_number(tabs[i]) .. "tabclose")
        end
    end
    if #vim.api.nvim_list_tabpages() == 1 then
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if vim.bo[vim.api.nvim_win_get_buf(win)].modified then return end
        end
        M.close(false)
    end
end

function M.move_tab_right() vim.cmd("+tabmove") end
function M.move_tab_left()
    if vim.fn.tabpagenr() > 1 then vim.cmd("-tabmove") end
end
function M.force_move_tab_last() vim.cmd("tabmove") end

function M.setup()
    vim.o.showtabline = 2
    vim.o.tabline = "%!v:lua.require'config.nvim-tabs'.render()"
    local group = vim.api.nvim_create_augroup("SmartTabMovement", { clear = true })
    vim.api.nvim_create_autocmd("BufModifiedSet", {
        group = group,
        callback = function(args)
            if not vim.bo[args.buf].modified or vim.g.nvim_ide_move_modified_tabs == false then return end
            local tab = vim.api.nvim_get_current_tabpage()
            -- One scheduled callback when a buffer becomes dirty, not a timer per keystroke.
            vim.schedule(function()
                if vim.api.nvim_get_current_tabpage() ~= tab then return end
                if #vim.api.nvim_list_tabpages() - vim.fn.tabpagenr() >= 3 then vim.cmd("tabmove") end
            end)
        end,
    })
    vim.api.nvim_create_user_command("Q", function(opts) M.close(opts.bang) end,
        { bang = true, desc = "Close tab and return to dashboard" })
    vim.api.nvim_create_user_command("CloseSavedTabs", M.close_saved, { desc = "Close saved tabs" })
end

return M
