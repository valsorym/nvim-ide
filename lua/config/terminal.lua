-- Native terminal buffers, reused by project and task without an extra plugin.
local M = {}
local terminals = {}
local function open(key, argv, direction)
    local cwd = vim.fn.getcwd()
    key = cwd .. ":" .. key
    local item = terminals[key]
    if item and item.win and vim.api.nvim_win_is_valid(item.win) then
        vim.api.nvim_win_close(item.win, true)
        item.win = nil
        return
    end
    if not item or not vim.api.nvim_buf_is_valid(item.buf) then
        item = { buf = vim.api.nvim_create_buf(false, true) }
        terminals[key] = item
    end
    if direction == "horizontal" then
        vim.cmd("botright " .. math.max(3, math.floor(vim.o.lines * 0.3)) .. "split")
        item.win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(item.win, item.buf)
    elseif direction == "vertical" then
        vim.cmd("botright vsplit")
        item.win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(item.win, item.buf)
    else
        local width, height = math.max(1, math.floor(vim.o.columns * 0.85)), math.max(1, math.floor(vim.o.lines * 0.7))
        item.win = vim.api.nvim_open_win(item.buf, true, {
            relative = "editor", width = width, height = height,
            row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
            col = math.max(0, math.floor((vim.o.columns - width) / 2)),
            style = "minimal", border = "rounded", title = " Terminal ",
        })
    end
    vim.wo[item.win].number = false
    vim.wo[item.win].relativenumber = false
    vim.wo[item.win].signcolumn = "no"
    if not item.job then
        item.job = vim.fn.jobstart(argv, {
            term = true, cwd = cwd,
            on_exit = function(_, code)
                item.job = nil
                vim.schedule(function()
                    if terminals[key] == item then
                        -- Leave finished output visible; a new invocation starts a fresh job.
                        terminals[key] = nil
                    end
                    if code ~= 0 then vim.notify("Terminal exited with status " .. code, vim.log.levels.WARN) end
                end)
            end,
        })
        if item.job <= 0 then
            item.job = nil
            vim.notify("Could not start terminal", vim.log.levels.ERROR)
            return
        end
        vim.bo[item.buf].bufhidden = "hide"
    end
    vim.cmd("startinsert")
end
function M.toggle(direction) open(direction, { vim.o.shell }, direction) end
function M.run(task)
    local python = require("config.python-venv").python()
    local commands = {
        python = { python }, node = { "node" },
        django = { python, "manage.py", "shell" },
        runserver = { python, "manage.py", "runserver" },
    }
    open(task, commands[task], task == "runserver" and "horizontal" or "float")
end
return M
