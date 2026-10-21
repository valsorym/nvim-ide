-- Literal project replacement from reviewed search results, kept in undoable buffers.
local M = {}

function M.apply(entries, search, replacement, cwd)
    if search == "" then return { changed = 0, skipped = 0 } end
    local files = {}
    for _, entry in ipairs(entries) do
        local path = vim.fs.normalize((entry.filename:sub(1, 1) == "/" and "" or cwd .. "/") .. entry.filename)
        files[path] = files[path] or {}
        files[path][entry.lnum] = entry.text
    end
    local result = { changed = 0, skipped = 0 }
    for path, matches in pairs(files) do
        local buf = vim.fn.bufadd(path)
        vim.fn.bufload(buf)
        if vim.bo[buf].modified or vim.bo[buf].readonly or not vim.bo[buf].modifiable
            or require("config.performance").is_large(buf) then
            result.skipped = result.skipped + 1
        else
            local updates = {}
            for row, expected in pairs(matches) do
                local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
                -- The file may have changed on disk while the picker was open.
                if line == expected then
                    local text, count = line:gsub(vim.pesc(search), function() return replacement end)
                    if count > 0 then updates[#updates + 1] = { row = row, text = text } end
                else result.skipped = result.skipped + 1 end
            end
            table.sort(updates, function(a, b) return a.row < b.row end)
            for i, update in ipairs(updates) do
                vim.api.nvim_buf_call(buf, function()
                    if i > 1 then vim.cmd("undojoin") end
                    vim.api.nvim_buf_set_lines(buf, update.row - 1, update.row, false, { update.text })
                end)
            end
            if #updates > 0 then result.changed = result.changed + 1 end
        end
    end
    return result
end

function M.search(ignored, initial)
    local cwd = vim.fn.getcwd()
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")
    local args = { "--fixed-strings", "--case-sensitive", "--hidden", "--glob", "!.git/**" }
    if ignored then args[#args + 1] = "--no-ignore" end
    require("telescope.builtin").live_grep({
        file_ignore_patterns = ignored and {} or nil,
        cwd = cwd, default_text = initial or "", additional_args = args,
        prompt_title = "Literal replace • Ctrl-R to review replacement",
        attach_mappings = function(prompt_buf, map)
            local function replace()
                local picker = state.get_current_picker(prompt_buf)
                local query = picker:_get_prompt()
                if query == "" or not picker.manager then return end
                local entries = picker:get_multi_selection()
                if #entries == 0 then
                    for entry in picker.manager:iter() do entries[#entries + 1] = entry end
                end
                if #entries == 0 then return end
                actions.close(prompt_buf)
                vim.schedule(function()
                    vim.ui.input({ prompt = "Replace literal '" .. query .. "' with: " }, function(replacement)
                        if replacement == nil then return end
                        vim.ui.select({ "Replace in buffers", "Cancel" }, { prompt = "Replace matches on " .. #entries .. " lines?" }, function(choice)
                            if choice ~= "Replace in buffers" then return end
                            local result = M.apply(entries, query, replacement, cwd)
                            vim.notify(string.format("Changed %d files; skipped %d buffers/lines. Review with :ls, save with :wall.", result.changed, result.skipped))
                        end)
                    end)
                end)
            end
            map("i", "<C-r>", replace)
            map("n", "r", replace)
            return true
        end,
    })
end
function M.word() M.search(false, vim.fn.expand("<cword>")) end
return M
