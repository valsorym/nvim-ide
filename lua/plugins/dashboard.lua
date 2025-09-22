-- ~/.config/nvim/lua/plugins/dashboard.lua
-- Dashboard.

return {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    dependencies = {"nvim-tree/nvim-web-devicons"},
    config = function()
        local db = require("dashboard")
        db.setup(
            {
                theme = "doom",
                config = {
                    header = {
                        "",
                        "",
                        "╔════════════════════════════════════════════════════════════╗",
                        "║                                                            ║",
                        "║  ███╗   ██╗██╗   ██╗██╗███╗   ███╗    ██╗██████╗ ███████╗  ║",
                        "║  ████╗  ██║██║   ██║██║████╗ ████║    ██║██╔══██╗██╔════╝  ║",
                        "║  ██╔██╗ ██║██║   ██║██║██╔████╔██║    ██║██║  ██║█████╗    ║",
                        "║  ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║    ██║██║  ██║██╔══╝    ║",
                        "║  ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║    ██║██████╔╝███████╗  ║",
                        "║  ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝    ╚═╝╚═════╝ ╚══════╝  ║",
                        "║                                                            ║",
                        "╚════════════════════════════════════════════════════════════╝",
                        " Welcome to your development environment!",
                        "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌",
                        "Version: 0.0.3",
                        "",
                        "",
                    },
                    center = {
                        {
                            icon = "  ",
                            desc = "Find File",
                            key = "f",
                            action = "Telescope find_files"
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
                            action = "qa"
                        }
                    },
                    footer = {
                        "",
                        " Press F9 to open File Explorer.",
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
    end
}
