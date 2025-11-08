-- ~/.config/nvim/ftplugin/htmldjango.lua
-- Django template settings with formatting protection.

-- 4 spaces indentation
vim.opt_local.expandtab = true
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4

-- Django comment strings (prefer {# #} for inline)
vim.opt_local.commentstring = "{# %s #}"

-- Enable auto-indent
vim.opt_local.autoindent = true
vim.opt_local.smartindent = true

-- CRITICAL: Disable all auto-formatting
vim.b.autoformat = true
vim.bo.formatexpr = ""

-- Disable formatting capability for HTML LSP servers
vim.api.nvim_create_autocmd("LspAttach", {
    buffer = 0,
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client then
            if client.name == "html" or
               client.name == "emmet_ls" or
               client.name == "htmldjango" or
               client.name == "jinja_lsp" then
                client.server_capabilities.documentFormattingProvider = false
                client.server_capabilities.documentRangeFormattingProvider = false

                -- Silent log (only in :messages)
                vim.api.nvim_echo({{
                    string.format("[htmldjango] Disabled formatting for %s", client.name),
                    "Comment"
                }}, false, {})
            end
        end
    end,
})

-- Django-specific keymaps for comments
local map = vim.keymap.set
local opts = {buffer = true, silent = true}

-- Normal comment: {# comment #}
map("n", "<leader>cc", function()
    local line = vim.api.nvim_get_current_line()
    local new_line = "{# " .. line .. " #}"
    vim.api.nvim_set_current_line(new_line)
end, vim.tbl_extend("force", opts, {desc = "Django inline comment"}))

-- Block comment: {% comment %} ... {% endcomment %}
map("n", "<leader>cb", function()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, {"{% comment %}"})
    vim.api.nvim_buf_set_lines(0, row + 1, row + 1, false, {"{% endcomment %}"})
    vim.api.nvim_win_set_cursor(0, {row + 1, 0})
end, vim.tbl_extend("force", opts, {desc = "Django block comment"}))

-- Visual mode: wrap selection in {% comment %}
map("v", "<leader>cb", function()
    local start_line = vim.fn.line("'<")
    local end_line = vim.fn.line("'>")

    vim.api.nvim_buf_set_lines(0, start_line - 1, start_line - 1, false, {"{% comment %}"})
    vim.api.nvim_buf_set_lines(0, end_line + 1, end_line + 1, false, {"{% endcomment %}"})

    vim.cmd("normal! gv")
end, vim.tbl_extend("force", opts, {desc = "Django block comment (visual)"}))

-- HTML comment: <!-- comment -->
map("n", "<leader>ch", function()
    local line = vim.api.nvim_get_current_line()
    local new_line = "<!-- " .. line .. " -->"
    vim.api.nvim_set_current_line(new_line)
end, vim.tbl_extend("force", opts, {desc = "HTML comment"}))

-- Override format command to do nothing (with helpful message)
map("n", "<leader>cf", function()
    vim.notify(
        "⚠️  Formatting disabled for Django templates\n" ..
        "💡 Use manual indentation instead",
        vim.log.levels.WARN
    )
end, vim.tbl_extend("force", opts, {desc = "Format (disabled)"}))

-- Override F2 to just save (no format)
map("n", "<F2>", function()
    vim.cmd("write")
    vim.notify("💾 Saved (no format)", vim.log.levels.INFO)
end, vim.tbl_extend("force", opts, {desc = "Save without format"}))

map("i", "<F2>", function()
    vim.cmd("stopinsert")
    vim.cmd("write")
    vim.notify("💾 Saved (no format)", vim.log.levels.INFO)
    vim.cmd("startinsert")
end, vim.tbl_extend("force", opts, {desc = "Save without format"}))