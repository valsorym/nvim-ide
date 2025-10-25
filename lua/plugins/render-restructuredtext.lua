-- ~/.config/nvim/lua/plugins/render-restructuredtext.lua
-- Render reStructuredText directly inside Neovim without browser.

return {
    "nvim-treesitter/nvim-treesitter",
    ft = { "rst", "restructuredtext" },
    event = "VeryLazy",

    config = function()
        -- Ensure RST parser is installed.
        require("nvim-treesitter.configs").setup({
            ensure_installed = { "rst" },
            highlight = { enable = true },
        })

        -- Virtual-text based inline renderer for .rst files.
        local api = vim.api
        local ns = api.nvim_create_namespace("render_rst")
        local enabled = false

        -- Define highlight groups.
        local function define_hl()
            api.nvim_set_hl(0, "RstHeading1", { fg = "#89b4fa", bold = true })
            api.nvim_set_hl(0, "RstHeading2", { fg = "#94e2d5", bold = true })
            api.nvim_set_hl(0, "RstHeading3", { fg = "#a6e3a1", bold = true })
            api.nvim_set_hl(0, "RstBullet", { fg = "#cba6f7" })
            api.nvim_set_hl(0, "RstQuote", { fg = "#a6e3a1", italic = true })
            api.nvim_set_hl(0, "RstCode", { fg = "#f9e2af" })
            api.nvim_set_hl(0, "RstDirective", { fg = "#f38ba8" })
        end

        -- Clear all virtual text and highlights.
        local function clear()
            api.nvim_buf_clear_namespace(0, ns, 0, -1)
        end

        -- Detect heading level by underline character.
        local function get_heading_level(char)
            local levels = {
                ["="] = 1,
                ["-"] = 2,
                ["~"] = 3,
                ["`"] = 4,
                ["#"] = 5,
                ["^"] = 6,
            }
            return levels[char] or 1
        end

        -- Simple parse & render loop.
        local function render()
            clear()
            define_hl()

            local lines = api.nvim_buf_get_lines(0, 0, -1, false)
            local prev_line = ""

            for i, line in ipairs(lines) do
                -- Headings with underline (previous line is title)
                local underline_char = line:match("^([=~`%-%^#]+)%s*$")
                if underline_char and prev_line ~= "" and not prev_line:match("^%s*$") then
                    local char = underline_char:sub(1, 1)
                    local level = get_heading_level(char)
                    local icons = { "󰎥  ", "󰎨  ", "󰎫  ", "󰎲  ", "󰎯  ", "󰎴  " }
                    local icon = icons[level] or "󰎥 "
                    local hl = "RstHeading" .. math.min(level, 3)

                    -- Highlight title line.
                    api.nvim_buf_add_highlight(0, ns, hl, i - 2, 0, -1)

                    -- Add icon to title.
                    api.nvim_buf_set_extmark(0, ns, i - 2, 0, {
                        virt_text = { { icon, hl } },
                        virt_text_pos = "inline",
                    })

                    -- Hide underline.
                    api.nvim_buf_set_extmark(0, ns, i - 1, 0, {
                        virt_text = { { "", "Comment" } },
                        virt_text_pos = "overlay",
                        hl_mode = "combine",
                    })
                end

                -- Bulleted lists (-, *, +).
                local indent, bullet = line:match("^(%s*)([%-%*%+])%s+")
                if bullet then
                    local col = #indent
                    api.nvim_buf_set_extmark(0, ns, i - 1, col, {
                        virt_text = { { "• ", "RstBullet" } },
                        virt_text_pos = "overlay",
                    })
                end

                -- Numbered lists.
                local indent_num, num = line:match("^(%s*)(%d+)%.%s+")
                if num then
                    local col = #indent_num
                    api.nvim_buf_set_extmark(0, ns, i - 1, col, {
                        virt_text = { { num .. ". ", "RstBullet" } },
                        virt_text_pos = "overlay",
                    })
                end

                -- Code blocks (::).
                if line:match("::%s*$") then
                    api.nvim_buf_set_extmark(0, ns, i - 1, 0, {
                        virt_text = { { "  ", "RstCode" } },
                        virt_text_pos = "eol",
                    })
                end

                -- Directives (.. directive::).
                local directive = line:match("^%s*%.%.%s+([%w%-]+)::")
                if directive then
                    local icon_map = {
                        ["code-block"] = " ",
                        ["note"] = " ",
                        ["warning"] = " ",
                        ["tip"] = "󰌶 ",
                        ["important"] = " ",
                        ["image"] = "󰥶 ",
                        ["figure"] = "󰹆 ",
                    }
                    local icon = icon_map[directive] or "┃ "
                    api.nvim_buf_set_extmark(0, ns, i - 1, 0, {
                        virt_text = { { icon .. " ", "RstDirective" } },
                        virt_text_pos = "inline",
                    })
                end

                -- Inline code (`code`)
                for start_pos, code_text, end_pos in line:gmatch("()``(.-)``()") do
                    api.nvim_buf_set_extmark(0, ns, i - 1, start_pos - 1, {
                        end_col = end_pos - 1,
                        hl_group = "RstCode",
                    })
                end

                prev_line = line
            end
        end

        -- Toggle logic.
        local function toggle()
            enabled = not enabled
            if enabled then
                render()
                vim.notify("RST rendering enabled", vim.log.levels.INFO)
            else
                clear()
                vim.notify("RST rendering disabled", vim.log.levels.INFO)
            end
        end

        -- Export toggle function globally for cross-plugin access.
        _G.rst_render_toggle = toggle

        -- Auto-render on buffer enter (optional).
        vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
            pattern = { "*.rst" },
            callback = function()
                if enabled then
                    vim.defer_fn(render, 100)
                end
            end,
        })

        -- Refresh on write and text changes.
        vim.api.nvim_create_autocmd({ "BufWritePost", "TextChanged", "TextChangedI" }, {
            pattern = { "*.rst" },
            callback = function()
                if enabled then
                    vim.defer_fn(render, 50)
                end
            end,
        })

        -- Unified toggle keymap (same as Markdown).
        vim.keymap.set("n", "<Leader>dr", function()
            local ft = vim.bo.filetype
            if ft == "markdown" then
                local ok, render_md = pcall(require, "render-markdown")
                if ok then
                    render_md.toggle()
                else
                    vim.notify("render-markdown not loaded", vim.log.levels.WARN)
                end
            elseif ft == "rst" or ft == "restructuredtext" then
                toggle()
            else
                vim.notify("No renderer available for ." .. ft, vim.log.levels.WARN)
            end
        end, { desc = "Toggle Rendering (Markdown/RST)" })
    end,
}