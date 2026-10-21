-- Shared Telescope selector; callbacks run exactly once, including cancellation.
local M = {}
function M.select(items, opts, on_choice)
    opts = opts or {}
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")
    local conf = require("telescope.config").values
    local finished = false
    local function finish(item, index)
        if finished then return end
        finished = true
        vim.schedule(function() on_choice(item, index) end)
    end
    require("telescope.pickers").new(require("telescope.themes").get_dropdown({
        layout_config = { width = 0.8, height = 0.6 },
    }), {
        prompt_title = opts.prompt or "Select",
        get_status_text = function(picker, status_opts)
            return conf.get_status_text(picker, status_opts) .. " "
        end,
        finder = require("telescope.finders").new_table({
            results = items,
            entry_maker = function(item)
                local display = opts.format_item and opts.format_item(item) or tostring(item)
                return { value = item, display = display, ordinal = display }
            end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(buf)
            actions.select_default:replace(function()
                local entry = state.get_selected_entry()
                if entry then finish(entry.value, entry.index) else finish(nil, nil) end
                actions.close(buf)
            end)
            vim.api.nvim_create_autocmd("BufWipeout", {
                buffer = buf, once = true,
                callback = function() finish(nil, nil) end,
            })
            return true
        end,
    }):find()
end
return M
