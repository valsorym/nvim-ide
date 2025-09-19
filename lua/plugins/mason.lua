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
                        -- Python servers
                        "pyright", -- Microsoft's Python LSP
                        -- JavaScript/TypeScript (ts_ls will be installed via mason-tool-installer)
                        "ts_ls", -- TypeScript Language Server
                        -- Web technologies
                        "html",
                        "cssls",
                        "emmet_ls",
                        -- Go (use system gopls instead of Mason version)
                        -- "gopls",        -- Commented out due to installation issues

                        -- C/C++ (use system clangd instead of Mason version)
                        -- "clangd",       -- Commented out due to installation issues

                        -- DevOps
                        "dockerls",
                        "yamlls",
                        "jsonls",
                        -- Lua (for Neovim config).
                        "lua_ls", -- Lua Language Server
                        -- Bash.
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
