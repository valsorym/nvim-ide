-- ~/.config/nvim/lua/config/contextual-buffers.lua
-- Simple buffer picker without tab grouping

local M = {}

-- Simple buffer picker
function M.show()
    local telescope = require("telescope")
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    -- Get all buffers
    local all_buffers = vim.api.nvim_list_bufs()
    local buffer_entries = {}

    for _, buf in ipairs(all_buffers) do
        -- Skip invalid and hidden buffers
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
            local bufname = vim.api.nvim_buf_get_name(buf)
            local filename = vim.fn.fnamemodify(bufname, ":t")

            -- Skip empty names and special buffers
            if filename ~= "" and
               not bufname:match("NvimTree") and
               not bufname:match("dashboard") and
               not bufname:match("toggleterm") then

                local is_modified = vim.bo[buf].modified
                local display_name = filename .. (is_modified and " [+]" or "")

                -- Add directory context for same-named files
                local dirname = vim.fn.fnamemodify(bufname, ":h:t")
                if dirname ~= "." and dirname ~= "" then
                    display_name = display_name .. " (" .. dirname .. ")"
                end

                table.insert(buffer_entries, {
                    bufnr = buf,
                    filename = bufname,
                    display = display_name,
                    ordinal = filename,
                })
            end
        end
    end

    if #buffer_entries == 0 then
        vim.notify("No buffers found", vim.log.levels.INFO)
        return
    end

    -- Sort by filename
    table.sort(buffer_entries, function(a, b)
        return a.ordinal < b.ordinal
    end)

    pickers.new({}, {
        prompt_title = "Buffers (" .. #buffer_entries .. ")",
        finder = finders.new_table({
            results = buffer_entries,
            entry_maker = function(entry)
                return {
                    value = entry.bufnr,
                    display = entry.display,
                    ordinal = entry.ordinal,
                    bufnr = entry.bufnr,
                    filename = entry.filename,
                }
            end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
            local function select_buffer()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)

                if selection and selection.bufnr then
                    -- Standard vim behavior - switch to buffer in current window
                    vim.api.nvim_set_current_buf(selection.bufnr)
                end
            end

            local function select_buffer_tab()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)

                if selection and selection.bufnr then
                    -- Open in new tab
                    vim.cmd("tabnew")
                    vim.api.nvim_set_current_buf(selection.bufnr)
                end
            end

            local function delete_buffer()
                local selection = action_state.get_selected_entry()
                if selection and selection.bufnr then
                    vim.api.nvim_buf_delete(selection.bufnr, {})
                    -- Refresh the picker
                    actions.close(prompt_bufnr)
                    vim.defer_fn(M.show, 100)
                end
            end

            map("i", "<CR>", select_buffer)
            map("n", "<CR>", select_buffer)
            map("i", "<C-t>", select_buffer_tab)
            map("n", "<C-t>", select_buffer_tab)
            map("i", "<C-d>", delete_buffer)
            map("n", "<C-d>", delete_buffer)
            map("i", "<C-x>", delete_buffer)  -- Alternative delete key
            map("n", "<C-x>", delete_buffer)

            return true
        end,
    }):find()
end

return M