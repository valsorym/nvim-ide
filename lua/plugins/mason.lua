return {
    { "mason-org/mason.nvim", cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" }, opts = {
        ui = { border = "rounded", icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" } },
        max_concurrent_installers = 2,
    } },
    { "mason-org/mason-lspconfig.nvim", lazy = true },
}
