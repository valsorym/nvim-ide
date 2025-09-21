# NeoVim IDE Configuration

Повнофункціональна IDE конфігурація для Neovim з підтримкою Python + Django, JavaScript/TypeScript, Vue.js, C/C++, Go та інших мов програмування.

## Встановлення

### 1. Встановлення залежностей і інструментів

```bash
# Оновлення системи та встановлення основних інструментів
sudo apt update && \
sudo apt install -y \
  build-essential \
  cmake \
  gettext \
  ninja-build \
  unzip \
  curl \
  git \
  libtool \
  libtool-bin \
  autoconf \
  automake \
  pkg-config \
  clangd \
  golang-go \
  fd-find \
  luarocks \
  cargo \
  composer \
  xclip \
  nodejs \
  npm \
  python3-pip \
  ripgrep \
  codespell \
  mypy
```

### 2. Встановлення шрифтів Nerd Fonts

```bash
# Завантаження та встановлення популярних Nerd Fonts
adwaita="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/AdwaitaMono.zip"
anonymous="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/AnonymousPro.zip"
jetbrains="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"
firacode="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraCode.zip"
cascadia="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/CascadiaCode.zip"
hack="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Hack.zip"
sourcecode="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/SourceCodePro.zip"
ubuntu="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/UbuntuMono.zip"
dejavu="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/DejaVuSansMono.zip"
inconsolata="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Inconsolata.zip"

mkdir -p ~/.local/share/fonts && \
mkdir -p ~/tmp/fonts && \
cd ~/tmp/fonts && \
wget $adwaita && \
wget $anonymous && \
wget $jetbrains && \
wget $firacode && \
wget $cascadia && \
wget $hack && \
wget $sourcecode && \
wget $ubuntu && \
wget $dejavu && \
wget $inconsolata && \
unzip -o "*.zip" -d ~/.local/share/fonts/ && \
rm *.zip && \
fc-cache -fv
```

**⚠️ ВАЖЛИВО**: Встановіть один з Nerd Font Mono як шрифт за замовчуванням у вашому терміналі для коректного відображення іконок.

### 3. Встановлення NeoVim з вихідного коду

```bash
# Створення тимчасової директорії та клонування репозиторію
mkdir -p /tmp/neovim && cd /tmp/neovim && \
git clone https://github.com/neovim/neovim.git && \
cd neovim && \
git checkout stable && \
make CMAKE_BUILD_TYPE=Release && \
sudo make install
```

### 4. Встановлення Python інструментів

```bash
# Глобальне встановлення Python форматерів
pip3 install black isort

# Або для конкретного проекту з віртуальним середовищем
python3 -m venv .venv
source .venv/bin/activate
pip install black isort django  # додайте інші залежності за потреби
```

### 5. Встановлення NVim-IDE конфігурації

```bash
bash -lc '
set -euo pipefail
cd "$HOME"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/nvim"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/nvim"
[ -e "$config_dir" ] && mv "$config_dir" "$config_dir.bak.$(date +%s)"
[ -e "$data_dir" ] && mv "$data_dir" "$data_dir.bak.$(date +%s)"
[ -e "$state_dir" ] && mv "$state_dir" "$state_dir.bak.$(date +%s)"
[ -e "$cache_dir" ] && mv "$cache_dir" "$cache_dir.bak.$(date +%s)"
mkdir -p "$config_dir"
mkdir -p "$data_dir"
mkdir -p "$state_dir"
mkdir -p "$cache_dir"
echo -e "\n\nCloning NVim-IDE..."
git clone --depth 1 https://github.com/valsorym/nvim-ide "$config_dir"
rm -rf "$config_dir/.git"
nvim --headless "+Lazy! sync" "+qa"
echo -e "\n\nNVim-IDE installed successfully: $config_dir"
echo "Plugins will install automatically on first launch..."
' && nvim
```

При першому запуску Neovim автоматично:
- Встановить всі плагіни через Lazy.nvim
- Завантажить LSP сервери через Mason
- Налаштує Treesitter парсери

## Основні можливості

### Python + Django
- Автоматичне виявлення віртуального середовища (.venv, venv)
- Підтримка Django шаблонів (htmldjango, jinja2)
- Автоматичне сортування imports з isort
- Форматування коду з Black (79 символів на рядок)
- LSP підтримка з Pyright
- Django management команди через термінал

### Web Development
- HTML/CSS/JavaScript/TypeScript повна підтримка
- Vue.js з Vue Language Server
- CSS/JS у `<style>` та `<script>` блоках HTML файлів
- Emmet для швидкого написання HTML/CSS
- Prettier для форматування
- JSON схеми з SchemaStore

### Основні функції IDE
- LSP сервери для 10+ мов програмування
- Інтелігентний файловий менеджер з режимом вкладок
- Telescope для швидкого пошуку файлів і тексту
- Git інтеграція з gitsigns
- Багатофункціональний термінал
- Автоматичне закриття дужок і парних символів
- Розумні коментарі для всіх мов
- Treesitter для точного підсвічування синтаксису
- Which-key для інтуїтивної навігації
- Автоматичне форматування при збереженні

## Швидкий старт - Основні дії

### 1. Відкрити дерево каталогів
```
F9                    # Відкрити файловий менеджер у модальному вікні
<leader>ee            # Альтернативний спосіб (<leader> = Space)

У файловому менеджері:
Enter                 # Відкрити файл у новій вкладці або розгорнути папку
t                     # Переключити між режимом файлів і вкладок
q або Esc             # Закрити файловий менеджер
```

