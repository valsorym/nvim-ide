# Neovim IDE Configuration

Повнофункціональна IDE конфігурація для Neovim з підтримкою Python + Django, JavaScript/TypeScript, Vue.js, C/C++, Go та інших мов програмування.

## Особливості

### 🐍 Python + Django
- Автоматичне виявлення віртуального середовища (.venv, venv)
- Підтримка Django шаблонів (htmldjango, jinja2)
- Автоматичне сортування imports з isort
- Форматування коду з Black
- LSP підтримка з Pyright
- Django management команди через термінал

### 🌐 Web Development
- HTML/CSS/JavaScript/TypeScript повна підтримка
- Vue.js з Vue Language Server
- CSS/JS у `<style>` та `<script>` блоках HTML файлів
- Emmet для швидкого написання HTML/CSS
- Prettier для форматування
- JSON схеми з SchemaStore

### 🚀 Основні можливості
- LSP сервери для 10+ мов програмування
- Інтелігентний файловий менеджер (nvim-tree) з режимом вкладок
- Telescope для швидкого пошуку файлів і тексту
- Git інтеграція з gitsigns
- Багатофункціональний термінал з toggleterm
- Автоматичне закриття дужок і парних символів
- Розумні коментарі для всіх мов
- Treesitter для точного підсвічування синтаксису
- Which-key для інтуїтивної навігації
- Автоматичне форматування при збереженні

## Комбінації клавіш

### 📁 Файли та навігація

| Клавіші | Дія |
|---------|-----|
| `F9` | Відкрити/закрити файловий менеджер |
| `<leader>ef` | Знайти поточний файл у дереві |
| `<leader>ff` | Знайти файли (Telescope) |
| `<leader>fg` | Пошук тексту в проекті (Live Grep) |
| `<leader>fb` | Список відкритих буферів |
| `<leader>fh` | Довідка (Help tags) |
| `<leader>fs` | Символи в документі |
| `<leader>fw` | Символи в робочій області |

### 🗂️ Вкладки (Tabs)

| Клавіші | Дія |
|---------|-----|
| `Alt + Left` / `F5` | Попередня вкладка |
| `Alt + Right` / `F6` | Наступна вкладка |
| `Alt + 1-9` | Перейти до вкладки 1-9 |
| `Alt + h` | Перемістити вкладку ліворуч |
| `Alt + l` | Перемістити вкладку праворуч |
| `<leader>tt` | Список всіх відкритих вкладок |

**У файловому менеджері:**
- `t` - перемикання між режимом файлів і вкладок
- `Enter` - відкрити файл у новій вкладці або перейти до існуючої

### 🖥️ Термінал

