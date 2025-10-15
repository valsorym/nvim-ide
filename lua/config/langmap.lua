-- ~/.config/nvim/lua/config/langmap.lua
-- Ukrainian keyboard layout support.

local M = {}

function M.setup()
    -- Set true for macOS, false for Windows
    local is_mac = true  -- <<< CHANGE THIS TO false ON WINDOWS keyboard

    -- Ukrainian to English key mapping.
    local ua_to_en = {}

    if is_mac then
        -- macOS Ukrainian layout.
        ua_to_en = {
            ["й"]="q", ["ц"]="w", ["у"]="e", ["к"]="r", ["е"]="t",
            ["н"]="y", ["г"]="u", ["ш"]="i", ["щ"]="o", ["з"]="p",
            ["х"]="[", ["ї"]="]",
            ["ф"]="a", ["и"]="s", ["в"]="d", ["а"]="f", ["п"]="g",
            ["р"]="h", ["о"]="j", ["л"]="k", ["д"]="l", ["ж"]=";",
            ["є"]="'",
            ["я"]="z", ["ч"]="x", ["с"]="c", ["м"]="v", ["і"]="b",
            ["т"]="n", ["ь"]="m", ["б"]=",", ["ю"]=".",
            -- Uppercase
            ["Й"]="Q", ["Ц"]="W", ["У"]="E", ["К"]="R", ["Е"]="T",
            ["Н"]="Y", ["Г"]="U", ["Ш"]="I", ["Щ"]="O", ["З"]="P",
            ["Х"]="{", ["Ї"]="}",
            ["Ф"]="A", ["И"]="S", ["В"]="D", ["А"]="F", ["П"]="G",
            ["Р"]="H", ["О"]="J", ["Л"]="K", ["Д"]="L", ["Ж"]=":",
            ["Є"]="\"",
            ["Я"]="Z", ["Ч"]="X", ["С"]="C", ["М"]="V", ["І"]="B",
            ["Т"]="N", ["Ь"]="M", ["Б"]="<", ["Ю"]=">",
        }
    else
        -- Windows Ukrainian layout.
        ua_to_en = {
            ["й"]="q", ["ц"]="w", ["у"]="e", ["к"]="r", ["е"]="t",
            ["н"]="y", ["г"]="u", ["ш"]="i", ["щ"]="o", ["з"]="p",
            ["х"]="[", ["ї"]="]",
            ["ф"]="a", ["і"]="s", ["в"]="d", ["а"]="f", ["п"]="g",
            ["р"]="h", ["о"]="j", ["л"]="k", ["д"]="l", ["ж"]=";",
            ["є"]="'",
            ["я"]="z", ["ч"]="x", ["с"]="c", ["м"]="v", ["и"]="b",
            ["т"]="n", ["ь"]="m", ["б"]=",", ["ю"]=".",
            -- Uppercase
            ["Й"]="Q", ["Ц"]="W", ["У"]="E", ["К"]="R", ["Е"]="T",
            ["Н"]="Y", ["Г"]="U", ["Ш"]="I", ["Щ"]="O", ["З"]="P",
            ["Х"]="{", ["Ї"]="}",
            ["Ф"]="A", ["І"]="S", ["В"]="D", ["А"]="F", ["П"]="G",
            ["Р"]="H", ["О"]="J", ["Л"]="K", ["Д"]="L", ["Ж"]=":",
            ["Є"]="\"",
            ["Я"]="Z", ["Ч"]="X", ["С"]="C", ["М"]="V", ["И"]="B",
            ["Т"]="N", ["Ь"]="M", ["Б"]="<", ["Ю"]=">",
        }
    end

    -- Setup basic langmap for Normal mode commands (dd, yy, etc).
    local langmap_pairs = {}
    for ua, en in pairs(ua_to_en) do
        -- Only map letters (skip special chars).
        if en:match("^%w$") then
            table.insert(langmap_pairs, ua .. en)
        end
    end

    vim.opt.langmap = table.concat(langmap_pairs, ",")
    vim.opt.langremap = false

    -- Create reverse mapping (English to Ukrainian).
    local en_to_ua = {}
    for ua, en in pairs(ua_to_en) do
        en_to_ua[en] = ua
    end

    -- Function to duplicate leader mappings with Ukrainian keys.
    local function duplicate_leader_mappings()
        vim.schedule(function()
            local modes = {"n", "v", "x", "o"}
            local count = 0

            for _, mode in ipairs(modes) do
                local maps = vim.api.nvim_get_keymap(mode)

                for _, m in ipairs(maps) do
                    local lhs = m.lhs or ""

                    -- Only process leader mappings.
                    if lhs:match("^<[Ll]eader>") or
                       lhs:match("^ ") then

                        -- Convert English keys to Ukrainian.
                        local ua_lhs = lhs
                        for en, ua in pairs(en_to_ua) do
                            -- Escape special chars in Lua patterns.
                            local safe_en = en:gsub("([^%w])", "%%%1")
                            ua_lhs = ua_lhs:gsub(safe_en, ua)
                        end

                        -- If mapping changed, create Ukrainian duplicate.
                        if ua_lhs ~= lhs then
                            local opts = {
                                silent = m.silent == 1,
                                noremap = m.noremap == 1,
                                expr = m.expr == 1,
                                desc = m.desc,  -- Keep original description.
                            }

                            -- Get the callback or command.
                            local rhs = m.callback or m.rhs

                            if rhs then
                                local ok = pcall(vim.keymap.set, mode,
                                    ua_lhs, rhs, opts)
                                if ok then
                                    count = count + 1
                                end
                            end
                        end
                    end
                end
            end

            vim.notify(
                string.format("🇺🇦 Ukrainian: %d keymaps", count),
                vim.log.levels.INFO
            )
        end)
    end

    -- Duplicate mappings after all plugins are loaded.
    vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
            vim.defer_fn(duplicate_leader_mappings, 500)
        end,
        once = true,
    })

    -- Manual command
    vim.api.nvim_create_user_command("DuplicateUAKeymaps",
        duplicate_leader_mappings,
        { desc = "Duplicate leader keymaps with Ukrainian keys" })
end

return M