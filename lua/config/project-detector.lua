-- ~/.config/nvim/lua/config/project-detector.lua
-- Automatic project detection and session management

local M = {}

function M.setup()
    -- Project markers (like VSCode looks for these files)
    local project_markers = {
        ".git",
        "package.json",       -- Node.js
        "Cargo.toml",        -- Rust
        "pyproject.toml",    -- Python (modern)
        "requirements.txt",   -- Python
        "setup.py",          -- Python
        "composer.json",     -- PHP
        "go.mod",            -- Go
        "Makefile",          -- C/C++
        "CMakeLists.txt",    -- CMake
        ".project",          -- Generic project marker
        ".vscode",           -- VSCode workspace
        ".idea",             -- IntelliJ/PyCharm
    }

    -- Find project root by looking for markers
    local function find_project_root(path)
        path = path or vim.fn.getcwd()
        local current = vim.fn.fnamemodify(path, ":p")

        while current ~= "/" do
            for _, marker in ipairs(project_markers) do
                local marker_path = current .. "/" .. marker
                if vim.fn.isdirectory(marker_path) == 1 or vim.fn.filereadable(marker_path) == 1 then
                    return current
                end
            end
            current = vim.fn.fnamemodify(current, ":h")
        end

        return nil
    end

    -- Check if current directory is a project
    local function is_project_directory(path)
        path = path or vim.fn.getcwd()
        return find_project_root(path) == vim.fn.fnamemodify(path, ":p")
    end

    -- Auto-detect and prompt for session restore
    local function auto_detect_session()
        local project_root = find_project_root()
        if not project_root then return end

        local project_name = vim.fn.fnamemodify(project_root, ":t")
        local session_file = vim.fn.stdpath("data") .. "/sessions/" ..
            vim.fn.substitute(project_root, "/", "%%", "g") .. ".vim"

        -- Check if session exists
        if vim.fn.filereadable(session_file) == 1 then
            -- Ask user if they want to restore session
            vim.defer_fn(function()
                local choice = vim.fn.confirm(
                    "Found session for project '" .. project_name .. "'.\nRestore it?",
                    "&Yes\n&No",
                    1
                )

                if choice == 1 then
                    -- Restore session
                    if pcall(require, "persistence") then
                        require("persistence").load()
                        vim.notify("Project session restored: " .. project_name, vim.log.levels.INFO, {
                            title = "Project Detector",
                            icon = "",
                            timeout = 2500,
                        })
                    end
                end
            end, 1000) -- Delay to let nvim fully load
        else
            -- No session exists, but it's a project - offer to create one
            if is_project_directory() then
                vim.defer_fn(function()
                    vim.notify("Project detected: " .. project_name .. " (no session)", vim.log.levels.INFO, {
                        title = "Project Detector",
                        icon = "",
                        timeout = 3000,
                    })
                end, 500)
            end
        end
    end

    -- Auto-save session when leaving a project
    local function auto_save_session()
        local project_root = find_project_root()
        if not project_root then return end

        -- Save session if persistence is available
        if pcall(require, "persistence") then
            require("persistence").save()

            local project_name = vim.fn.fnamemodify(project_root, ":t")
            vim.notify("Project session saved: " .. project_name, vim.log.levels.INFO, {
                title = "Project Detector",
                icon = "",
                timeout = 2000,
            })
        end
    end

    -- VSCode-like workspace file support
    local function create_vscode_workspace()
        local project_root = find_project_root()
        if not project_root then
            vim.notify("No project detected", vim.log.levels.WARN, {
                title = "Workspace",
                icon = "",
                timeout = 2000,
            })
            return
        end

        local project_name = vim.fn.fnamemodify(project_root, ":t")
        local workspace_file = project_root .. "/" .. project_name .. ".code-workspace"

        -- Check if workspace file already exists
        if vim.fn.filereadable(workspace_file) == 1 then
            vim.notify("Workspace file already exists", vim.log.levels.WARN, {
                title = "Workspace",
                icon = "",
                timeout = 2000,
            })
            return
        end

        -- Create basic VSCode workspace file
        local workspace_content = vim.json.encode({
            folders = {{
                path = "."
            }},
            settings = {
                ["editor.tabSize"] = 4,
                ["editor.insertSpaces"] = true,
                ["files.trimTrailingWhitespace"] = true,
            }
        })

        local file = io.open(workspace_file, "w")
        if file then
            file:write(workspace_content)
            file:close()

            vim.notify("Workspace file created: " .. project_name .. ".code-workspace", vim.log.levels.INFO, {
                title = "Workspace",
                icon = "",
                timeout = 2500,
            })
        else
            vim.notify("Failed to create workspace file", vim.log.levels.ERROR, {
                title = "Workspace",
                icon = "",
                timeout = 2500,
            })
        end
    end

    -- Set up autocommands
    local group = vim.api.nvim_create_augroup("ProjectDetector", { clear = true })

    -- Auto-detect on startup
    vim.api.nvim_create_autocmd("VimEnter", {
        group = group,
        once = true,
        callback = auto_detect_session,
        desc = "Auto-detect project session on startup",
    })

    -- Auto-save when changing directories
    vim.api.nvim_create_autocmd("DirChanged", {
        group = group,
        callback = function(args)
            -- Save session for previous directory if it was a project
            if args.match == "global" then
                auto_save_session()
            end
        end,
        desc = "Auto-save session when changing directories",
    })

    -- Auto-save on exit
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = group,
        callback = auto_save_session,
        desc = "Auto-save session on exit",
    })

    -- Commands
    vim.api.nvim_create_user_command("ProjectDetect", function()
        local project_root = find_project_root()
        if project_root then
            local project_name = vim.fn.fnamemodify(project_root, ":t")
            vim.notify("Project detected: " .. project_name .. " at " .. project_root, vim.log.levels.INFO, {
                title = "Project Detector",
                icon = "",
                timeout = 3000,
            })
        else
            vim.notify("No project detected in current directory", vim.log.levels.WARN, {
                title = "Project Detector",
                icon = "",
                timeout = 2500,
            })
        end
    end, { desc = "Detect current project" })

    vim.api.nvim_create_user_command("ProjectCreateWorkspace", create_vscode_workspace, {
        desc = "Create VSCode workspace file for current project"
    })

    -- Keymaps
    vim.keymap.set("n", "<leader>pd", "<cmd>ProjectDetect<cr>", { desc = "Detect project" })
    vim.keymap.set("n", "<leader>pc", "<cmd>ProjectCreateWorkspace<cr>", { desc = "Create workspace" })

    -- Expose functions globally
    _G.ProjectDetector = {
        find_project_root = find_project_root,
        is_project_directory = is_project_directory,
    }
end

return M