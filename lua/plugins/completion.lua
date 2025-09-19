-- ~/.config/nvim/lua/plugins/completion.lua
-- Autocompletion configuration.

return {
    "hrsh7th/nvim-cmp",
    dependencies = {
        -- Completion sources.
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/cmp-nvim-lua",
        -- Snippets.
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "rafamadriz/friendly-snippets",
        -- Icons.
        "onsails/lspkind.nvim"
    },
    config = function()
        local cmp = require("cmp")
        local luasnip = require("luasnip")
        local lspkind = require("lspkind")

        -- Load friendly-snippets.
        require("luasnip.loaders.from_vscode").lazy_load()

        cmp.setup(
            {
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end
                },
                window = {
                    completion = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered()
                },
                mapping = cmp.mapping.preset.insert(
                    {
                        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                        ["<C-f>"] = cmp.mapping.scroll_docs(4),
                        ["<C-Space>"] = cmp.mapping.complete(),
                        ["<C-e>"] = cmp.mapping.abort(),
                        ["<CR>"] = cmp.mapping.confirm(
                            {
                                behavior = cmp.ConfirmBehavior.Replace,
                                select = true
                            }
                        ),
                        ["<Tab>"] = cmp.mapping(
                            function(fallback)
                                if cmp.visible() then
                                    cmp.select_next_item()
                                elseif luasnip.expand_or_jumpable() then
                                    luasnip.expand_or_jump()
                                else
                                    fallback()
                                end
                            end,
                            {"i", "s"}
                        ),
                        ["<S-Tab>"] = cmp.mapping(
                            function(fallback)
                                if cmp.visible() then
                                    cmp.select_prev_item()
                                elseif luasnip.jumpable(-1) then
                                    luasnip.jump(-1)
                                else
                                    fallback()
                                end
                            end,
                            {"i", "s"}
                        )
                    }
                ),
                sources = cmp.config.sources(
                    {
                        {name = "nvim_lsp", priority = 1000},
                        {name = "luasnip", priority = 750},
                        {name = "nvim_lua", priority = 700},
                        {name = "path", priority = 500},
                        {name = "buffer", priority = 250}
                    }
                ),
                formatting = {
                    format = lspkind.cmp_format(
                        {
                            mode = "symbol_text",
                            maxwidth = 50,
                            ellipsis_char = "...",
                            before = function(entry, vim_item)
                                -- Source name.
                                vim_item.menu =
                                    ({
                                    nvim_lsp = "[LSP]",
                                    luasnip = "[Snip]",
                                    nvim_lua = "[Lua]",
                                    buffer = "[Buf]",
                                    path = "[Path]"
                                })[entry.source.name]
                                return vim_item
                            end
                        }
                    )
                },
                experimental = {
                    ghost_text = {
                        hl_group = "Comment"
                    }
                }
            }
        )

        -- Command line completion.
        cmp.setup.cmdline(
            {"/", "?"},
            {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                    {name = "buffer"}
                }
            }
        )

        cmp.setup.cmdline(
            ":",
            {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources(
                    {
                        {name = "path"}
                    },
                    {
                        {name = "cmdline"}
                    }
                )
            }
        )
    end
}
