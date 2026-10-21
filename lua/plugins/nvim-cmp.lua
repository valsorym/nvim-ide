-- Completion is buffer-bounded; snippets use Neovim's own snippet engine.
return {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = { "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path" },
    config = function()
        local cmp = require("cmp")
        cmp.setup({
            enabled = function() return vim.bo.buftype == "" and not require("config.performance").is_large(0) end,
            performance = { debounce = 100, throttle = 60, max_view_entries = 30 },
            snippet = { expand = function(args) vim.snippet.expand(args.body) end },
            window = { completion = cmp.config.window.bordered(), documentation = cmp.config.window.bordered() },
            completion = { completeopt = "menu,menuone,noinsert,noselect" },
            preselect = cmp.PreselectMode.None,
            mapping = cmp.mapping.preset.insert({
                ["<C-Space>"] = cmp.mapping.complete(),
                ["<C-e>"] = cmp.mapping.abort(),
                ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                ["<C-f>"] = cmp.mapping.scroll_docs(4),
                ["<Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then cmp.confirm({ select = true })
                    elseif vim.snippet.active({ direction = 1 }) then vim.snippet.jump(1)
                    else fallback() end
                end, { "i", "s" }),
                ["<S-Tab>"] = cmp.mapping(function(fallback)
                    if vim.snippet.active({ direction = -1 }) then vim.snippet.jump(-1) else fallback() end
                end, { "i", "s" }),
                ["<CR>"] = cmp.mapping(function(fallback)
                    if cmp.visible() and cmp.get_selected_entry() then cmp.confirm({ select = false }) else fallback() end
                end, { "i", "s" }),
            }),
            sources = cmp.config.sources({
                { name = "nvim_lsp", priority = 1000 },
                { name = "path", priority = 250 },
                { name = "buffer", priority = 100, keyword_length = 3, max_item_count = 30,
                    option = { get_bufnrs = function()
                        return require("config.performance").is_large(0) and {} or { vim.api.nvim_get_current_buf() }
                    end } },
            }),
            formatting = { format = function(entry, item)
                item.menu = ({ nvim_lsp = "[LSP]", buffer = "[Buffer]", path = "[Path]" })[entry.source.name]
                return item
            end },
        })
    end,
}
