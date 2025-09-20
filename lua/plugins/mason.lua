-- ~/.config/nvim/lua/plugins/mason.lua
-- Fixed Mason configuration without UI errors

return {
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup({
                ui = {
                    check_outdated_packages_on_open = true,
                    border = "rounded",
                    icons = {
                        package_installed = "✓",
                        package_pending = "➜",
                        package_uninstalled = "✗"
                    },
                    keymaps = {
                        toggle_package_expand = "<CR>",
                        install_package = "i",
                        update_package = "u",
                        check_package_version = "c",
                        update_all_packages = "U",
                        check_outdated_packages = "C",
                        uninstall_package = "X",
                        cancel_installation = "<C-c>",
                        apply_language_filter = "<C-f>",
                    },
                },
                install_root_dir = vim.fn.stdpath("data") .. "/mason",
                pip = {
                    upgrade_pip = false,
                },
                log_level = vim.log.levels.INFO,
                max_concurrent_installers = 4,
            })
        end
    },
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = {"mason.nvim"},
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "pyright",
                    "ts_ls",
                    "html",
                    "cssls",
                    "emmet_ls",
                    "dockerls",
                    "yamlls",
                    "jsonls",
                    "lua_ls",
                    "bashls"
                },
                automatic_installation = true,
                handlers = nil,
            })
        end
    },
    {
        "jay-babu/mason-null-ls.nvim",
        dependencies = {"mason.nvim", "nvimtools/none-ls.nvim"},
        config = function()
            require("mason-null-ls").setup({
                ensure_installed = {},
                automatic_installation = false,
                handlers = {},
            })
        end
    }
}