| Клавіші | Дія |
|---------|-----|
| `Ctrl + \` | Відкрити/закрити плаваючий термінал |
| `<leader>tf` | Плаваючий термінал |
| `<leader>th` | Горизонтальний термінал |
| `<leader>tv` | Вертикальний термінал (ширина 80) |
| `<leader>tp` | Python термінал (з віртуальним середовищем) |
| `<leader>td` | Django shell |
| `<leader>tr` | Django runserver |
| `<leader>tn` | Node.js термінал |

### 🔤 LSP (Language Server)

| Клавіші | Дія |
|---------|-----|
| `gd` | Перейти до визначення |
| `gD` | Перейти до декларації |
| `gr` | Показати всі посилання |
| `gi` | Перейти до реалізації |
| `K` | Показати документацію |
| `<C-k>` | Допомога з сигнатурою |
| `<leader>ca` | Дії коду (Code Actions) |
| `<leader>rn` | Перейменувати символ |

### 🧹 Форматування та збереження

| Клавіші | Дія |
|---------|-----|
| `F2` | Розумне збереження + форматування |
| `<leader>f` | Форматувати поточний буфер |
| `<leader>F` | Форматувати документ |
| `<leader>tf` | Увімкнути/вимкнути авто-форматування при збереженні |
| `<leader>is` | Сортувати Python imports (isort) |

### 🔍 Діагностика

| Клавіші | Дія |
|---------|-----|
| `]d` | Наступна помилка/попередження |
| `[d` | Попередня помилка/попередження |
| `<leader>d` | Показати діагностику у плаваючому вікні |
| `<leader>q` | Відкрити список помилок (quickfix) |

### 📝 Редагування

| Клавіші | Дія |
|---------|-----|
| `gcc` | Закоментувати/розкоментувати рядок |
| `gbc` | Блочний коментар |
| `gcO` | Коментар вище |
| `gco` | Коментар нижче |
| `gcA` | Коментар в кінці рядка |
| `<` / `>` | Зменшити/збільшити відступ (з збереженням виділення) |
| `Alt + j/k` | Перемістити рядки вгору/вниз |
| `J/K` (візуальний режим) | Перемістити блоки вгору/вниз |

### 🪟 Вікна

| Клавіші | Дія |
|---------|-----|
| `<C-h/j/k/l>` | Навігація між вікнами |
| `<C-Up/Down>` | Змінити висоту вікна |
| `<C-Left/Right>` | Змінити ширину вікна |

### 🐙 Git

| Клавіші | Дія |
|---------|-----|
| `<leader>hs` | Додати hunk до індексу |
| `<leader>hr` | Скасувати зміни у hunk |
| `<leader>hp` | Попередній перегляд hunk |
| `<leader>hb` | Показати blame для рядка |
| `<leader>tb` | Увімкнути/вимкнути показ blame |
| `<leader>hd` | Показати diff |
| `]c` | Наступний hunk |
| `[c` | Попередній hunk |

### 🔧 Система та інші

| Клавіші | Дія |
|---------|-----|
| `<leader>m` | Відкрити Mason (менеджер LSP) |
| `<leader>vs` | Вибрати Python віртуальне середовище |
| `<leader>qq` | Вийти з усіх вкладок |
| `<leader>qQ` | Примусово вийти |
| `<leader>h` | Очистити підсвічування пошуку |

## Встановлення

### Передумови

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install neovim git curl build-essential nodejs npm python3-pip ripgrep

# Arch Linux
sudo pacman -S neovim git curl base-devel nodejs npm python-pip ripgrep

# macOS
brew install neovim git curl node python ripgrep
```

### Python інструменти

```bash
# Глобально
pip3 install black isort

# Або у віртуальному середовищі проекту
python -m venv .venv
source .venv/bin/activate  # Linux/macOS
pip install black isort
```

### Встановлення конфігурації

```bash
# Резервна копія існуючої конфігурації
mv ~/.config/nvim ~/.config/nvim.backup

# Клонування конфігурації
git clone <your-repo> ~/.config/nvim

# Запуск Neovim (плагіни встановляться автоматично)
nvim
```

При першому запуску:
1. Lazy.nvim автоматично встановить всі плагіни
2. Mason встановить необхідні LSP сервери
3. Treesitter завантажить парсери для мов програмування

## Структура проекту

```
~/.config/nvim/
├── init.lua                              # Головний файл конфігурації
├── after/plugin/
│   └── nvimtree-autoclose.lua           # Автозакриття порожніх вкладок
└── lua/
    ├── config/
    │   ├── colorcolumn.lua              # Вертикальна лінія на 79 символів
    │   ├── keymaps.lua                  # Централізовані гарячі клавіші
    │   ├── line-numbers.lua             # Розумні номери рядків
    │   └── nvim-tabs.lua                # Кастомні вкладки з parent/filename
    └── plugins/
        ├── additional.lua               # Treesitter, Telescope, Git, Terminal
        ├── completion.lua               # nvim-cmp з LuaSnip
        ├── dashboard.lua                # Стартовий екран
        ├── formatting.lua               # null-ls для форматування
        ├── lsp.lua                      # LSP конфігурація для всіх мов
        ├── mason.lua                    # Менеджер LSP серверів
        ├── nvim-tree.lua               # Файловий менеджер з режимом вкладок
        ├── tabs-list.lua               # Незалежний список вкладок
        ├── theme.lua                    # Catppuccin тема
        └── which-key.lua               # Допомога з гарячими клавішами
```

## Підтримувані мови програмування

| Мова | LSP Server | Форматер | Особливості |
|------|------------|----------|-------------|
| **Python** | Pyright | Black + isort | Django шаблони, venv detection |
| **JavaScript/TypeScript** | ts_ls | Prettier | Inlay hints, автоімпорт |
| **Vue.js** | vue_ls | Prettier | Single File Components |
| **HTML** | html | Prettier | Django template support |
| **CSS/SCSS** | cssls | Prettier | Emmet integration |
| **Go** | gopls | goimports | Автоматичні imports |
| **C/C++** | clangd | clang-format | Background indexing |
| **Lua** | lua_ls | stylua | Neovim API support |
| **JSON** | jsonls | Prettier | Schema validation |
| **YAML** | yamlls | Prettier | GitHub Actions, Docker Compose |
| **Docker** | dockerls | - | Dockerfile підтримка |
| **Bash** | bashls | - | Shell scripting |

## Особливості конфігурації

### Розумні вкладки
- Показують parent/filename для кращої навігації
- Автоматичне закриття порожніх вкладок з лише NvimTree
- Збереження останньої вкладки з новим пустим файлом

### Файловий менеджер з двома режимами
- **Файли**: стандартний вигляд дерева файлів
- **Вкладки**: список всіх відкритих вкладок
- Переключення клавішею `t`

### Автоматичне виявлення Python середовища
1. Перевіряє змінну `VIRTUAL_ENV`
2. Шукає `.venv` в поточній директорії
3. Шукає `venv` в поточній директорії
4. Використовує системний `python3`

### Розумні номери рядків
- Гібридні в Normal режимі (відносні + поточний абсолютний)
- Абсолютні в Insert режимі та при втраті фокусу
- Приховані в спеціальних буферах (NvimTree, Dashboard)

### Оптимізовані діагностики
- Приглушені кольори для віртуального тексту
- Єдиний символ попередження (⚠) для всіх типів
- Плаваючі вікна з закругленими кутами

## Django розробка

### Шаблони
- Автоматичне розпізнавання `.html` файлів як Django шаблонів
- Підсвічування Jinja2 синтаксису
- Emmet у Django шаблонах

### Термінали
```bash
<leader>td   # python manage.py shell
<leader>tr   # python manage.py runserver
```

### Автоматичне сортування imports
```bash
<leader>is   # isort --profile black --line-length 79
```

## Vue.js розробка

- Повна підтримка Single File Components
- TypeScript в `<script setup lang="ts">`
- CSS/SCSS в `<style>` блоках
- Template підсвічування і автодоповнення

## Troubleshooting

### LSP сервери не встановлюються
```bash
:Mason
# Оберіть потрібний сервер і натисніть 'i' для встановлення
```

### Python середовище не знаходиться
```bash
:VenvSelect  # Вручну вибрати venv
```

### Форматування не працює
```bash
# У віртуальному середовищі
pip install black isort

# Перевірити статус
:lua print(vim.g.format_on_save)
<leader>tf  # Увімкнути авто-форматування
```

### Telescope не знаходить файли
```bash
# Встановити ripgrep
sudo apt install ripgrep  # Ubuntu/Debian
brew install ripgrep      # macOS
```

### Повільна робота which-key
Конфігурація оптимізована з:
- `delay = 100ms`
- `timeoutlen = 300ms`
- Вимкнені сповіщення

## Кастомізація

### Зміна теми
У `lua/plugins/theme.lua` змініть:
```lua
flavour = "mocha", -- latte, frappe, macchiato, mocha
```

### Додавання нових мов
У `lua/plugins/lsp.lua` додайте новий сервер:
```lua
new_server = {
  settings = { ... },
  root_markers = { ".git" },
}
```

### Налаштування гарячих клавіш
У `lua/config/keymaps.lua` додайте нові мапінги:
```lua
map("n", "<leader>xx", ":YourCommand<CR>", { desc = "Your description" })
```

### Зміна формату вкладок
У `lua/config/nvim-tabs.lua` змініть стиль у функції `tab_name()`.

## Продуктивність

- Lazy loading плагінів для швидкого запуску
- Оптимізовані autocmd групи
- Мінімальні затримки для інтерфейсу
- Ефективне використання пам'яті

Конфігурація розроблена для максимальної продуктивності при збереженні всієї необхідної функціональності IDE.