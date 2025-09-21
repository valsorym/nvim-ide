-- Простий тест для перевірки що наші зміни застосовуються
-- Помістіть цей файл у ~/.config/nvim/ і запустіть :luafile test-telescope.lua

print("=== TELESCOPE TAB TEST ===")

-- Перевірка чи Telescope взагалі працює
local ok, telescope = pcall(require, "telescope")
if not ok then
    print("ERROR: Telescope not found")
    return
end

local builtin = require("telescope.builtin")
print("Telescope loaded successfully")

-- Створюємо простий кастомний picker для тестування
local function test_tab_picker()
    print("Starting test tab picker...")

    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    -- Створюємо простий список файлів для тестування
    local test_files = {
        "lua/config/keymaps.lua",
        "lua/plugins/additional.lua",
        "lua/plugins/lsp.lua"
    }

    pickers.new({}, {
        prompt_title = "TEST: Tab File Picker",
        finder = finders.new_table({
            results = test_files,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry,
                    ordinal = entry,
                    path = entry,
                }
            end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
            map("i", "<CR>", function()
                local entry = action_state.get_selected_entry()
                if not entry then
                    print("No entry selected")
                    return
                end

                print("SELECTED FILE: " .. entry.value)
                actions.close(prompt_bufnr)

                -- ЗАВЖДИ відкриваємо в новому табі
                print("OPENING IN NEW TAB: " .. entry.value)
                vim.cmd("tabnew " .. vim.fn.fnameescape(entry.value))
            end)

            map("n", "<CR>", function()
                local entry = action_state.get_selected_entry()
                if not entry then return end

                print("SELECTED FILE (normal): " .. entry.value)
                actions.close(prompt_bufnr)

                print("OPENING IN NEW TAB (normal): " .. entry.value)
                vim.cmd("tabnew " .. vim.fn.fnameescape(entry.value))
            end)

            return true -- Відключаємо дефолтні маппінги
        end,
    }):find()
end

-- Створюємо команду для тестування
vim.api.nvim_create_user_command("TestTabPicker", test_tab_picker, {})

print("Test setup complete. Run :TestTabPicker to test")
print("If this works, we know our approach is correct")

-- Тестуємо оригінальний find_files
local original_find_files = builtin.find_files
print("Original find_files function: " .. tostring(original_find_files))

-- Тестуємо чи можемо змінити builtin
builtin.test_function = function()
    print("Custom function added to builtin")
end

if builtin.test_function then
    print("SUCCESS: Can modify builtin functions")
    builtin.test_function()
else
    print("ERROR: Cannot modify builtin functions")
end