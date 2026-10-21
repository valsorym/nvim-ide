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
    vim.health.info("Language servers: :checkhealth vim.lsp; installers: :Mason / :LanguageToolsInstall")
end
return M
