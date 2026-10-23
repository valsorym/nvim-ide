local M = {}
function M.check()
    vim.health.start("Neovim IDE")
    if vim.fn.has("nvim-0.11.3") == 1 then vim.health.ok("Neovim 0.11.3+") else vim.health.error("Neovim 0.11.3+ required") end
    for _, exe in ipairs({ "git", "rg" }) do
        if vim.fn.executable(exe) == 1 then vim.health.ok(exe .. " available") else vim.health.error(exe .. " missing") end
    end
    vim.health.info("TERM=" .. (vim.env.TERM or "") .. "; COLORTERM=" .. (vim.env.COLORTERM or ""))
    if vim.o.termguicolors then vim.health.ok("24-bit colour enabled") else vim.health.warn("termguicolors is disabled") end
    if vim.env.TMUX then
        local result = vim.system({ "tmux", "display-message", "-p", "#{client_termname} #{client_termfeatures}" }, { text = true }):wait(1000)
        if result.code == 0 and result.stdout:find("RGB", 1, true) then
            vim.health.ok("tmux client advertises RGB: " .. vim.trim(result.stdout))
        else
            vim.health.warn("tmux client does not advertise RGB; load extras/tmux.conf and reconnect the client")
        end
    end
    vim.health.info("Ukrainian layout: " .. (vim.g.nvim_ide_ukrainian_layout or "mac") .. "; langremap=" .. tostring(vim.o.langremap))
    vim.health.info("Large-file limits: " .. (vim.g.nvim_ide_large_file_bytes or 1048576) .. " bytes / "
        .. (vim.g.nvim_ide_large_file_lines or 20000) .. " lines")
    if vim.fn.executable("alacritty") == 1 then vim.health.ok("Desktop launcher: Alacritty available") end
    vim.health.start("Language tools")
    local tools = require("config.tools")
    local missing = {}
    for _, name in ipairs({ "ruff", "black", "isort", "prettier", "stylua", "gofmt", "rustfmt", "shfmt", "clang-format" }) do
        local path = tools.executable(name, 0)
        if path then vim.health.ok(name .. ": " .. path) else missing[#missing + 1] = name end
    end
    vim.health.info("Optional formatters not installed: " .. table.concat(missing, ", "))
    vim.health.info("Python formatter preference: " .. (vim.g.nvim_ide_python_formatter or "ruff") .. "; Black/isort fallback")
    for _, name in ipairs({ "node", "make" }) do
        if vim.fn.executable(name) == 1 then vim.health.ok(name .. " available")
        else vim.health.info(name .. " absent (optional runtime/build tool)") end
    end
    local servers = { "pyright-langserver", "typescript-language-server", "vue-language-server", "vscode-html-language-server",
        "vscode-css-language-server", "emmet-ls", "gopls", "clangd", "docker-langserver", "yaml-language-server",
        "vscode-json-language-server", "lua-language-server", "bash-language-server", "marksman" }
    local absent = {}
    for _, name in ipairs(servers) do
        if vim.fn.executable(name) == 1 then vim.health.ok(name .. " available") else absent[#absent + 1] = name end
    end
    if #absent > 0 then vim.health.info("Uninstalled language servers: " .. table.concat(absent, ", ") .. "; :Mason / :LanguageToolsInstall") end
    vim.health.start("Parsers and compatibility")
    for _, lang in ipairs({ "markdown", "markdown_inline", "python", "lua", "cpp" }) do
        local ok, added = pcall(vim.treesitter.language.add, lang)
        if ok and added then vim.health.ok(lang .. " parser available")
        else vim.health.info(lang .. " parser missing; :ParsersInstall") end
    end
    if vim.fn.has("nvim-0.12") == 1 then
        vim.health.info("This release is tested on Neovim 0.11; Tree-sitter 0.12 migration needs a separate compatibility check")
    end
    vim.health.info("Ukrainian command aliases use the keymap registration API; recheck them after Neovim/plugin upgrades")
    vim.health.info("Language clients: :checkhealth vim.lsp")
end
return M
