-- Translate command keys by physical QWERTY position, without touching text.
local M = {}

function M.setup()
    local ukrainian = "йцукенгшщзхїфівапролджєячсмитьбю"
    local english = "qwertyuiop[]asdfghjkl;'zxcvbnm,."
    local upper_ua = "ЙЦУКЕНГШЩЗХЇФІВАПРОЛДЖЄЯЧСМИТЬБЮ"
    local upper_en = "QWERTYUIOP{}ASDFGHJKL:\"ZXCVBNM<>"
    local layout = vim.g.nvim_ide_ukrainian_layout or vim.env.NVIM_IDE_UKRAINIAN_LAYOUT or "mac"
    assert(layout == "mac" or layout == "windows", "Ukrainian layout must be mac or windows")
    vim.g.nvim_ide_ukrainian_layout = layout
    -- Apple Ukrainian swaps the physical positions of і and и.
    if layout == "mac" then
        ukrainian = vim.fn.tr(ukrainian, "іи", "иі")
        upper_ua = vim.fn.tr(upper_ua, "ІИ", "ИІ")
    end
    local pairs, alternatives = {}, {}
    for i, char in ipairs(vim.fn.split(ukrainian .. upper_ua, "\\zs")) do
        local target = (english .. upper_en):sub(i, i)
        alternatives[target] = char
        -- Comma, semicolon and backslash are delimiters in 'langmap'.
        target = target:gsub("([,;\\\"|])", "\\%1")
        pairs[#pairs + 1] = char .. target
    end
    vim.opt.langmap = table.concat(pairs, ",")
    -- Only typed keys are translated; mapping results and inserted text stay intact.
    vim.opt.langremap = false

    -- langmap handles native commands, but user maps need actual UTF-8 aliases.
    -- Register them with the original mapping so lazy plugins and buffer-local
    -- maps work immediately. No keypress hooks or layout polling.
    if M.installed then return end
    M.installed = true
    local function aliases(lhs)
        if lhs:lower():find("<plug>", 1, true) then return {} end
        local variants, i, count = { "" }, 1, 0
        while i <= #lhs do
            local token = lhs:sub(i):match("^<[^>]+>")
            local char = token or lhs:sub(i, i)
            local shift = token and token:match("^<[Ss]%-([a-zA-Z])>$")
            local alt = alternatives[shift and shift:upper() or char]
            if alt then
                count = count + 1
                -- Bound expansion for plugins with unusually long mnemonic maps.
                if count > 5 then return {} end
                local size = #variants
                for j = 1, size do
                    variants[size + j] = variants[j] .. alt
                    variants[j] = variants[j] .. char
                end
            else
                for j = 1, #variants do variants[j] = variants[j] .. char end
            end
            i = i + #char
        end
        table.remove(variants, 1)
        return variants
    end
    M.aliases = aliases
    local function command_mode(mode)
        return mode == "n" or mode == "v" or mode == "x" or mode == "o" or mode == ""
    end
    -- Neovim registers a few defaults (gc, grr, grn, ...) before init.lua.
    -- Copy those once; later registrations go through the hooks below.
    for _, mode in ipairs({ "n", "x", "o" }) do
        for _, mapping in ipairs(vim.api.nvim_get_keymap(mode)) do
            local opts = {
                noremap = mapping.noremap == 1, silent = mapping.silent == 1,
                expr = mapping.expr == 1, nowait = mapping.nowait == 1,
                script = mapping.script == 1, desc = mapping.desc, callback = mapping.callback,
            }
            for _, lhs in ipairs(aliases(mapping.lhs)) do
                if vim.fn.maparg(lhs, mode) == "" then
                    vim.api.nvim_set_keymap(mode, lhs, mapping.rhs or "", opts)
                end
            end
        end
    end
    for _, scope in ipairs({ "", "buf_" }) do
        local set_name, del_name = "nvim_" .. scope .. "set_keymap", "nvim_" .. scope .. "del_keymap"
        local set, delete = vim.api[set_name], vim.api[del_name]
        local offset = scope == "" and 0 or 1
        vim.api[set_name] = function(...)
            local args = { ... }
            set(unpack(args))
            if not command_mode(args[1 + offset]) then return end
            for _, lhs in ipairs(aliases(args[2 + offset])) do
                args[2 + offset] = lhs
                set(unpack(args))
            end
        end
        vim.api[del_name] = function(...)
            local args = { ... }
            delete(unpack(args))
            if not command_mode(args[1 + offset]) then return end
            for _, lhs in ipairs(aliases(args[2 + offset])) do
                args[2 + offset] = lhs
                pcall(delete, unpack(args))
            end
        end
    end
end

return M
