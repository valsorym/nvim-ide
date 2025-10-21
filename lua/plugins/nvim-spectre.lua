-- ~/.config/nvim/lua/plugins/nvim-spectre.lua
-- Interactive find and replace across project files.

return {
    "nvim-pack/nvim-spectre",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        require("spectre").setup({
            color_devicons = true,
            open_cmd = "vnew",
            live_update = false,
            line_sep_start = "┌─────────────────────────────────────────",
            result_padding = "│  ",
            line_sep = "└─────────────────────────────────────────",
            highlight = {
                ui = "String",
                search = "DiffChange",
                replace = "DiffDelete",
            },
            mapping = {
                ["toggle_line"] = {
                    map = "dd",
                    cmd = "<cmd>lua require('spectre').toggle_line()<CR>",
                    desc = "Toggle current item",
                },
                ["enter_file"] = {
                    map = "<cr>",
                    cmd = "<cmd>lua require('spectre.actions')" ..
                        ".select_entry()<CR>",
                    desc = "Go to file",
                },
                ["send_to_qf"] = {
                    map = "<leader>q",
                    cmd = "<cmd>lua require('spectre.actions')" ..
                        ".send_to_qf()<CR>",
                    desc = "Send to quickfix",
                },
                ["replace_cmd"] = {
                    map = "<leader>c",
                    cmd = "<cmd>lua require('spectre.actions')" ..
                        ".replace_cmd()<CR>",
                    desc = "Input replace command",
                },
                ["show_option_menu"] = {
                    map = "<leader>o",
                    cmd = "<cmd>lua require('spectre').show_options()<CR>",
                    desc = "Show options",
                },
                ["run_current_replace"] = {
                    map = "<leader>rc",
                    cmd = "<cmd>lua require('spectre.actions')" ..
                        ".run_current_replace()<CR>",
                    desc = "Replace current line",
                },
                ["run_replace"] = {
                    map = "<leader>R",
                    cmd = "<cmd>lua require('spectre.actions')" ..
                        ".run_replace()<CR>",
                    desc = "Replace all",
                },
                ["change_view_mode"] = {
                    map = "<leader>v",
                    cmd = "<cmd>lua require('spectre').change_view()<CR>",
                    desc = "Change result view mode",
                },
                ["change_replace_sed"] = {
                    map = "trs",
                    cmd = "<cmd>lua require('spectre').change_engine_replace" ..
                        "('sed')<CR>",
                    desc = "Use sed",
                },
                ["change_replace_oxi"] = {
                    map = "tro",
                    cmd = "<cmd>lua require('spectre').change_engine_replace" ..
                        "('oxi')<CR>",
                    desc = "Use oxi",
                },
                ["toggle_live_update"] = {
                    map = "tu",
                    cmd = "<cmd>lua require('spectre').toggle_live_update()" ..
                        "<CR>",
                    desc = "Toggle live update",
                },
                ["toggle_ignore_case"] = {
                    map = "ti",
                    cmd = "<cmd>lua require('spectre').change_options" ..
                        "('ignore-case')<CR>",
                    desc = "Toggle ignore case",
                },
                ["toggle_ignore_hidden"] = {
                    map = "th",
                    cmd = "<cmd>lua require('spectre').change_options" ..
                        "('hidden')<CR>",
                    desc = "Toggle hidden files",
                },
                ["resume_last_search"] = {
                    map = "<leader>l",
                    cmd = "<cmd>lua require('spectre').resume_last_search()" ..
                        "<CR>",
                    desc = "Resume last search",
                },
            },
            find_engine = {
                ["rg"] = {
                    cmd = "rg",
                    args = {
                        "--color=never",
                        "--no-heading",
                        "--with-filename",
                        "--line-number",
                        "--column",
                    },
                    options = {
                        ["ignore-case"] = {
                            value = "--ignore-case",
                            icon = "[I]",
                            desc = "Ignore case",
                        },
                        ["hidden"] = {
                            value = "--hidden",
                            desc = "Hidden files",
                            icon = "[H]",
                        },
                    },
                },
            },
            replace_engine = {
                ["sed"] = {
                    cmd = "sed",
                    args = nil,
                    options = {
                        ["ignore-case"] = {
                            value = "--ignore-case",
                            icon = "[I]",
                            desc = "Ignore case",
                        },
                    },
                },
            },
            default = {
                find = {
                    cmd = "rg",
                    options = {"ignore-case"},
                },
                replace = {
                    cmd = "sed",
                },
            },
            replace_vim_cmd = "cdo",
            is_open_target_win = true,
            is_insert_mode = false,
        })

        -- Additional keymaps for quick access
        vim.keymap.set("n", "<leader>fc", function()
            require("spectre").toggle()
        end, {desc = "Live Change (Find & Replace)"})

        -- Search current word
        vim.keymap.set("n", "<leader>fw", function()
            require("spectre").open_visual({select_word = true})
        end, {desc = "Search current word"})

        -- Search in current file
        vim.keymap.set("n", "<leader>fp", function()
            require("spectre").open_file_search({select_word = true})
        end, {desc = "Search in current file"})

        -- Visual mode search
        vim.keymap.set("v", "<leader>fc", function()
            require("spectre").open_visual()
        end, {desc = "Search selected text"})
    end,
}