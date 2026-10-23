-- Load only the selected theme at startup; alternatives load when browsing themes.
local M = {}
local default_theme = "catppuccin-mocha"
local saved_path = vim.fn.stdpath("state") .. "/colorscheme"
local plugins = { "catppuccin", "tokyonight.nvim", "gruvbox-material", "kanagawa.nvim", "nord.nvim", "onedark.nvim" }

function M.pick(save)
    local before, background = vim.g.colors_name or "default", vim.o.background
    require("lazy").load({ plugins = plugins })
    if vim.g.colors_name ~= before then
        vim.o.background = background
        vim.cmd.colorscheme(before)
    end
    local colors = { before }
    for _, name in ipairs(vim.fn.getcompletion("", "color")) do
        if name ~= before then colors[#colors + 1] = name end
    end
    local opts = {
        enable_preview = true,
        finder = require("telescope.finders").new_table({ results = colors, entry_maker = function(name)
            local display = name .. (name == default_theme and " (default)" or "")
            return { value = name, ordinal = display, display = display }
        end }),
        attach_mappings = function(prompt, map)
            if save then
                local function select_and_save()
                    if not require("telescope.actions.state").get_selected_entry() then return end
                    -- Run Telescope's original selection so preview cancellation stays correct.
                    require("telescope.actions").select_default(prompt)
                    local ok, err = require("config.state").write(saved_path, vim.g.colors_name .. "\n")
                    if not ok then vim.notify(err, vim.log.levels.ERROR) end
                end
                map("i", "<CR>", select_and_save)
                map("n", "<CR>", select_and_save)
            end
            return true
        end,
    }
    if vim.bo.filetype == "dashboard" then
        opts.previewer = require("config.theme-preview").dashboard(vim.api.nvim_get_current_buf())
    end
    require("telescope.builtin").colorscheme(opts)
end

function M.setup()
    local theme = default_theme
    for _, path in ipairs({ saved_path, vim.fn.stdpath("config") .. "/.last_colorscheme" }) do
        if vim.fn.filereadable(path) == 1 then
            theme = vim.fn.readfile(path)[1] or theme
            break
        end
    end
    if not pcall(vim.cmd.colorscheme, theme) then vim.cmd.colorscheme(default_theme) end
    vim.api.nvim_create_user_command("ThemeSwitcher", function() M.pick(false) end, {})
    vim.api.nvim_create_user_command("ThemeSwitcherPermanent", function() M.pick(true) end, {})
    vim.api.nvim_create_user_command("ThemeInfo", function() vim.notify("Theme: " .. (vim.g.colors_name or "default")) end, {})
end
return M