### 2. Відкрити список відкритих буферів/вкладок
```
F8                    # Показати список всіх відкритих вкладок
<leader>et            # Альтернативний спосіб

F10                   # Показати буфери через Telescope
<leader>eb            # Показати буфери через Telescope
<leader>fb            # Показати буфери через Telescope

У списку вкладок:
Enter                 # Переключитися на обрану вкладку
d                     # Закрити обрану вкладку
q або Esc             # Закрити список
```

### 3. Переміщатися по вкладках
```
Alt + Left / F5       # Попередня вкладка
Alt + Right / F6      # Наступна вкладка
Alt + 1-9             # Перейти до вкладки з номером 1-9
Alt + h               # Перемістити поточну вкладку ліворуч
Alt + l               # Перемістити поточну вкладку праворуч
```

### 4. Активувати Python venv
```
<leader>vs            # Вибрати Python віртуальне середовище
:VenvSelect           # Команда для ручного вибору venv

Автоматичне виявлення:
1. Перевіряє змінну VIRTUAL_ENV
2. Шукає .venv в поточній директорії
3. Шукає venv в поточній директорії
4. Використовує системний python3
```

### 5. Перенести файли в підкаталог (nvim-tree)
```
F9                    # Відкрити nvim-tree
x                     # Вирізати файл
Перейти до папки призначення
p                     # Вставити файл

Альтернативно:
c                     # Копіювати файл
p                     # Вставити копію
```

### 6. Закрити файл (та всі файли)
```
<leader>qq            # Закрити поточну вкладку
<leader>qa            # Закрити всі вкладки та вийти з nvim
<leader>qQ            # Примусово закрити поточну вкладку (без збереження)
<leader>qA            # Примусово закрити все та вийти
```

## Повний список комбінацій клавіш

### Файли та навігація

| Клавіші | Дія |
|---------|-----|
| `F9` | Відкрити/закрити файловий менеджер |
| `<leader>ee` | Відкрити файловий менеджер |
| `<leader>ff` | Знайти файли (Telescope) |
| `<leader>fg` | Пошук тексту в проекті (Live Grep) |
| `<leader>fb` | Список відкритих буферів |
| `<leader>fh` | Довідка (Help tags) |
| `<leader>fs` | Символи в документі |
| `<leader>fw` | Символи в робочій області |

### Вкладки (Tabs)

| Клавіші | Дія |
|---------|-----|
| `Alt + Left` / `F5` | Попередня вкладка |
| `Alt + Right` / `F6` | Наступна вкладка |
| `Alt + 1-9` | Перейти до вкладки 1-9 |
| `Alt + h` | Перемістити вкладку ліворуч |
| `Alt + l` | Перемістити вкладку праворуч |
| `F8` | Список всіх відкритих вкладок |
| `<leader>et` | Список всіх відкритих вкладок |
| `F10` | Список буферів (Telescope) |
| `<leader>eb` | Список буферів (Telescope) |
| `<leader>fb` | Список буферів (Telescope) |

**У файловому менеджері:**
- `t` - перемикання між режимом файлів і вкладок
- `Enter` - відкрити файл у новій вкладці або перейти до існуючої

### Термінал

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

### LSP (Language Server)

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

### Форматування та збереження

| Клавіші | Дія |
|---------|-----|
| `F2` | Розумне збереження + форматування |
| `<leader>f` | Форматувати поточний буфер |
| `<leader>F` | Форматувати документ |
| `<leader>tf` | Увімкнути/вимкнути авто-форматування при збереженні |
| `<leader>is` | Сортувати Python imports (isort) |

### Діагностика

| Клавіші | Дія |
|---------|-----|
| `]d` | Наступна помилка/попередження |
| `[d` | Попередня помилка/попередження |
| `<leader>d` | Показати діагностику у плаваючому вікні |
| `<leader>q` | Відкрити список помилок (quickfix) |

### Редагування

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

### Буфер обміну (Clipboard)

| Клавіші | Дія |
|---------|-----|
| `<leader>ya` | Скопіювати весь буфер до clipboard |
| `<leader>yy` | Скопіювати виділення до clipboard (також у візуальному режимі) |
| `<leader>yp` | Вставити з clipboard (також у візуальному режимі) |

### Вікна

| Клавіші | Дія |
|---------|-----|
| `<C-h/j/k/l>` | Навігація між вікнами |
| `<C-Up/Down>` | Змінити висоту вікна |
| `<C-Left/Right>` | Змінити ширину вікна |

### Git

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

### Система та інші

| Клавіші | Дія |
|---------|-----|
| `<leader>m` | Відкрити Mason (менеджер LSP) |
| `<leader>vs` | Вибрати Python віртуальне середовище |
| `<leader>qq` | Закрити поточну вкладку |
| `<leader>qa` | Закрити всі вкладки та вийти |
| `<leader>qQ` | Примусово закрити поточну вкладку |
| `<leader>qA` | Примусово закрити все та вийти |
| `<leader>h` | Очистити підсвічування пошуку |

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
<leader>vs   # Альтернативний спосіб
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

### Шрифти не відображаються правильно
- Переконайтесь, що встановлено Nerd Font
- Встановіть один з Nerd Font Mono як шрифт терміналу за замовчуванням
- Рекомендовані: JetBrains Mono Nerd Font, Fira Code Nerd Font

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