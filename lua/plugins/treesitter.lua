-- The master branch is the compatible API for Neovim 0.11; main requires 0.12.
return {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter.configs").setup({
            ensure_installed = {}, auto_install = false,
            highlight = { enable = true, additional_vim_regex_highlighting = false,
                disable = function(_, buf) return require("config.performance").is_large(buf) end },
            -- Use native filetype indentation; parser-based indentation can be expensive.
            indent = { enable = false },
        })
        vim.api.nvim_create_user_command("ParsersInstall", function()
            vim.cmd("TSInstall python javascript typescript tsx vue go c cpp dockerfile bash markdown markdown_inline gitignore htmldjango lua json yaml html css scss rst toml vim vimdoc")
        end, { desc = "Install parsers for all supported languages" })
    end,
}
