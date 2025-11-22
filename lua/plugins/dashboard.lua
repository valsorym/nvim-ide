-- ~/.config/nvim/lua/plugins/dashboard.lua
-- Dashboard.

-- Release version.
local release_version = "v1.2.4"

return {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    dependencies = {"nvim-tree/nvim-web-devicons"},
    config = function()
        local db = require("dashboard")

        -- NVim version.
        local v = vim.version()
        local nvim_version = string.format("v%d.%d.%d", v.major, v.minor, v.patch)

        -- Dynamic year range.
        local base_year = 2025
        local current_year = os.date("*t").year
        local year_label = tostring(base_year)
        if current_year > base_year then
            local short_suffix = tostring(current_year)
            year_label = string.format("%d-%s", base_year, short_suffix)
        end

        db.setup(
            {
                theme = "doom",
                config = {
                    header = {
                        "",
                        "",
                        "  ╭───────────────────────────────────────────────────────────────╮  ",
                        "  │                                                               │─╮",
                        "  │                                                               │ │",
                        "  │    ███╗   ██╗██╗   ██╗██╗███╗   ███╗    ██╗██████╗ ███████╗   │ │",
                        "  │    ████╗  ██║██║   ██║██║████╗ ████║    ██║██╔══██╗██╔════╝   │ │",
                        "  │    ██╔██╗ ██║██║   ██║██║██╔████╔██║    ██║██║  ██║█████╗     │ │",
                        "  │    ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║    ██║██║  ██║██╔══╝     │ │",
                        "  │    ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║    ██║██████╔╝███████╗   │ │",
                        "  │    ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝    ╚═╝╚═════╝ ╚══════╝   │ │",
                        "  │             Welcome to your development environment!         │ │",
                        "  │                                                               │ │",
                        "  ╰───────────────────────────────────────────────────────────────╯ │",
                        "    ╰───────────────────────────────────────────────────────────────╯",
                        "",
                        "",
                    },
                    center = {
                        {
                            icon = "  ",
                            desc = "Find & Replace",
                            key = "f",
                            action = function()
                                -- Close dashboard first
                                vim.cmd("bd")
                                -- Trigger <leader>fc
                                vim.schedule(function()
                                    local keys = vim.api.nvim_replace_termcodes("<leader>fc", true, false, true)
                                    vim.api.nvim_feedkeys(keys, "m", false)
                                end)
                            end
                        },
                        {
                            icon = "  ",
                            desc = "Recent Files",
                            key = "r",
                            action = function()
                                if vim.v.oldfiles and #vim.v.oldfiles > 0 then
                                    require("telescope.builtin").oldfiles()
                                else
                                    print("No recent files found")
                                end
                            end
                        },
                        {
                            icon = "  ",
                            desc = "Find Text",
                            key = "g",
                            action = "Telescope live_grep"
                        },
                        {
                            icon = "  ",
                            desc = "New File",
                            key = "n",
                            action = "enew"
                        },
                        {
                            icon = "󰗼  ",
                            desc = "Quit",
                            key = "q",
                            action = function()
                                -- Show prompt
                                print("Really quit? [y/n]")

                                -- Get single character
                                local char = vim.fn.getchar()
                                local key = vim.fn.nr2char(char)

                                -- Clear the command line
                                vim.cmd("echo ''")

                                if key:lower() == "y" then
                                    vim.cmd("qa")
                                else
                                    print("Cancelled.")
                                end
                            end
                        }
                    },
                    footer = {
                        "",
                        string.format("🄯%s NVIM-IDE %s", year_label, release_version),
                        string.format(" NVim %s", nvim_version),
                    }
                }
            }
        )

        -- Stronger version: force-disable numbers by window options.
        local function hide_numbers()
            if vim.bo.filetype == "dashboard" then
                local win = vim.api.nvim_get_current_win()
                vim.wo[win].number = false
                vim.wo[win].relativenumber = false
                vim.wo[win].signcolumn = "no"
                vim.wo[win].foldcolumn = "0"
                pcall(
                    function()
                        vim.wo[win].statuscolumn = ""
                    end
                )
            end
        end

        vim.api.nvim_create_autocmd(
            {"FileType", "BufWinEnter", "WinEnter", "TabEnter"},
            {
                pattern = "dashboard",
                callback = hide_numbers
            }
        )

        -- Apply muted colors only for dashboard.
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "dashboard",
            callback = function()
                local muted = "#5c6370"
                vim.api.nvim_set_hl(0, "DashboardFooter", { fg = muted })
            end,
        })

    end
}
