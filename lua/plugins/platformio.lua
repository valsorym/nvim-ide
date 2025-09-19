-- ~/.config/nvim/lua/plugins/platformio.lua
-- PlatformIO integration for embedded development.

return {
    -- LSP configuration for PlatformIO projects will be handled in lsp.lua
    -- This file contains project management and terminal integration

    {
        "akinsho/toggleterm.nvim", -- extends existing toggleterm config
        opts = function(_, opts)
            -- Add PlatformIO specific terminals
            local Terminal = require("toggleterm.terminal").Terminal

            -- PlatformIO build terminal
            local pio_build = Terminal:new({
                cmd = "pio run",
                hidden = true,
                direction = "horizontal",
                close_on_exit = false,
                on_open = function(term)
                    vim.cmd("startinsert!")
                end,
            })

            -- PlatformIO upload terminal
            local pio_upload = Terminal:new({
                cmd = "pio run --target upload",
                hidden = true,
                direction = "horizontal",
                close_on_exit = false,
                on_open = function(term)
                    vim.cmd("startinsert!")
                end,
            })

            -- PlatformIO monitor terminal
            local pio_monitor = Terminal:new({
                cmd = "pio device monitor",
                hidden = true,
                direction = "horizontal",
                close_on_exit = false,
                on_open = function(term)
                    vim.cmd("startinsert!")
                end,
            })

            -- PlatformIO clean terminal
            local pio_clean = Terminal:new({
                cmd = "pio run --target clean",
                hidden = true,
                direction = "horizontal",
                close_on_exit = false,
                on_open = function(term)
                    vim.cmd("startinsert!")
                end,
            })

            -- Global functions for terminal access
            function _PIO_BUILD()
                pio_build:toggle()
            end

            function _PIO_UPLOAD()
                pio_upload:toggle()
            end

            function _PIO_MONITOR()
                pio_monitor:toggle()
            end

            function _PIO_CLEAN()
                pio_clean:toggle()
            end

            return opts
        end
    },

    -- File type detection and basic configuration
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, {
                "cpp",
                "c",
                "python", -- for platformio.ini and scripts
                "ini",    -- for platformio.ini files
                "json"    -- for platformio project files
            })
            return opts
        end,
    },

    -- Project detection and management
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            {
                "nvim-telescope/telescope-project.nvim",
                config = function()
                    require("telescope").load_extension("project")
                end,
            },
        },
        keys = {
            {"<leader>fp", "<cmd>Telescope project<cr>", desc = "Find projects"},
        },
    },
}