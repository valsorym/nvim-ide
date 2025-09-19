-- ~/.config/nvim/lua/plugins/theme.lua
-- Catppuccin - modern dark theme with great plugin support.

return {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
        require("catppuccin").setup(
            {
                flavour = "mocha", -- latte, frappe, macchiato, mocha
                background = {
                    -- :h background
                    light = "latte",
                    dark = "mocha"
                },
                transparent_background = false,
                show_end_of_buffer = false, -- shows the '~' characters after end of buffers
                term_colors = true, -- sets terminal colors
                dim_inactive = {
                    enabled = true, -- dims the background color of inactive window
                    shade = "dark",
                    percentage = 0.15 -- percentage of the shade to apply
                },
                no_italic = false, -- force no italic
                no_bold = false, -- force no bold
                no_underline = false, -- force no underline
                styles = {
                    -- handles the styles of general highlights
                    comments = {"italic"}, -- change the style of comments
                    conditionals = {"italic"},
                    loops = {},
                    functions = {},
                    keywords = {},
                    strings = {},
                    variables = {},
                    numbers = {},
                    booleans = {},
                    properties = {},
                    types = {},
                    operators = {}
                },
                color_overrides = {},
                custom_highlights = {},
                integrations = {
                    cmp = true,
                    gitsigns = true,
                    nvimtree = true,
                    treesitter = true,
                    notify = false,
                    mini = {
                        enabled = true,
                        indentscope_color = ""
                    },
                    -- Plugin integrations
                    telescope = {
                        enabled = true
                    },
                    which_key = true,
                    mason = true,
                    markdown = true,
                    dashboard = true,
                    lsp_trouble = false,
                    ts_rainbow = false,
                    hop = false,
                    illuminate = {
                        enabled = true,
                        lsp = false
                    },
                    native_lsp = {
                        enabled = true,
                        virtual_text = {
                            errors = {"italic"},
                            hints = {"italic"},
                            warnings = {"italic"},
                            information = {"italic"}
                        },
                        underlines = {
                            errors = {"underline"},
                            hints = {"underline"},
                            warnings = {"underline"},
                            information = {"underline"}
                        },
                        inlay_hints = {
                            background = true
                        }
                    }
                }
            }
        )

        -- Set colorscheme.
        vim.cmd.colorscheme("catppuccin")

        -- Optional: Custom highlights for better experience.
        vim.api.nvim_create_autocmd(
            "ColorScheme",
            {
                pattern = "catppuccin*",
                callback = function()
                    -- Make line numbers more subtle.
                    vim.api.nvim_set_hl(
                        0,
                        "LineNr",
                        {
                            fg = "#585b70",
                            bg = "NONE"
                        }
                    )

                    -- Enhance cursor line number.
                    vim.api.nvim_set_hl(
                        0,
                        "CursorLineNr",
                        {
                            fg = "#f9e2af",
                            bg = "#1e1e2e",
                            bold = true
                        }
                    )

                    -- Better colorcolumn.
                    vim.api.nvim_set_hl(
                        0,
                        "ColorColumn",
                        {
                            bg = "#1e1e2e"
                        }
                    )

                    -- Subtle virtual text for diagnostics.
                    vim.api.nvim_set_hl(
                        0,
                        "DiagnosticVirtualTextError",
                        {
                            fg = "#f38ba8",
                            bg = "#302030",
                            italic = true
                        }
                    )
                    vim.api.nvim_set_hl(
                        0,
                        "DiagnosticVirtualTextWarn",
                        {
                            fg = "#fab387",
                            bg = "#302820",
                            italic = true
                        }
                    )
                    vim.api.nvim_set_hl(
                        0,
                        "DiagnosticVirtualTextInfo",
                        {
                            fg = "#89dceb",
                            bg = "#1a2030",
                            italic = true
                        }
                    )
                    vim.api.nvim_set_hl(
                        0,
                        "DiagnosticVirtualTextHint",
                        {
                            fg = "#94e2d5",
                            bg = "#1a302a",
                            italic = true
                        }
                    )
                end
            }
        )
    end
}
