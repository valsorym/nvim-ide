-- ~/.config/nvim/lua/plugins/footer.lua
-- Flat, fast lualine with Nerd Font icons and zero git shelling.

return {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        -- Optional, but enables zero-shell git info:
        -- "lewis6991/gitsigns.nvim",
    },
    config = function()
        local lualine = require("lualine")

        -- ICONS
        local icons = {
            branch = "",     -- nf-dev-git_branch
            added = "",      -- nf-fa-plus
            changed = "",    -- nf-fa-exclamation_circle
            removed = "",    -- nf-fa-minus
            lock = "",       -- nf-fa-lock
            new = "󰎔",        -- nf-md-new_box
            python = "",     -- nf-dev-python
            line = "",       -- nf-pom-line
            col = "",        -- nf-pom-col
            lsp = "",        -- nf-fa-cog
            sep = "│",
        }

        -- GIT
        local function git_branch_with_status()
            local gs = vim.b.gitsigns_status_dict
            if not gs or not gs.head or gs.head == "" then
                return ""
            end
            local parts = {}
            if (gs.added or 0) > 0 then
                table.insert(parts, icons.added .. " " .. gs.added)
            end
            if (gs.changed or 0) > 0 then
                table.insert(parts, icons.changed .. " " .. gs.changed)
            end
            if (gs.removed or 0) > 0 then
                table.insert(parts, icons.removed .. " " .. gs.removed)
            end
            local tail = (#parts > 0) and (" [" .. table.concat(parts, " ")
                .. "]") or ""
            return " " .. icons.branch .. " " .. gs.head .. tail
        end

        -- LSP
        local function lsp_status()
            local cl = vim.lsp.get_clients({bufnr = 0})
            if #cl == 0 then return "" end
            local first = cl[1] and cl[1].name or ""
            if #cl == 1 then return icons.lsp .. " " .. first end
            return icons.lsp .. " " .. first .. "(+" .. (#cl - 1) .. ")"
        end

        -- SELECTION INFO
        local function selection_info()
            local m = vim.fn.mode()
            if m ~= "v" and m ~= "V" and m ~= "\22" then return "" end
            local s = vim.fn.getpos("'<")
            local e = vim.fn.getpos("'>")
            if m == "v" then
                if s[2] == e[2] then
                    local n = math.abs(e[3] - s[3]) + 1
                    return n .. " chars"
                else
                    local n = math.abs(e[2] - s[2]) + 1
                    return n .. " lines"
                end
            elseif m == "V" then
                local n = math.abs(e[2] - s[2]) + 1
                return n .. " lines"
            else
                local ln = math.abs(e[2] - s[2]) + 1
                local cn = math.abs(e[3] - s[3]) + 1
                return ln .. "x" .. cn .. " block"
            end
        end

        -- FILE SIZE
        local function file_size()
            local p = vim.fn.expand("%:p")
            if p == "" then return "" end
            local st = vim.loop.fs_stat(p)
            if not st or not st.size then return "" end
            local sz = st.size
            if sz < 1024 then return sz .. "B" end
            if sz < 1048576 then return string.format("%.1fK", sz / 1024) end
            return string.format("%.1fM", sz / 1048576)
        end

        -- PYTHON VENV
        local function python_venv()
            local v = vim.fn.getenv("VIRTUAL_ENV")
            if v and v ~= "" and v ~= vim.NIL then
                return icons.python .. " " .. vim.fn.fnamemodify(v, ":t")
            end
            if vim.fn.isdirectory(".venv") == 1 then
                return icons.python .. " .venv"
            end
            if vim.fn.isdirectory("venv") == 1 then
                return icons.python .. " venv"
            end
            return ""
        end

        -- LOCATION
        local function loc_fmt(_)
            local l = vim.fn.line(".")
            local c = vim.fn.col(".")
            return icons.col .. " " .. c .. " " .. icons.line .. " " .. l
        end

        -- SETUP
        lualine.setup({
            options = {
                theme = "catppuccin",
                component_separators = { left = "", right = "" },
                section_separators = { left = "", right = "" },
                disabled_filetypes = {
                    statusline = { "dashboard", "alpha", "NvimTree" },
                    winbar = {},
                },
                always_divide_middle = true,
                globalstatus = false,
                refresh = { statusline = 1000, tabline = 1000, winbar = 1000 },
            },
            sections = {
                lualine_a = {
                    { "mode", fmt = function(s) return s:sub(1, 3) end },
                },
                lualine_b = {
                    {
                        git_branch_with_status,
                        icon = "",
                        color = { fg = "#a6e3a1" },
                    },
                },
                lualine_c = {
                    {
                        "filename",
                        file_status = true,
                        newfile_status = true,
                        path = 1,
                        symbols = {
                            modified = " [+]",
                            readonly = " " .. icons.lock,
                            unnamed = "[No Name]",
                            newfile = " " .. icons.new,
                        },
                    },
                    { file_size, color = { fg = "#fab387" } },
                },
                lualine_x = {
                    { selection_info, color = { fg = "#f9e2af" } },
                    { python_venv, color = { fg = "#89b4fa" } },
                    {
                        "diagnostics",
                        sources = { "nvim_diagnostic" },
                        colored = true,
                        symbols = {
                            error = " ",
                            warn = " ",
                            info = " ",
                            hint = " ",
                        },
                        update_in_insert = false,
                    },
                    { lsp_status, color = { fg = "#cba6f7" } },
                    { "encoding" },
                    { "fileformat" },
                    { "filetype" },
                },
                lualine_y = { "progress" },
                lualine_z = { { "location", fmt = loc_fmt } },
            },
            inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = { { "filename", file_status = true, path = 1 } },
                lualine_x = { "location" },
                lualine_y = {},
                lualine_z = {},
            },
            tabline = {},
            winbar = {},
            inactive_winbar = {},
            extensions = { "nvim-tree", "toggleterm", "mason" },
        })
    end,
}
