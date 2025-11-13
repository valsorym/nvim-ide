-- ~/.config/nvim/lua/config/python-venv.lua
-- Python virtual environment auto-detection and management

local M = {}

-- Default configuration
local config = {
    -- Enable auto-activation on directory change
    auto_activate = true,
    -- Show notifications when venv is activated/deactivated
    notify = true,
    -- Search paths for virtual environments (relative to project root)
    venv_names = {".venv", "venv", "env", ".env"},
    -- Max levels to search up for venv
    search_levels = 3,
    -- Auto-activate only for Python files
    python_files_only = false,
}

-- Utility functions
local function dir_exists(path)
    return vim.fn.isdirectory(path) == 1
end

local function file_exists(path)
    return vim.fn.filereadable(path) == 1
end

local function is_python_project()
    local cwd = vim.fn.getcwd()
    local python_indicators = {
        "requirements.txt",
        "pyproject.toml",
        "setup.py",
        "setup.cfg",
        "Pipfile",
        "manage.py",  -- Django
        "app.py",     -- Flask
        "main.py",
    }

    for _, indicator in ipairs(python_indicators) do
        if file_exists(cwd .. "/" .. indicator) then
            return true
        end
    end

    return false
end

local function notify(message, level)
    if config.notify then
        vim.notify(message, level or vim.log.levels.INFO, {
            title = "Python Venv",
            timeout = 2000,
        })
    end
end

-- Get current virtual environment info
function M.get_current_venv()
    local venv_path = vim.env.VIRTUAL_ENV
    if venv_path then
        return {
            path = venv_path,
            name = vim.fn.fnamemodify(venv_path, ":t"),
            python = vim.g.python3_host_prog,
        }
    end
    return nil
end

-- Check if we're in a Python file
function M.is_python_buffer()
    local ft = vim.bo.filetype
    return ft == "python" or ft == "django" or ft == "htmldjango"
end

-- Find virtual environment in directory tree
function M.find_venv(start_path)
    start_path = start_path or vim.fn.getcwd()

    local function search_dir(dir_path, level)
        if level > config.search_levels then
            return nil
        end

        for _, venv_name in ipairs(config.venv_names) do
            local venv_path = dir_path .. "/" .. venv_name
            local python_path = venv_path .. "/bin/python"

            if dir_exists(venv_path) and file_exists(python_path) then
                return {
                    path = venv_path,
                    name = venv_name,
                    python = python_path,
                    project_root = dir_path,
                }
            end
        end

        -- Search parent directory
        local parent = vim.fn.fnamemodify(dir_path, ":h")
        if parent ~= dir_path and parent ~= "/" then
            return search_dir(parent, level + 1)
        end

        return nil
    end

    return search_dir(start_path, 0)
end

-- Activate virtual environment
function M.activate(venv_info)
    if not venv_info then
        return false, "No virtual environment provided"
    end

    -- Deactivate current venv first
    M.deactivate(true)

    -- Set environment variables
    vim.env.VIRTUAL_ENV = venv_info.path
    vim.env.PATH = venv_info.path .. "/bin:" .. vim.env.PATH
    vim.g.python3_host_prog = venv_info.python

    -- Store original PATH for deactivation
    if not vim.env.ORIGINAL_PATH then
        vim.env.ORIGINAL_PATH = vim.env.PATH:gsub(venv_info.path .. "/bin:", "")
    end

    notify("Activated: " .. venv_info.name .. " (" .. venv_info.project_root .. ")")

    -- Trigger autocmd for other plugins
    vim.api.nvim_exec_autocmds("User", {
        pattern = "PythonVenvActivated",
        data = venv_info,
    })

    return true, "Virtual environment activated"
end

