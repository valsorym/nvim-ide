-- Literal project replacement from reviewed search results, kept in undoable buffers.
local M = {}
vim.api.nvim_create_autocmd("BufWinEnter", {
    group = vim.api.nvim_create_augroup("ReplacementBuffers", { clear = true }),
    callback = function(args)
        if vim.b[args.buf].nvim_ide_deferred_read then
            vim.b[args.buf].nvim_ide_deferred_read = nil
            -- Run normal read hooks once the result is actually opened; no disk reload.
            vim.api.nvim_exec_autocmds("BufReadPost", { buffer = args.buf, modeline = false })
        end
    end,
})

function M.apply(entries, search, replacement, cwd)
    if search == "" then return { changed = 0, skipped = 0, swap_skipped = 0, errors = {} } end
    local files = {}
    for _, entry in ipairs(entries) do
        local path = vim.fs.normalize((entry.filename:sub(1, 1) == "/" and "" or cwd .. "/") .. entry.filename)
        files[path] = files[path] or {}
        files[path][entry.lnum] = entry.text
    end
    local result = { changed = 0, skipped = 0, swap_skipped = 0, errors = {} }
    local swap = require("config.swap").guard()
    for path, matches in pairs(files) do
        if swap(path) then
            result.skipped = result.skipped + 1
            result.swap_skipped = result.swap_skipped + 1
        else
            local buf, editing, counted
            local ok, err = pcall(function()
                buf = vim.fn.bufadd(path)
                if not vim.api.nvim_buf_is_loaded(buf) then
                    assert(vim.fn.filereadable(path) == 1, "File is no longer readable")
                    -- Search-only buffers must not start language clients for every result file.
                    local previous = vim.o.eventignore
                    vim.o.eventignore = "all"
                    local ok, err = pcall(vim.fn.bufload, buf)
                    vim.o.eventignore = previous
                    if not ok then error(err) end
                    vim.b[buf].nvim_ide_deferred_read = true
                    require("config.performance").check(buf)
                end
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
                    -- List the buffer before editing: even an interrupted batch stays discoverable.
                    if #updates > 0 then vim.bo[buf].buflisted = true; editing = true end
                    for i, update in ipairs(updates) do
                        vim.api.nvim_buf_call(buf, function()
                            if i > 1 then vim.cmd("undojoin") end
                            vim.api.nvim_buf_set_lines(buf, update.row - 1, update.row, false, { update.text })
                        end)
                    end
                    if #updates > 0 then
                        vim.bo[buf].buflisted = true
                        result.changed = result.changed + 1
                        counted = true
                    end
                end
            end)
            if not ok then
                if editing and not counted and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modified then
                    result.changed = result.changed + 1
                end
                result.skipped = result.skipped + 1
                result.errors[#result.errors + 1] = path .. ": " .. tostring(err)
            end
        end
    end
    return result
end

function M.search(ignored, initial)
    local cwd = vim.fn.getcwd()
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")
    local args = { "--fixed-strings", "--case-sensitive" }
    require("telescope.builtin").live_grep({
        vimgrep_arguments = require("config.search").grep_args(ignored),
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
                            vim.notify(string.format("Changed %d files; skipped %d buffers/lines (%d files with swap). Review with :ls or Space bl, save with :wall.", result.changed, result.skipped, result.swap_skipped))
                            if #result.errors > 0 then vim.notify(table.concat(result.errors, "\n"), vim.log.levels.ERROR) end
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
