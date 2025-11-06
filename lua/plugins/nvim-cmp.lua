-- ~/.config/nvim/lua/plugins/completion.lua
-- Code autocomplete in Neovim!

return {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
    },
    config = function()
        local cmp = require("cmp")
        local luasnip = require("luasnip")

        cmp.setup({
            snippet = {
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                end,
            },

            -- Completion menu appearance.
            window = {
                completion = cmp.config.window.bordered(),
                documentation = cmp.config.window.bordered(),
            },

            -- Preselect first item but don't auto-insert.
            completion = {
                completeopt = "menu,menuone,noinsert,noselect",
            },

            preselect = cmp.PreselectMode.None,

            -- Key mappings.
            mapping = cmp.mapping.preset.insert({
                -- Ctrl+Space: Manually trigger completion.
                ["<C-Space>"] = cmp.mapping.complete(),

                -- Ctrl+E: Close completion menu.
                ["<C-e>"] = cmp.mapping.abort(),

                -- Ctrl+B/F: Scroll documentation.
                ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                ["<C-f>"] = cmp.mapping.scroll_docs(4),

                -- Arrow keys: Navigate through completion items.
                ["<Down>"] = cmp.mapping.select_next_item({
                    behavior = cmp.SelectBehavior.Select
                }),
                ["<Up>"] = cmp.mapping.select_prev_item({
                    behavior = cmp.SelectBehavior.Select
                }),

                -- Ctrl+N/P: Navigate (Vim-style).
                ["<C-n>"] = cmp.mapping.select_next_item({
                    behavior = cmp.SelectBehavior.Insert
                }),
                ["<C-p>"] = cmp.mapping.select_prev_item({
                    behavior = cmp.SelectBehavior.Insert
                }),

                -- TAB: Confirm selection OR jump to next snippet placeholder.
                ["<Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.confirm({
                            select = true,  -- auto-select first item
                            behavior = cmp.ConfirmBehavior.Insert,
                        })
                    elseif luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                    else
                        fallback()
                    end
                end, { "i", "s" }),

                -- Shift+TAB: Jump to previous snippet placeholder.
                ["<S-Tab>"] = cmp.mapping(function(fallback)
                    if luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fallback()
                    end
                end, { "i", "s" }),

                -- ENTER: Always create new line (never confirm completion).
                ["<CR>"] = cmp.mapping(function(fallback)
                    if cmp.visible() and cmp.get_selected_entry() then
                        -- If item is manually selected, confirm it.
                        cmp.confirm({
                            behavior = cmp.ConfirmBehavior.Insert,
                        })
                    else
                        -- Otherwise just insert newline.
                        fallback()
                    end
                end, { "i", "s" }),
            }),

            -- Sources priority.
            sources = cmp.config.sources({
                { name = "nvim_lsp", priority = 1000 },
                { name = "luasnip", priority = 750 },
                { name = "buffer", priority = 500 },
                { name = "path", priority = 250 },
            }),

            -- Formatting.
            formatting = {
                format = function(entry, vim_item)
                    -- Source name.
                    vim_item.menu = ({
                        nvim_lsp = "[LSP]",
                        luasnip = "[Snippet]",
                        buffer = "[Buffer]",
                        path = "[Path]",
                    })[entry.source.name]
                    return vim_item
                end,
            },

            -- Experimental features.
            experimental = {
                ghost_text = false,  -- disable ghost text (grey preview)
            },
        })

        -- Command-line completion.
        cmp.setup.cmdline(":", {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({
                { name = "path" },
                { name = "cmdline" },
            }),
        })

        cmp.setup.cmdline("/", {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {
                { name = "buffer" },
            },
        })
    end,
}