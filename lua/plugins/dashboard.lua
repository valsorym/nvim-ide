-- ~/.config/nvim/lua/plugins/dashboard.lua
-- Dashboard.

-- Release version.
local release_version = "v2.7.0"

return {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    cmd = "Dashboard",
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
                            action = function() require("config.replace").search(false) end

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
                            action = "confirm qall"

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

    end,
}
