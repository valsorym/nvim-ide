-- Load only the selected theme at startup; alternatives load when browsing themes.
local M = {}
local saved_path = vim.fn.stdpath("state") .. "/colorscheme"
local plugins = { "catppuccin", "tokyonight.nvim", "gruvbox-material", "kanagawa.nvim", "nord.nvim", "onedark.nvim" }

function M.pick(save)
    require("lazy").load({ plugins = plugins })
    require("telescope.builtin").colorscheme({
        enable_preview = true,
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
    })
end

function M.setup()
    local theme = "catppuccin"
    for _, path in ipairs({ saved_path, vim.fn.stdpath("config") .. "/.last_colorscheme" }) do
        if vim.fn.filereadable(path) == 1 then
            theme = vim.fn.readfile(path)[1] or theme
            break
        end
    end
    if not pcall(vim.cmd.colorscheme, theme) then vim.cmd.colorscheme("catppuccin") end
    vim.api.nvim_create_user_command("ThemeSwitcher", function() M.pick(false) end, {})
    vim.api.nvim_create_user_command("ThemeSwitcherPermanent", function() M.pick(true) end, {})
    vim.api.nvim_create_user_command("ThemeInfo", function() vim.notify("Theme: " .. (vim.g.colors_name or "default")) end, {})
end
return M
