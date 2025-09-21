-- Перевірка що забінджено на <leader>fg
print("=== CHECKING KEYBINDINGS ===")

-- Перевіряємо що таке <leader>
print("Leader key: " .. vim.g.mapleader or "\\")

-- Перевіряємо keymap для <leader>fg
local keymaps = vim.api.nvim_get_keymap("n")
for _, keymap in ipairs(keymaps) do
    if keymap.lhs:find("fg") then
        print("Found keymap: " .. keymap.lhs .. " -> " .. (keymap.rhs or "function"))
        if keymap.callback then
            print("  Has callback function: " .. tostring(keymap.callback))
        end
        if keymap.desc then
            print("  Description: " .. keymap.desc)
        end
    end
end

-- Перевіряємо builtin функції
local builtin = require("telescope.builtin")
print("\nBuiltin live_grep function: " .. tostring(builtin.live_grep))

-- Створюємо wrapper що показує що відбувається
local original_live_grep = builtin.live_grep
builtin.live_grep = function(opts)
    print("CUSTOM: live_grep called with opts: " .. vim.inspect(opts or {}))
    return original_live_grep(opts)
end

print("Wrapper installed for live_grep")
print("Now try <leader>fg and see the debug output")