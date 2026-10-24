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
        layout_config = opts.layout_config or { width = 0.8, height = 0.6 },
    }), {
        prompt_title = opts.prompt or "Select",
        selection_caret = opts.selection_caret,
        entry_prefix = opts.entry_prefix,
        get_status_text = function(picker, status_opts)
            return conf.get_status_text(picker, status_opts) .. " "
        end,
        finder = require("telescope.finders").new_table({
            results = items,
            entry_maker = function(item)
                local display, highlights
                if opts.format_item then display, highlights = opts.format_item(item)
                else display = tostring(item) end
                return { value = item, display = function() return display, highlights end,
                    ordinal = opts.ordinal and opts.ordinal(item) or display }
            end,
        }),
        sorter = opts.sorter or conf.generic_sorter({}),
        attach_mappings = function(buf, map)
            if opts.close_on_q then map("n", "q", actions.close) end
            actions.select_default:replace(function()
                local entry = state.get_selected_entry()
                local item, index = entry and entry.value, entry and entry.index
                if opts.resolve_choice then
                    item, index = opts.resolve_choice(state.get_current_picker(buf):_get_prompt(), item, index)
                end
                finish(item, index)
                actions.close(buf)
            end)
            vim.api.nvim_create_autocmd("BufWipeout", {
                buffer = buf, once = true,
                callback = function() finish(nil, nil) end,
            })
            if opts.on_open then opts.on_open(state.get_current_picker(buf), buf) end
            return true
        end,
    }):find()
end
return M
