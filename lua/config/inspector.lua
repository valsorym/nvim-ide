-- Symbol requests are asynchronous and use Neovim's UTF-16/UTF-8 conversion.
local M = {}
function M.show(grouped)
    local buf = vim.api.nvim_get_current_buf()
    if require("config.performance").is_large(buf) then
        vim.notify("Symbol parsing is disabled for large files", vim.log.levels.WARN)
        return
    end
    local function pick(items)
        local conf = require("telescope.config").values
        require("telescope.pickers").new({}, {
            prompt_title = "Document symbols",
            finder = require("telescope.finders").new_table({ results = items,
                entry_maker = require("telescope.make_entry").gen_from_lsp_symbols({}) }),
            sorter = conf.generic_sorter({}), previewer = conf.qflist_previewer({}),
            attach_mappings = function()
                require("telescope.actions").select_default:replace(function(prompt)
                    require("telescope.actions").select_tab_drop(prompt)
                end)
                return true
            end,
        }):find()
    end
    vim.lsp.buf.document_symbol({ on_list = function(result)
        if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_get_current_buf() ~= buf then return end
        if not grouped then pick(result.items); return end
        local groups = {}
        for _, item in ipairs(result.items) do
            local kind = item.kind or "Symbol"
            groups[kind] = groups[kind] or {}
            groups[kind][#groups[kind] + 1] = item
        end
        local kinds = vim.tbl_keys(groups)
        table.sort(kinds)
        vim.ui.select(kinds, { prompt = "Symbol kinds", format_item = function(kind)
            return kind .. " (" .. #groups[kind] .. ")"
        end }, function(kind) if kind then pick(groups[kind]) end end)
    end })
end
return M
