-- Enhanced lua/utils/tabopen.lua
-- Unified function to always open files in new/existing tabs.

local M = {}

-- Main function to open files in tabs with consistent behavior
function M.open(file_path, line, col)
    if not file_path or file_path == "" then
        return false
    end

    -- Normalize to absolute path for reliable comparison
    local abs_path = vim.fn.fnamemodify(file_path, ":p")
    if abs_path == "" then
        return false
    end

    local target_tab = nil
    local current_tab = vim.fn.tabpagenr()

    -- Search if file already open in some tab
    for tab_nr = 1, vim.fn.tabpagenr("$") do
        local buflist = vim.fn.tabpagebuflist(tab_nr)
        for _, buf_nr in ipairs(buflist) do
            local buf_name = vim.fn.bufname(buf_nr)
            if buf_name ~= "" then
                local buf_abs_path = vim.fn.fnamemodify(buf_name, ":p")
                if buf_abs_path == abs_path then
                    target_tab = tab_nr
                    break
                end
            end
        end
        if target_tab then break end
    end

    if target_tab then
        -- File already open → switch to that tab
        vim.cmd(target_tab .. "tabnext")

        -- Jump to specific location if provided
        if line and line > 0 then
            vim.defer_fn(function()
                pcall(vim.api.nvim_win_set_cursor, 0, {line, col or 0})
                vim.cmd("normal! zz")
            end, 10)
        end

        vim.notify("Switched to existing tab: " .. vim.fn.fnamemodify(abs_path, ":t"), vim.log.levels.INFO)
    else
        -- File not open → decide whether to reuse current tab or create new
        local current_buf = vim.api.nvim_get_current_buf()
        local current_bufname = vim.fn.bufname(current_buf)
        local current_filetype = vim.bo[current_buf].filetype
        local current_modified = vim.bo[current_buf].modified

        -- Check if current tab can be reused (dashboard or empty unmodified buffer)
        local can_reuse = false
        if current_filetype == "dashboard" then
            can_reuse = true
        elseif current_bufname == "" and not current_modified then
            can_reuse = true
        end

        if can_reuse then
            -- Reuse current tab
            vim.cmd("edit " .. vim.fn.fnameescape(file_path))
            vim.notify("Opened in current tab: " .. vim.fn.fnamemodify(abs_path, ":t"), vim.log.levels.INFO)
        else
            -- Create new tab
            vim.cmd("tabnew " .. vim.fn.fnameescape(file_path))
            vim.notify("Opened in new tab: " .. vim.fn.fnamemodify(abs_path, ":t"), vim.log.levels.INFO)
        end

        -- Jump to specific location if provided
        if line and line > 0 then
            vim.defer_fn(function()
                pcall(vim.api.nvim_win_set_cursor, 0, {line, col or 0})
                vim.cmd("normal! zz")
            end, 10)
        end
    end

    return true
end

-- Enhanced helper function for Telescope entries
function M.open_telescope_entry(entry)
    if not entry then return false end

    -- Handle different types of telescope entries
    local file_path = nil
    local line = nil
    local col = nil

    -- For live_grep results
    if entry.filename then
        file_path = entry.filename
        line = entry.lnum
        col = entry.col
    -- For file finder results
    elseif entry.value then
        file_path = entry.value
        line = entry.lnum
        col = entry.col
    -- For buffer results
    elseif entry.bufnr then
        file_path = vim.api.nvim_buf_get_name(entry.bufnr)
        line = entry.lnum
        col = entry.col
    -- Fallback for array-style entries
    elseif entry[1] then
        file_path = entry[1]
        line = entry.lnum
        col = entry.col
    end

    if not file_path then
        vim.notify("Could not determine file path from telescope entry", vim.log.levels.WARN)
        return false
    end

    return M.open(file_path, line, col)
end

-- Helper function for LSP locations
function M.open_lsp_location(location)
    if not location then return false end

    local file_path = location.filename or location.uri
    if file_path and file_path:match("^file://") then
        file_path = vim.uri_to_fname(file_path)
    end

    local line = location.lnum or (location.range and location.range.start.line + 1)
    local col = location.col or (location.range and location.range.start.character)

    return M.open(file_path, line, col)
end

-- Debug function to check current state
function M.debug()
    local current_tab = vim.fn.tabpagenr()
    local total_tabs = vim.fn.tabpagenr("$")
    local current_buf = vim.api.nvim_get_current_buf()
    local current_file = vim.fn.bufname(current_buf)

    print("=== Tab Open Debug ===")
    print("Current tab: " .. current_tab .. "/" .. total_tabs)
    print("Current file: " .. (current_file ~= "" and current_file or "[No Name]"))
    print("Filetype: " .. vim.bo[current_buf].filetype)
    print("Modified: " .. tostring(vim.bo[current_buf].modified))

    -- List all tabs and their files
    for tab_nr = 1, total_tabs do
        local buflist = vim.fn.tabpagebuflist(tab_nr)
        local main_buf = buflist[vim.fn.tabpagewinnr(tab_nr)]
        local tab_file = vim.fn.bufname(main_buf)
        local tab_name = tab_file ~= "" and vim.fn.fnamemodify(tab_file, ":t") or "[No Name]"
        local marker = tab_nr == current_tab and " <-- CURRENT" or ""
        print("Tab " .. tab_nr .. ": " .. tab_name .. marker)
    end
end

return M