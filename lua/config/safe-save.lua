-- ~/.config/nvim/lua/config/safe-save.lua
-- Safe save with formatting support

local M = {}

-- Smart write function that handles different file types appropriately
function M.smart_write()
    local ft = vim.bo.filetype
    local bufname = vim.api.nvim_buf_get_name(0)

    -- Skip formatting for specific filetypes that shouldn't be auto-formatted
    local no_format_filetypes = {
        "htmldjango",
        "html",
        "markdown",
        "text",
        "gitcommit",
        "gitrebase",
    }

    -- Check if current filetype should skip formatting
    local should_skip_format = false
    for _, skip_ft in ipairs(no_format_filetypes) do
        if ft == skip_ft then
            should_skip_format = true
            break
        end
    end

    -- Check if autoformat is disabled globally or for buffer
    if vim.g.format_on_save == false or vim.b.autoformat == false then
        should_skip_format = true
    end

    -- Save without formatting if needed
    if should_skip_format then
        vim.cmd("silent! write")
        vim.notify("💾 Saved (no format)", vim.log.levels.INFO)
        return
    end

    -- Try to format with LSP first, then fallback to manual tools
    local formatted = false

    -- Try LSP formatting
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    for _, client in pairs(clients) do
        if client.supports_method("textDocument/formatting") then
            vim.lsp.buf.format({
                async = false,
                filter = function(c) return c.id == client.id end
            })
            formatted = true
            break
        end
    end

    -- Manual formatting for specific file types if LSP didn't handle it
    if not formatted then
        if ft == "python" then
            -- Python: try isort + black
            local success = M.format_python_file()
            if success then
                formatted = true
            end
        elseif ft == "lua" and vim.fn.executable("stylua") == 1 then
            -- Lua: stylua
            local cursor_pos = vim.api.nvim_win_get_cursor(0)
            vim.fn.system({"stylua", "--column-width", "79", bufname})
            if vim.v.shell_error == 0 then
                vim.cmd("silent! edit!")
                pcall(vim.api.nvim_win_set_cursor, 0, cursor_pos)
                formatted = true
            end
        elseif (ft == "javascript" or ft == "typescript" or ft == "json")
            and vim.fn.executable("prettier") == 1 then
            -- JS/TS: prettier
            local cursor_pos = vim.api.nvim_win_get_cursor(0)
            vim.fn.system({"prettier", "--write", "--print-width", "79", bufname})
            if vim.v.shell_error == 0 then
                vim.cmd("silent! edit!")
                pcall(vim.api.nvim_win_set_cursor, 0, cursor_pos)
                formatted = true
            end
        end
    end

    -- Save the file
    vim.cmd("silent! write")

    -- Show appropriate notification
    if formatted then
        vim.notify("💾 Saved and formatted", vim.log.levels.INFO)
    else
        vim.notify("💾 Saved", vim.log.levels.INFO)
    end
end

-- Format Python file with isort + black
function M.format_python_file()
    local function get_python_executable()
        local venv = vim.fn.getenv("VIRTUAL_ENV")
        if venv ~= vim.NIL and venv ~= "" then
            return venv .. "/bin/python"
        end
        if vim.fn.isdirectory(".venv") == 1 then
            return vim.fn.getcwd() .. "/.venv/bin/python"
        end
        if vim.fn.isdirectory("venv") == 1 then
            return vim.fn.getcwd() .. "/venv/bin/python"
        end
        return "python3"
    end

    local py = get_python_executable()
    local current_file = vim.fn.expand("%:p")
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local success = false

    -- Step 1: isort
    local isort_exe = py:gsub("/python$", "/isort")
    local isort_cmd = vim.fn.executable(isort_exe) == 1 and isort_exe or "isort"

    if vim.fn.executable(isort_cmd) == 1 then
        vim.fn.system({
            isort_cmd, "--profile", "black", "--line-length", "79",
            "--multi-line", "3", "--trailing-comma", current_file
        })
        if vim.v.shell_error == 0 then
            success = true
        end
    end

    -- Step 2: black
    local black_exe = py:gsub("/python$", "/black")
    local black_cmd = vim.fn.executable(black_exe) == 1 and black_exe or "black"

    if vim.fn.executable(black_cmd) == 1 then
        local result = vim.fn.system({
            black_cmd, "--line-length", "79", "--skip-string-normalization",
            current_file
        })
        if vim.v.shell_error == 0 then
            vim.cmd("silent! edit!")
            pcall(vim.api.nvim_win_set_cursor, 0, cursor_pos)
            success = true
        else
            -- Handle syntax errors
            if result:match("Cannot parse") or result:match("SyntaxError") then
                local line_number = result:match(": (%d+):")
                if line_number then
                    vim.notify("❌ Syntax error on line " .. line_number,
                        vim.log.levels.ERROR)
                    pcall(vim.api.nvim_win_set_cursor, 0,
                        {tonumber(line_number), 0})
                end
            end
        end
    end

    return success
end

return M