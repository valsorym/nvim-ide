-- ~/.config/nvim/lua/plugins/theme.lua
-- Multiple themes with Telescope switcher support

return {
    -- Catppuccin theme
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = true,
        priority = 1000,
        config = function()
            local catppuccin = require("catppuccin")

            catppuccin.setup({
                flavour = "mocha",
                background = { light = "latte", dark = "mocha" },
                transparent_background = false,
                show_end_of_buffer = false,
                term_colors = true,
                dim_inactive = {
                    enabled = true,
                    shade = "dark",
                    percentage = 0.15
                },
                no_italic = false,
                no_bold = false,
                no_underline = false,
                styles = {
                    comments = {"italic"},
                    conditionals = {},
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
                integrations = {
                    cmp = true,
                    gitsigns = true,
                    nvimtree = true,
                    treesitter = true,
                    telescope = { enabled = true },
                    which_key = false,
                    mason = true,
                    markdown = true,
                    native_lsp = {
                        enabled = true,
                        virtual_text = {
                            errors = {},
                            hints = {},
                            warnings = {},
                            information = {}
                        },
                        underlines = {
                            errors = {},
                            hints = {},
                            warnings = {},
                            information = {}
                        },
                        inlay_hints = { background = true }
                    }
                },
                custom_highlights = function(colors)
                    return {
                        -- Muted comments for all filetypes.
                        Comment = {
                            fg = colors.overlay0,
                            style = {"italic"}
                        },

                        -- Jinja2/Django template comments.
                        jinjaComment = {
                            fg = colors.overlay0,
                            style = {"italic"}
                        },
                        jinjaTagDelim = { fg = colors.overlay1 },
                        jinjaVarDelim = { fg = colors.overlay1 },
                        jinjaString = { fg = colors.green },
                        jinjaFilter = { fg = colors.mauve },

                        -- HTML comments in templates.
                        htmlComment = {
                            fg = colors.overlay0,
                            style = {"italic"}
                        },
                        htmlCommentPart = {
                            fg = colors.overlay0,
                            style = {"italic"}
                        },
                    }
                end,
            })

        end,
    },
    -- Tokyo Night theme
    {
        "folke/tokyonight.nvim",
        lazy = true,
        priority = 999,
        config = function()
            require("tokyonight").setup({
                style = "night",
                light_style = "day",
                transparent = false,
                terminal_colors = true,
                styles = {
                    comments = {italic = true},
                    keywords = {italic = true},
                    functions = {},
                    variables = {},
                    sidebars = "dark",
                    floats = "dark"
                },
                sidebars = {"qf", "help"},
                day_brightness = 0.3,
                hide_inactive_statusline = false,
                dim_inactive = true,
                lualine_bold = false
            })
        end
    },
    -- Gruvbox Material theme
    {
        "sainnhe/gruvbox-material",
        lazy = true,
        priority = 998,
        config = function()
            vim.g.gruvbox_material_background = "medium"
            vim.g.gruvbox_material_better_performance = 1
            vim.g.gruvbox_material_enable_italic = 1
            vim.g.gruvbox_material_disable_italic_comment = 0
            vim.g.gruvbox_material_enable_bold = 0
            vim.g.gruvbox_material_transparent_background = 0
            vim.g.gruvbox_material_diagnostic_text_highlight = 1
            vim.g.gruvbox_material_diagnostic_line_highlight = 1
        end
    },
    -- Kanagawa theme
    {
        "rebelot/kanagawa.nvim",
        lazy = true,
        priority = 997,
        config = function()
            require("kanagawa").setup({
                compile = false,
                undercurl = true,
                commentStyle = {italic = true},
                functionStyle = {},
                keywordStyle = {italic = true},
                statementStyle = {bold = true},
                typeStyle = {},
                transparent = false,
                dimInactive = false,
                terminalColors = true,
                colors = {
                    palette = {},
                    theme = {
                        wave = {},
                        lotus = {},
                        dragon = {},
                        all = {
                            ui = {
                                bg_gutter = "none"
                            }
                        }
                    }
                },
                overrides = function(colors)
                    return {}
                end
            })
        end
    },
    -- Nord theme
    {
        "shaunsingh/nord.nvim",
        lazy = true,
        priority = 996,
        config = function()
            vim.g.nord_contrast = true
            vim.g.nord_borders = false
            vim.g.nord_disable_background = false
            vim.g.nord_italic = true
            vim.g.nord_uniform_diff_background = true
            vim.g.nord_bold = false
        end
    },
    -- One Dark theme
    {
        "navarasu/onedark.nvim",
        lazy = true,
        priority = 995,
        config = function()
            require("onedark").setup({
                style = "dark",
                transparent = false,
                term_colors = true,
                ending_tildes = false,
                cmp_itemkind_reverse = false,
                toggle_style_key = nil,
                toggle_style_list = {
                    "dark", "darker", "cool",
                    "deep", "warm", "warmer", "light"
                },
                code_style = {
                    comments = "italic",
                    keywords = "none",
                    functions = "none",
                    strings = "none",
                    variables = "none"
                },
                lualine = {
                    transparent = false
                }
            })
        end
    },
}
