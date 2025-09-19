-- ~/.config/nvim/lua/plugins/mason.lua
-- Mason package manager for LSP servers, formatters, linters.

return {
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup(
                {
                    ui = {
                        icons = {
                            package_installed = "✓",
                            package_pending = "➜",
                            package_uninstalled = "✗"
                        }
                    }
                }
            )
        end
    },
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = {"mason.nvim"},
        config = function()
            require("mason-lspconfig").setup(
                {
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
                    automatic_installation = true
                }
            )
        end
    },
    {
        "jay-babu/mason-null-ls.nvim",
        dependencies = {"mason.nvim", "nvimtools/none-ls.nvim"},
        config = function()
            require("mason-null-ls").setup(
                {
                    -- Disable automatic installation completely.
                    ensure_installed = {},
                    automatic_installation = false
                }
            )
        end
    }
}
