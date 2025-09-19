-- ~/.config/nvim/lua/plugins/footer.lua
-- Enhanced statusline with useful information.

return {
    "nvim-lualine/lualine.nvim",
    dependencies = {"nvim-tree/nvim-web-devicons"},
    config = function()
        local lualine = require("lualine")

        -- Custom function to get git branch with status
        local function git_branch_with_status()
            local branch = vim.fn.system("git branch --show-current 2>/dev/null"):gsub("\n", "")
            if branch == "" then
                return ""
            end

            -- Get git status counts
            local status = vim.fn.system("git status --porcelain 2>/dev/null")
            if status == "" then
                return " " .. branch
            end

            local modified = 0
            local added = 0
            local deleted = 0
            local untracked = 0

            for line in status:gmatch("[^\r\n]+") do
                local first_char = line:sub(1, 1)
                local second_char = line:sub(2, 2)

                if first_char == "M" or second_char == "M" then
                    modified = modified + 1
                elseif first_char == "A" or second_char == "A" then
                    added = added + 1
                elseif first_char == "D" or second_char == "D" then
                    deleted = deleted + 1
                elseif first_char == "?" then
                    untracked = untracked + 1
                end
            end

            local status_str = ""
            if modified > 0 then status_str = status_str .. "~" .. modified end
            if added > 0 then status_str = status_str .. "+" .. added end
            if deleted > 0 then status_str = status_str .. "-" .. deleted end
            if untracked > 0 then status_str = status_str .. "?" .. untracked end

            return " " .. branch .. (status_str ~= "" and " [" .. status_str .. "]" or "")
        end

        -- Custom function to show LSP status
        local function lsp_status()
            local clients = vim.lsp.get_clients({bufnr = 0})
            if #clients == 0 then
                return ""
            end

            local client_names = {}
            for _, client in pairs(clients) do
                table.insert(client_names, client.name)
            end

            return "LSP: " .. table.concat(client_names, ", ")
        end

        -- Custom function to show diagnostic counts
        local function diagnostics_count()
            local diagnostics = vim.diagnostic.get(0)
            local errors = 0
            local warnings = 0
            local hints = 0
            local info = 0

            for _, diag in pairs(diagnostics) do
                if diag.severity == vim.diagnostic.severity.ERROR then
                    errors = errors + 1
                elseif diag.severity == vim.diagnostic.severity.WARN then
                    warnings = warnings + 1
                elseif diag.severity == vim.diagnostic.severity.HINT then
                    hints = hints + 1
                elseif diag.severity == vim.diagnostic.severity.INFO then
                    info = info + 1
                end
            end

            local result = {}
            if errors > 0 then table.insert(result, "E:" .. errors) end
            if warnings > 0 then table.insert(result, "W:" .. warnings) end
            if info > 0 then table.insert(result, "I:" .. info) end
            if hints > 0 then table.insert(result, "H:" .. hints) end

            return table.concat(result, " ")
        end

        -- Custom function to show selection info
        local function selection_info()
            local mode = vim.fn.mode()
            if mode == "v" or mode == "V" or mode == "\22" then -- \22 is Ctrl-V
                local start_pos = vim.fn.getpos("'<")
                local end_pos = vim.fn.getpos("'>")

                if mode == "v" then
                    -- Character-wise visual mode
                    local start_line, start_col = start_pos[2], start_pos[3]
                    local end_line, end_col = end_pos[2], end_pos[3]

                    if start_line == end_line then
                        local selected = math.abs(end_col - start_col) + 1
                        return selected .. " chars"
                    else
                        local lines = math.abs(end_line - start_line) + 1
                        return lines .. " lines"
                    end
                elseif mode == "V" then
                    -- Line-wise visual mode
                    local lines = math.abs(end_pos[2] - start_pos[2]) + 1
                    return lines .. " lines"
                elseif mode == "\22" then
                    -- Block-wise visual mode
                    local lines = math.abs(end_pos[2] - start_pos[2]) + 1
                    local cols = math.abs(end_pos[3] - start_pos[3]) + 1
                    return lines .. "x" .. cols .. " block"
                end
            end
            return ""
        end

        -- Custom function to show file size
        local function file_size()
            local file = vim.fn.expand("%:p")
            if file == "" then
                return ""
            end

            local size = vim.fn.getfsize(file)
            if size < 0 then
                return ""
            elseif size < 1024 then
                return size .. "B"
            elseif size < 1048576 then
                return string.format("%.1fK", size / 1024)
            else
                return string.format("%.1fM", size / 1048576)
            end
        end

        -- Custom function to show Python virtual environment
        local function python_venv()
            local venv = vim.fn.getenv("VIRTUAL_ENV")
            if venv ~= vim.NIL and venv ~= "" then
                local venv_name = vim.fn.fnamemodify(venv, ":t")
                return " " .. venv_name
            end

            -- Check for local .venv
            if vim.fn.isdirectory(".venv") == 1 then
                return " .venv"
            elseif vim.fn.isdirectory("venv") == 1 then
                return " venv"
            end

            return ""
        end

        lualine.setup({
            options = {
                theme = "catppuccin",
                component_separators = { left = "", right = "" },
                section_separators = { left = "", right = "" },
                disabled_filetypes = {
                    statusline = {"dashboard", "alpha", "NvimTree"},
                    winbar = {},
                },
                ignore_focus = {},
                always_divide_middle = true,
                globalstatus = false,
                refresh = {
                    statusline = 1000,
                    tabline = 1000,
                    winbar = 1000,
                }
            },
            sections = {
                lualine_a = {
                    {
                        "mode",
                        fmt = function(str)
                            return str:sub(1, 3) -- Shorten mode names
                        end
                    }
                },
                lualine_b = {
                    {
                        git_branch_with_status,
                        icon = "",
                        color = { fg = "#a6e3a1" } -- Green color for git
                    }
                },
                lualine_c = {
                    {
                        "filename",
                        file_status = true,
                        newfile_status = true,
                        path = 1, -- Relative path
                        symbols = {
                            modified = " [+]",
                            readonly = " []",
                            unnamed = "[No Name]",
                            newfile = "[New]"
                        }
                    },
                    {
                        file_size,
                        color = { fg = "#fab387" } -- Orange color
                    }
                },
                lualine_x = {
                    {
                        selection_info,
                        color = { fg = "#f9e2af" } -- Yellow color for selection
                    },
                    {
                        python_venv,
                        color = { fg = "#89b4fa" } -- Blue color for Python
                    },
                    {
                        diagnostics_count,
                        color = { fg = "#f38ba8" } -- Red color for diagnostics
                    },
                    {
                        lsp_status,
                        color = { fg = "#cba6f7" } -- Purple color for LSP
                    },
                    "encoding",
                    "fileformat",
                    "filetype"
                },
                lualine_y = {
                    "progress"
                },
                lualine_z = {
                    {
                        "location",
                        fmt = function(str)
                            local line, col = str:match("(%d+):(%d+)")
                            if line and col then
                                return "☰ " .. line .. " ⟨" .. col .. "⟩"
                            end
                            return str
                        end
                    }
                }
            },
            inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = {
                    {
                        "filename",
                        file_status = true,
                        path = 1
                    }
                },
                lualine_x = {"location"},
                lualine_y = {},
                lualine_z = {}
            },
            tabline = {},
            winbar = {},
            inactive_winbar = {},
            extensions = {"nvim-tree", "toggleterm", "mason"}
        })
    end
}