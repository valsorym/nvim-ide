-- ~/.config/nvim/lua/plugins/langmapper.lua
-- Auto-mapping for Ukrainian keyboard layout.

return {
    "Wansmer/langmapper.nvim",
    lazy = false,
    priority = 1,
    config = function()
        local langmapper = require("langmapper")

        -- Set true for macOS, false for Windows.
        _G.is_mac_keyboard = true

        langmapper.setup({
            hack_keymap = true,
            map_all_ctrl = true,
        })

        -- Automapping will handle everything.
        langmapper.automapping({
            global = true,
            buffer = true,
        })

        -- Define character mappings directly.
        local en_chars = {
            'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p',
            'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l',
            'z', 'x', 'c', 'v', 'b', 'n', 'm'
        }

        local ua_chars_mac = {
            'й', 'ц', 'у', 'к', 'е', 'н', 'г', 'ш', 'щ', 'з',
            'ф', 'і', 'в', 'а', 'п', 'р', 'о', 'л', 'д',
            'я', 'ч', 'с', 'м', 'і', 'т', 'ь'
        }

        local ua_chars_win = {
            'й', 'ц', 'у', 'к', 'е', 'н', 'г', 'ш', 'щ', 'з',
            'ф', 'і', 'в', 'а', 'п', 'р', 'о', 'л', 'д',
            'я', 'ч', 'с', 'м', 'и', 'т', 'ь'
        }

        local ua_chars = _G.is_mac_keyboard and ua_chars_mac
            or ua_chars_win

        -- Build langmap table.
        local langmap_table = {}
        for i, en_char in ipairs(en_chars) do
            local ua_char = ua_chars[i]
            if ua_char then
                table.insert(langmap_table, ua_char .. en_char)
                table.insert(langmap_table,
                    ua_char:upper() .. en_char:upper())
            end
        end

        -- Set langmap without problematic characters.
        vim.opt.langmap = table.concat(langmap_table, ',')
        vim.opt.langnoremap = false
    end,
}