-- Deactivate virtual environment
function M.deactivate(silent)
    local current = M.get_current_venv()
    if not current then
        if not silent then
            notify("No active virtual environment", vim.log.levels.WARN)
        end
        return false
    end

    -- Restore original PATH
    if vim.env.ORIGINAL_PATH then
        vim.env.PATH = vim.env.ORIGINAL_PATH
        vim.env.ORIGINAL_PATH = nil
    else
        -- Fallback: remove venv bin from PATH
        local venv_bin = current.path .. "/bin"
        vim.env.PATH = vim.env.PATH:gsub(venv_bin .. ":", "")
    end

    vim.env.VIRTUAL_ENV = nil
    vim.g.python3_host_prog = nil

    if not silent then
        notify("Deactivated: " .. current.name)
    end

    -- Trigger autocmd
    vim.api.nvim_exec_autocmds("User", {
        pattern = "PythonVenvDeactivated",
        data = current,
    })

    return true
end

-- Auto-activate virtual environment
function M.auto_activate()
    -- Skip if auto-activation is disabled
    if not config.auto_activate then
        return
    end

    -- Skip if python_files_only is true and we're not in a Python buffer
    if config.python_files_only and not M.is_python_buffer() then
        return
    end

    -- Skip if not a Python project (unless we're in a Python buffer)
    if not M.is_python_buffer() and not is_python_project() then
        return
    end

    local current_venv = M.get_current_venv()
    local found_venv = M.find_venv()

    if not found_venv then
        -- No venv found, deactivate current if any
        if current_venv then
            M.deactivate(true)
        end
        return
    end

    -- Don't reactivate if already using the correct venv
    if current_venv and current_venv.path == found_venv.path then
        return
    end

    -- Activate the found venv
    M.activate(found_venv)
end

-- Show virtual environment status
function M.status()
    local current = M.get_current_venv()
    if current then
        local message = string.format(
            "Active: %s\nPath: %s\nPython: %s",
            current.name,
            current.path,
            current.python or "Not set"
        )
        notify(message, vim.log.levels.INFO)
    else
        notify("No active virtual environment", vim.log.levels.INFO)
    end
end

-- Setup function
function M.setup(opts)
    -- Merge user config with defaults
    config = vim.tbl_deep_extend("force", config, opts or {})

    -- Create autocmd group
    local augroup = vim.api.nvim_create_augroup("PythonVenv", { clear = true })

    -- Auto-activate on relevant events
    vim.api.nvim_create_autocmd({"VimEnter", "DirChanged"}, {
        group = augroup,
        callback = function()
            -- Small delay to ensure directory is fully changed
            vim.defer_fn(M.auto_activate, 100)
        end,
    })

    -- Auto-activate when opening Python files
    vim.api.nvim_create_autocmd("FileType", {
        group = augroup,
        pattern = {"python", "django", "htmldjango"},
        callback = function()
            vim.defer_fn(M.auto_activate, 50)
        end,
    })

    -- Create user commands
    vim.api.nvim_create_user_command("VenvActivate", function()
        M.auto_activate()
    end, { desc = "Auto-activate local Python virtual environment" })

    vim.api.nvim_create_user_command("VenvDeactivate", function()
        M.deactivate()
    end, { desc = "Deactivate Python virtual environment" })

    vim.api.nvim_create_user_command("VenvStatus", function()
        M.status()
    end, { desc = "Show Python virtual environment status" })

    vim.api.nvim_create_user_command("VenvFind", function()
        local venv = M.find_venv()
        if venv then
            notify(string.format("Found: %s at %s", venv.name, venv.project_root))
        else
            notify("No virtual environment found", vim.log.levels.WARN)
        end
    end, { desc = "Find virtual environment in current directory tree" })

    -- Set up keymaps if they don't exist
    local function safe_keymap(mode, lhs, rhs, opts)
        local existing = vim.fn.maparg(lhs, mode)
        if existing == "" then
            vim.keymap.set(mode, lhs, rhs, opts)
        end
    end

    -- Optional keymaps (only set if not already mapped)
    safe_keymap("n", "<leader>cva", M.auto_activate, { desc = "Activate Python venv" })
    safe_keymap("n", "<leader>cvd", M.deactivate, { desc = "Deactivate Python venv" })
    safe_keymap("n", "<leader>cvs", M.status, { desc = "Venv status" })
end

return M