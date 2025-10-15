-- ~/.config/nvim/lua/config/langmap.lua
-- Physical keyboard position mapping with layout detection

local M = {}

function M.setup()
    -- Set true for macOS, false for Windows
    local is_mac = true  -- <<< CHANGE THIS TO false ON WINDOWS

    -- Ukrainian to English key mapping
    local ua_to_en = {}

    if is_mac then
        -- macOS Ukrainian layout
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
        -- Windows Ukrainian layout
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

    -- Create reverse mapping (English to Ukrainian)
    local en_to_ua = {}
    for ua, en in pairs(ua_to_en) do
        en_to_ua[en] = ua
    end

    -- Store current layout state
    M.current_layout = "en"
    M.last_key_time = 0

    -- Detect layout based on last typed character
    function M.detect_layout()
        local bufnr = vim.api.nvim_get_current_buf()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local row, col = cursor[1], cursor[2]

        if col > 0 then
            local line = vim.api.nvim_buf_get_lines(
                bufnr, row - 1, row, false)[1] or ""
            if #line >= col then
                local char = line:sub(col, col)
                if ua_to_en[char] then
                    M.current_layout = "ua"
                    M.last_key_time = vim.loop.now()
                    return "ua"
                elseif char:match("[a-zA-Z]") then
                    M.current_layout = "en"
                    M.last_key_time = vim.loop.now()
                    return "en"
                end
            end
        end

        return M.current_layout
    end

    -- Trigger layout change event
    function M.trigger_layout_change()
        vim.api.nvim_exec_autocmds("User", { pattern = "LayoutChanged" })
    end

    -- Hook into InsertCharPre to detect layout changes
    vim.api.nvim_create_autocmd("InsertCharPre", {
        callback = function()
            local char = vim.v.char
            local old_layout = M.current_layout

            if ua_to_en[char] then
                M.current_layout = "ua"
            elseif char:match("[a-zA-Z]") then
                M.current_layout = "en"
            end

            if old_layout ~= M.current_layout then
                M.trigger_layout_change()
            end
        end,
        desc = "Detect keyboard layout"
    })

    -- Function to get clean English keys from lhs
    local function get_english_keys(lhs)
        local keys = lhs:gsub("^<[Ll]eader>", ""):gsub("^ ", "")
        return keys
    end

    -- Setup operator mappings for Ukrainian layout
    local function setup_operator_mappings()
        -- DON'T map Space here - which-key handles it automatically

        -- Common Vim operators that need Ukrainian equivalents
        local operators = {
            -- Delete operations
            {en = "d", ua = en_to_ua["d"], desc = "Delete"},
            {en = "dd", ua = en_to_ua["d"] .. en_to_ua["d"], desc = "Delete line"},
            {en = "D", ua = en_to_ua["D"], desc = "Delete to end"},

            -- Yank operations
            {en = "y", ua = en_to_ua["y"], desc = "Yank"},
            {en = "yy", ua = en_to_ua["y"] .. en_to_ua["y"], desc = "Yank line"},
            {en = "Y", ua = en_to_ua["Y"], desc = "Yank to end"},

            -- Change operations
            {en = "c", ua = en_to_ua["c"], desc = "Change"},
            {en = "cc", ua = en_to_ua["c"] .. en_to_ua["c"], desc = "Change line"},
            {en = "C", ua = en_to_ua["C"], desc = "Change to end"},

            -- Visual mode
            {en = "v", ua = en_to_ua["v"], desc = "Visual mode"},
            {en = "V", ua = en_to_ua["V"], desc = "Visual line mode"},

            -- Insert/Append modes
            {en = "i", ua = en_to_ua["i"], desc = "Insert mode"},
            {en = "I", ua = en_to_ua["I"], desc = "Insert at line start"},
            {en = "a", ua = en_to_ua["a"], desc = "Append after cursor"},
            {en = "A", ua = en_to_ua["A"], desc = "Append at line end"},
            {en = "o", ua = en_to_ua["o"], desc = "Open line below"},
            {en = "O", ua = en_to_ua["O"], desc = "Open line above"},

            -- Other common operators
            {en = "p", ua = en_to_ua["p"], desc = "Paste after"},
            {en = "P", ua = en_to_ua["P"], desc = "Paste before"},
            {en = "x", ua = en_to_ua["x"], desc = "Delete char"},
            {en = "X", ua = en_to_ua["X"], desc = "Delete char before"},
            {en = "s", ua = en_to_ua["s"], desc = "Substitute char"},
            {en = "S", ua = en_to_ua["S"], desc = "Substitute line"},
            {en = "r", ua = en_to_ua["r"], desc = "Replace char"},
            {en = "u", ua = en_to_ua["u"], desc = "Undo"},
            {en = "U", ua = en_to_ua["U"], desc = "Undo line"},
        }

        local count = 0
        for _, op in ipairs(operators) do
            if op.ua and op.ua ~= op.en then
                -- Normal mode mapping
                vim.keymap.set("n", op.ua, op.en, {
                    noremap = true,
                    silent = true,
                    desc = op.desc .. " (UA)"
                })

                -- Visual mode for operators that make sense there
                if op.en:match("^[dycxsp]$") then
                    vim.keymap.set("v", op.ua, op.en, {
                        noremap = true,
                        silent = true,
                        desc = op.desc .. " (UA)"
                    })
                end

                count = count + 1
            end
        end

        -- Additional motion operators
        local motions = {
            {en = "w", ua = en_to_ua["w"]},
            {en = "b", ua = en_to_ua["b"]},
            {en = "e", ua = en_to_ua["e"]},
            {en = "h", ua = en_to_ua["h"]},
            {en = "j", ua = en_to_ua["j"]},
            {en = "k", ua = en_to_ua["k"]},
            {en = "l", ua = en_to_ua["l"]},
            {en = "0", ua = "0"},
            {en = "$", ua = "$"},
            {en = "^", ua = "^"},
            {en = "gg", ua = en_to_ua["g"] .. en_to_ua["g"]},
            {en = "G", ua = en_to_ua["G"]},
        }

        for _, motion in ipairs(motions) do
            if motion.ua and motion.ua ~= motion.en then
                vim.keymap.set({"n", "v", "o"}, motion.ua, motion.en, {
                    noremap = true,
                    silent = true
                })
            end
        end

        return count
    end

    -- Function to duplicate leader mappings with Ukrainian keys
    local function duplicate_leader_mappings()
        vim.schedule(function()
            local modes = {"n", "v", "x", "o"}
            local count = 0

            for _, mode in ipairs(modes) do
                local maps = vim.api.nvim_get_keymap(mode)

                for _, m in ipairs(maps) do
                    local lhs = m.lhs or ""

                    if lhs:match("^<[Ll]eader>") or lhs:match("^ ") then
                        local ua_lhs = lhs
                        for en, ua in pairs(en_to_ua) do
                            local safe_en = en:gsub("([^%w])", "%%%1")
                            ua_lhs = ua_lhs:gsub(safe_en, ua)
                        end

                        if ua_lhs ~= lhs then
                            local description = m.desc
                            if not description or description == "" then
                                local en_keys = get_english_keys(lhs)
                                description = string.format("[%s]", en_keys)
                            end

                            local opts = {
                                silent = m.silent == 1,
                                noremap = m.noremap == 1,
                                expr = m.expr == 1,
                                desc = description,
                            }

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

            -- Setup operator mappings
            local op_count = setup_operator_mappings()

            vim.notify(
                string.format(
                    "🇺🇦 Ukrainian keymaps: %d leader + %d operators = %d total",
                    count, op_count, count + op_count
                ),
                vim.log.levels.INFO
            )
        end)
    end

    -- Duplicate mappings after all plugins are loaded
    vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
            vim.defer_fn(duplicate_leader_mappings, 500)
        end,
        once = true,
    })

    -- Manual commands
    vim.api.nvim_create_user_command("DuplicateUAKeymaps",
        duplicate_leader_mappings,
        { desc = "Duplicate leader keymaps with Ukrainian keys" })

    vim.api.nvim_create_user_command("CheckLayout",
        function()
            M.detect_layout()
            vim.notify(
                string.format("Current layout: %s",
                    M.current_layout == "ua" and "🇺🇦 Ukrainian" or "🇬🇧 English"),
                vim.log.levels.INFO
            )
            M.trigger_layout_change()
        end,
        { desc = "Check current keyboard layout" })

    vim.api.nvim_create_user_command("SetLayoutUA",
        function()
            M.current_layout = "ua"
            M.trigger_layout_change()
            vim.notify("Layout set to: 🇺🇦 Ukrainian", vim.log.levels.INFO)
        end,
        { desc = "Set layout to Ukrainian" })

    vim.api.nvim_create_user_command("SetLayoutEN",
        function()
            M.current_layout = "en"
            M.trigger_layout_change()
            vim.notify("Layout set to: 🇬🇧 English", vim.log.levels.INFO)
        end,
        { desc = "Set layout to English" })

    -- Store module globally
    _G.LangmapHelper = M
    M.ua_to_en = ua_to_en
    M.en_to_ua = en_to_ua
end

return M