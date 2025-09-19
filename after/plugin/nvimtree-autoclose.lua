-- ~/.config/nvim/after/plugin/nvim-tree-autoclose.lua
-- Close tab if it contains only NvimTree or NvimTree + empty [No Name].

local function should_close_tab(buflist)
    local real_files = 0
    local tree_windows = 0
    local empty_buffers = 0

    for _, bufnr in ipairs(buflist) do
        local bufname = vim.fn.bufname(bufnr)

        if bufname:match("NvimTree_") then
            tree_windows = tree_windows + 1
        elseif bufname == "" then
            -- empty buffer - check if it's modified
            if vim.bo[bufnr].modified then
                real_files = real_files + 1 -- modified empty buffer counts as real
            else
                empty_buffers = empty_buffers + 1 -- clean empty buffer
            end
        else
            real_files = real_files + 1 -- normal file
        end
    end

    -- Close tab if only tree, or tree + clean empty buffers.
    return tree_windows > 0 and real_files == 0
end

local function handle_last_tab_cleanup()
    local total_tabs = vim.fn.tabpagenr("$")
    local current_tab = vim.fn.tabpagenr()
    local buflist = vim.fn.tabpagebuflist(current_tab)

    -- If this is the last tab and should be closed.
    if total_tabs == 1 and should_close_tab(buflist) then
        -- Close NvimTree first.
        local api = require("nvim-tree.api")
        if api.tree.is_visible() then
            api.tree.close()
        end

        -- Create new empty buffer.
        vim.cmd("enew")
        return true
    end

    return false
end

local function close_empty_tabs()
    local total_tabs = vim.fn.tabpagenr("$")

    -- Handle last tab special case.
    if handle_last_tab_cleanup() then
        return
    end

    -- Close empty tabs (but not the last one).
    if total_tabs <= 1 then
        return
    end

    for tab_nr = total_tabs, 1, -1 do
        local buflist = vim.fn.tabpagebuflist(tab_nr)
        if should_close_tab(buflist) then
            vim.cmd(tab_nr .. "tabclose")
        end
    end
end

-- Create autocmd group for better management.
local autoclose_group = vim.api.nvim_create_augroup("NvimTreeAutoclose", {clear = true})

-- Main trigger - after buffer operations.
vim.api.nvim_create_autocmd(
    {"BufDelete", "BufWipeout", "BufUnload"},
    {
        group = autoclose_group,
        callback = function()
            -- Delay to let vim finish buffer operations.
            vim.defer_fn(close_empty_tabs, 100)
        end
    }
)

-- Trigger when window is closed.
vim.api.nvim_create_autocmd(
    "WinClosed",
    {
        group = autoclose_group,
        callback = function()
            vim.defer_fn(close_empty_tabs, 50)
        end
    }
)

-- Trigger for tab operations.
vim.api.nvim_create_autocmd(
    {"TabEnter", "TabClosed"},
    {
        group = autoclose_group,
        callback = function()
            vim.defer_fn(close_empty_tabs, 50)
        end
    }
)
