-- ~/.config/nvim/lua/plugins/completion.lua
-- Fast, flat (Nerd Fonts) UI; tuned sorting; safe tab-jump; cmdline.

return {
    "hrsh7th/nvim-cmp",
    dependencies = {
        -- Sources.
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
        "onsails/lspkind.nvim",
    },
    config = function()
        local cmp = require("cmp")
        local luasnip = require("luasnip")
        local lspkind = require("lspkind")

        -- SNIPPETS
        require("luasnip.loaders.from_vscode").lazy_load()

        -- HELPERS
        local function has_words_before()
            local line, col = unpack(vim.api.nvim_win_get_cursor(0))
            if col == 0 then return false end
            local text = vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]
            return text:sub(col, col):match("%s") == nil
        end

        -- ICONS (FLAT NERD FONTS)

        -- Ensure your terminal/GUI uses a Nerd Font.
        lspkind.init({
            mode = "symbol_text",
            preset = "codicons",
            symbol_map = {
                Text = "", Method = "", Function = "󰊕", Constructor = "",
                Field = "", Variable = "", Class = "", Interface = "",
                Module = "", Property = "", Unit = "", Value = "",
                Enum = "", Keyword = "", Snippet = "", Color = "",
                File = "", Reference = "", Folder = "", EnumMember = "",
                Constant = "", Struct = "", Event = "", Operator = "",
                TypeParameter = "",
            },
        })

        -- Sorting: prefer LSP > Snip > Path > Buffer
        local compare = require("cmp.config.compare")
        local source_weight = {
            nvim_lsp = 4, luasnip = 3, path = 2, nvim_lua = 2, buffer = 1,
        }
        local function by_source(a, b)
            local sa = source_weight[a.source.name] or 0
            local sb = source_weight[b.source.name] or 0
            if sa ~= sb then return sa > sb end
            return false
        end

        -- CORE SETUP
        cmp.setup({
            preselect = cmp.PreselectMode.Item,
            completion = { completeopt = "menu,menuone,noinsert" },
            performance = {
                debounce = 60, throttle = 15, fetching_timeout = 200,
                max_view_entries = 120,
            },
            snippet = {
                expand = function(args) luasnip.lsp_expand(args.body) end,
            },
            window = {
                completion = cmp.config.window.bordered(),
                documentation = cmp.config.window.bordered(),
            },
            mapping = cmp.mapping.preset.insert({
                ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                ["<C-f>"] = cmp.mapping.scroll_docs(4),
                ["<C-Space>"] = cmp.mapping.complete(),
                ["<C-e>"] = cmp.mapping.abort(),
                ["<CR>"] = cmp.mapping.confirm({
                    behavior = cmp.ConfirmBehavior.Replace, select = true,
                }),
                ["<Tab>"] = cmp.mapping(function(fb)
                    if cmp.visible() then
                        cmp.select_next_item()
                    elseif luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                    elseif has_words_before() then
                        cmp.complete()
                    else
                        fb()
                    end
                end, { "i", "s" }),
                ["<S-Tab>"] = cmp.mapping(function(fb)
                    if cmp.visible() then
                        cmp.select_prev_item()
                    elseif luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fb()
                    end
                end, { "i", "s" }),
            }),
            sources = cmp.config.sources({
                { name = "nvim_lsp" },
                { name = "luasnip" },
                { name = "nvim_lua" },
                { name = "path" },
                { name = "buffer", keyword_length = 3 },
            }),
            sorting = {
                priority_weight = 2,
                comparators = {
                    compare.offset,
                    compare.exact,
                    by_source,          -- custom comparator
                    compare.score,
                    compare.recently_used,
                    compare.locality,
                    compare.kind,
                    compare.length,
                    compare.order,
                },
            },
            formatting = {
                fields = { "kind", "abbr", "menu" },
                format = lspkind.cmp_format({
                    mode = "symbol_text",
                    maxwidth = 50,
                    ellipsis_char = "…",
                    before = function(entry, vim_item)
                        vim_item.menu = ({
                            nvim_lsp = "[LSP]",
                            luasnip = "[Snip]",
                            nvim_lua = "[Lua]",
                            buffer = "[Buf]",
                            path = "[Path]",
                        })[entry.source.name]
                        return vim_item
                    end,
                }),
            },
            experimental = { ghost_text = { hl_group = "Comment" } },
        })

        -- CMDLINE
        cmp.setup.cmdline({ "/", "?" }, {
            mapping = cmp.mapping.preset.cmdline(),
            sources = { { name = "buffer" } },
        })

        cmp.setup.cmdline(":", {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({ { name = "path" } }, {
                { name = "cmdline" },
            }),
        })

        -- AUTOPAIRS
        local ok, ap = pcall(require, "nvim-autopairs.completion.cmp")
        if ok then
            cmp.event:on("confirm_done", ap.on_confirm_done())
        end
    end,
}
