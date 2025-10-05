-- ~/.config/nvim/lua/plugins/theme.lua
-- Multiple themes with Telescope switcher support

return {
    -- Catppuccin theme
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = false,
        priority = 1000,
        config = function()
            local catppuccin = require("catppuccin")

            catppuccin.setup({
                flavour = "mocha",
                background = { light = "latte", dark = "mocha" },
                transparent_background = false,
                show_end_of_buffer = false,
                term_colors = true,
                dim_inactive = { enabled = true, shade = "dark", percentage = 0.15 },
                no_italic = false,
                no_bold = false,
                no_underline = false,
                styles = {
                    comments = {"italic"},
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
                integrations = {
                    cmp = true,
                    gitsigns = true,
                    nvimtree = true,
                    treesitter = true,
                    telescope = { enabled = true },
                    which_key = true,
                    mason = true,
                    markdown = true,
                    native_lsp = {
                        enabled = true,
                        -- Do not style text for diagnostics at all.
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
                        Comment = { fg = colors.overlay0, style = {"italic"} },

                        -- Jinja2/Django template comments.
                        jinjaComment = { fg = colors.overlay0, style = {"italic"} },
                        jinjaTagDelim = { fg = colors.overlay1 },
                        jinjaVarDelim = { fg = colors.overlay1 },
                        jinjaString = { fg = colors.green },
                        jinjaFilter = { fg = colors.mauve },

                        -- HTML comments in templates.
                        htmlComment = { fg = colors.overlay0, style = {"italic"} },
                        htmlCommentPart = { fg = colors.overlay0, style = {"italic"} },
                    }
                end,
            })

            -- Enforce "signs only": no underline/undercurl/italic on text.
            local function enforce_signs_only()
                -- Turn off diagnostic underlines globally.
                vim.diagnostic.config({ underline = false })
                -- Neutralize underline highlight groups (any colorscheme).
                local groups = {
                    "DiagnosticUnderlineError",
                    "DiagnosticUnderlineWarn",
                    "DiagnosticUnderlineInfo",
                    "DiagnosticUnderlineHint",
                }
                for _, g in ipairs(groups) do
                    pcall(vim.api.nvim_set_hl, 0, g, {
                        underline = false,
                        undercurl = false,
                        italic = false,
                        sp = "NONE"
                    })
                end
            end

            enforce_signs_only()

            -- Muted comments for Jinja/Django templates
            local function setup_template_colors()
                vim.api.nvim_set_hl(0, "Comment", {
                    fg = "#6c7086",
                    italic = true
                })
                vim.api.nvim_set_hl(0, "htmlComment", {
                    fg = "#6c7086",
                    italic = true
                })
                vim.api.nvim_set_hl(0, "htmlCommentPart", {
                    fg = "#6c7086",
                    italic = true
                })
                vim.api.nvim_set_hl(0, "jinjaComment", {
                    fg = "#6c7086",
                    italic = true
                })
            end

            setup_template_colors()

            vim.api.nvim_create_autocmd("ColorScheme", {
                callback = enforce_signs_only
            })
        end

    },
    -- Tokyo Night theme
    {
        "folke/tokyonight.nvim",
        lazy = false, -- Changed to false to load theme on startup
        priority = 999,
        config = function()
            require("tokyonight").setup(
                {
                    style = "night", -- storm, moon, night, day
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
                }
            )
        end
    },
    -- Gruvbox Material theme
    {
        "sainnhe/gruvbox-material",
        lazy = false, -- Changed to false to load theme on startup
        priority = 998,
        config = function()
            vim.g.gruvbox_material_background = "medium" -- hard, medium, soft
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
        lazy = false, -- Changed to false to load theme on startup
        priority = 997,
        config = function()
            require("kanagawa").setup(
                {
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
                }
            )
        end
    },
    -- Nord theme
    {
        "shaunsingh/nord.nvim",
        lazy = false, -- Changed to false to load theme on startup
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
        lazy = false, -- Changed to false to load theme on startup
        priority = 995,
        config = function()
            require("onedark").setup(
                {
                    style = "dark", -- dark, darker, cool, deep, warm, warmer, light
                    transparent = false,
                    term_colors = true,
                    ending_tildes = false,
                    cmp_itemkind_reverse = false,
                    toggle_style_key = nil,
                    toggle_style_list = {"dark", "darker", "cool", "deep", "warm", "warmer", "light"},
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
                }
            )
        end
    },
    -- Theme switcher plugin
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {"nvim-lua/plenary.nvim"},
        keys = {
            {
                "<leader>ut",
                "<cmd>ThemeSwitcher<cr>",
                desc = "Theme switcher"
            },
            {
                "<leader>us",
                "<cmd>ThemeSwitcherPermanent<cr>",
                desc = "Set permanent theme"
            },
            {
                "<leader>ud",
                "<cmd>lua print(vim.inspect(vim.fn.getcompletion('', 'color')))<cr>",
                desc = "Debug available themes"
            },
            {
                "<leader>ui",
                "<cmd>ThemeInfo<cr>",
                desc = "Theme info"
            }
        },
        config = function()
            -- Enhanced favorite themes list with all available variants
            local favorite_themes = {
                "catppuccin",
                "catppuccin-latte",
                "catppuccin-frappe",
                "catppuccin-macchiato",
                "catppuccin-mocha",
                "tokyonight",
                "tokyonight-night",
                "tokyonight-storm",
                "tokyonight-moon",
                "tokyonight-day",
                "gruvbox-material",
                "kanagawa",
                "kanagawa-wave",
                "kanagawa-dragon",
                "kanagawa-lotus",
                "nord",
                "onedark"
            }

            -- Function to check if theme is available and favorite
            local function is_favorite(theme_name)
                for _, fav in ipairs(favorite_themes) do
                    if theme_name == fav then
                        return true
                    end
                end
                return false
            end

            -- Function to ensure all theme plugins are loaded
            local function ensure_themes_loaded()
                -- Force load all theme plugins if not already loaded
                local theme_plugins = {
                    "tokyonight.nvim",
                    "gruvbox-material",
                    "kanagawa.nvim",
                    "nord.nvim",
                    "onedark.nvim"
                }

                for _, plugin in ipairs(theme_plugins) do
                    if not package.loaded[plugin] then
                        require("lazy").load({plugins = {plugin}})
                    end
                end

                -- Small delay to ensure themes are properly registered
                vim.defer_fn(
                    function()
                    end,
                    50
                )
            end

            -- Custom theme switcher with favorites prioritized
            local function theme_switcher()
                -- Ensure all themes are loaded first
                ensure_themes_loaded()

                local pickers = require("telescope.pickers")
                local finders = require("telescope.finders")
                local conf = require("telescope.config").values
                local actions = require("telescope.actions")
                local action_state = require("telescope.actions.state")
                local previewers = require("telescope.previewers")

                -- Get all available colorschemes after ensuring plugins are loaded
                local all_themes = vim.fn.getcompletion("", "color")

                -- Separate favorites and others
                local favorites = {}
                local others = {}

                for _, theme in ipairs(all_themes) do
                    if is_favorite(theme) then
                        table.insert(favorites, "★ " .. theme)
                    else
                        table.insert(others, "  " .. theme)
                    end
                end

                -- Sort favorites to match our preferred order
                table.sort(
                    favorites,
                    function(a, b)
                        local clean_a = a:gsub("^★ ", "")
                        local clean_b = b:gsub("^★ ", "")

                        local index_a = 999
                        local index_b = 999

                        for i, fav in ipairs(favorite_themes) do
                            if clean_a == fav then
                                index_a = i
                            end
                            if clean_b == fav then
                                index_b = i
                            end
                        end

                        return index_a < index_b
                    end
                )

                -- Combine with favorites first
                local all_entries = {}
                vim.list_extend(all_entries, favorites)

                if #others > 0 then
                    table.insert(all_entries, "") -- separator
                    table.insert(all_entries, "--- Other Themes ---")
                    table.insert(all_entries, "") -- separator
                    vim.list_extend(all_entries, others)
                end

                pickers.new(
                    {},
                    {
                        prompt_title = "Choose Colorscheme (" .. #favorites .. " favorites, " .. #others .. " others)",
                        finder = finders.new_table(
                            {
                                results = all_entries,
                                entry_maker = function(entry)
                                    if entry == "" or entry == "--- Other Themes ---" then
                                        return {
                                            value = entry,
                                            display = entry,
                                            ordinal = entry,
                                            selectable = false
                                        }
                                    end

                                    local clean_name = entry:gsub("^[★ ]*", "")
                                    return {
                                        value = clean_name,
                                        display = entry,
                                        ordinal = clean_name
                                    }
                                end
                            }
                        ),
                        sorter = conf.generic_sorter({}),
                        previewer = previewers.new_termopen_previewer(
                            {
                                get_command = function(entry)
                                    if entry and entry.selectable ~= false and entry.value ~= "" then
                                        return {
                                            "sh",
                                            "-c",
                                            string.format('echo "Theme: %s"', entry.value)
                                        }
                                    end
                                    return {"echo", ""}
                                end
                            }
                        ),
                        attach_mappings = function(prompt_bufnr, map)
                            map(
                                "i",
                                "<CR>",
                                function()
                                    local selection = action_state.get_selected_entry()
                                    if selection and selection.value ~= "" and selection.selectable ~= false then
                                        pcall(
                                            function()
                                                vim.cmd("colorscheme " .. selection.value)
                                                local file =
                                                    io.open(vim.fn.stdpath("config") .. "/.last_colorscheme", "w")
                                                if file then
                                                    file:write(selection.value)
                                                    file:close()
                                                    vim.notify(
                                                        "Theme applied: " .. selection.value,
                                                        vim.log.levels.INFO
                                                    )
                                                end
                                            end
                                        )
                                    end
                                    actions.close(prompt_bufnr)
                                end
                            )

                            return true
                        end
                    }
                ):find()
            end

            -- Permanent theme switcher with confirmation
            local function theme_switcher_permanent()
                -- Ensure all themes are loaded first
                ensure_themes_loaded()

                local pickers = require("telescope.pickers")
                local finders = require("telescope.finders")
                local conf = require("telescope.config").values
                local actions = require("telescope.actions")
                local action_state = require("telescope.actions.state")
                local previewers = require("telescope.previewers")

                -- Get all available colorschemes
                local all_themes = vim.fn.getcompletion("", "color")

                -- Separate favorites and others
                local favorites = {}
                local others = {}

                for _, theme in ipairs(all_themes) do
                    if is_favorite(theme) then
                        table.insert(favorites, "★ " .. theme)
                    else
                        table.insert(others, "  " .. theme)
                    end
                end

                -- Sort favorites to match our preferred order
                table.sort(
                    favorites,
                    function(a, b)
                        local clean_a = a:gsub("^★ ", "")
                        local clean_b = b:gsub("^★ ", "")

                        local index_a = 999
                        local index_b = 999

                        for i, fav in ipairs(favorite_themes) do
                            if clean_a == fav then
                                index_a = i
                            end
                            if clean_b == fav then
                                index_b = i
                            end
                        end

                        return index_a < index_b
                    end
                )

                -- Combine with favorites first
                local all_entries = {}
                vim.list_extend(all_entries, favorites)

                if #others > 0 then
                    table.insert(all_entries, "") -- separator
                    table.insert(all_entries, "--- Other Themes ---")
                    table.insert(all_entries, "") -- separator
                    vim.list_extend(all_entries, others)
                end

                pickers.new(
                    {},
                    {
                        prompt_title = "Set Permanent Theme",
                        finder = finders.new_table(
                            {
                                results = all_entries,
                                entry_maker = function(entry)
                                    if entry == "" or entry == "--- Other Themes ---" then
                                        return {
                                            value = entry,
                                            display = entry,
                                            ordinal = entry,
                                            selectable = false
                                        }
                                    end

                                    local clean_name = entry:gsub("^[★ ]*", "")
                                    return {
                                        value = clean_name,
                                        display = entry,
                                        ordinal = clean_name
                                    }
                                end
                            }
                        ),
                        sorter = conf.generic_sorter({}),
                        previewer = previewers.new_termopen_previewer(
                            {
                                get_command = function(entry)
                                    if entry and entry.selectable ~= false and entry.value ~= "" then
                                        return {
                                            "sh",
                                            "-c",
                                            string.format('echo "Theme: %s"', entry.value)
                                        }
                                    end
                                    return {"echo", ""}
                                end
                            }
                        ),
                        attach_mappings = function(prompt_bufnr, map)
                            map(
                                "i",
                                "<CR>",
                                function()
                                    local selection = action_state.get_selected_entry()
                                    if selection and selection.value ~= "" and selection.selectable ~= false then
                                        pcall(
                                            function()
                                                -- Apply theme
                                                vim.cmd("colorscheme " .. selection.value)

                                                -- Save permanently
                                                local file =
                                                    io.open(vim.fn.stdpath("config") .. "/.last_colorscheme", "w")
                                                if file then
                                                    file:write(selection.value)
                                                    file:close()
                                                end

                                                -- Confirmation message
                                                vim.notify(
                                                    "Permanent theme set: " .. selection.value,
                                                    vim.log.levels.INFO
                                                )
                                            end
                                        )
                                    end
                                    actions.close(prompt_bufnr)
                                end
                            )

                            return true
                        end
                    }
                ):find()
            end

            -- Current theme info command
            local function show_current_theme()
                local current = vim.g.colors_name or "none"
                local saved_file = vim.fn.stdpath("config") .. "/.last_colorscheme"
                local file = io.open(saved_file, "r")
                local saved = "none"
                if file then
                    saved = file:read("*all"):gsub("\n", "")
                    file:close()
                end

                -- Get all available themes for debugging
                ensure_themes_loaded()
                local all_themes = vim.fn.getcompletion("", "color")
                local favorite_count = 0
                for _, theme in ipairs(all_themes) do
                    if is_favorite(theme) then
                        favorite_count = favorite_count + 1
                    end
                end

                print("Current theme: " .. current)
                print("Saved theme: " .. saved)
                print("Available themes: " .. #all_themes .. " (" .. favorite_count .. " favorites)")

                if current ~= saved then
                    print("Theme changed temporarily. Use <leader>us to make permanent.")
                end
            end

            -- Create commands
            vim.api.nvim_create_user_command(
                "ThemeSwitcher",
                theme_switcher,
                {
                    desc = "Open theme switcher with preview"
                }
            )

            vim.api.nvim_create_user_command(
                "ThemeSwitcherPermanent",
                theme_switcher_permanent,
                {
                    desc = "Open theme switcher and save permanently"
                }
            )

            vim.api.nvim_create_user_command(
                "ThemeInfo",
                show_current_theme,
                {
                    desc = "Show current and saved theme info"
                }
            )

            -- Auto-apply last used theme on startup
            vim.api.nvim_create_autocmd(
                "VimEnter",
                {
                    callback = function()
                        -- Ensure all theme plugins are loaded
                        ensure_themes_loaded()

                        local last_theme_file = vim.fn.stdpath("config") .. "/.last_colorscheme"
                        local file = io.open(last_theme_file, "r")
                        if file then
                            local last_theme = file:read("*all"):gsub("\n", "")
                            file:close()
                            if last_theme and last_theme ~= "" then
                                pcall(
                                    function()
                                        vim.cmd("colorscheme " .. last_theme)
                                    end
                                )
                                return
                            end
                        end
                        -- Default theme if no saved preference
                        pcall(
                            function()
                                vim.cmd.colorscheme("catppuccin")
                            end
                        )
                    end
                }
            )
        end
    }
}
