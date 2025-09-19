# NeoVim IDE Configuration

Повнофункціональна IDE конфігурація для Neovim з підтримкою Python + Django, JavaScript/TypeScript, Vue.js, C/C++, Go, PlatformIO та інших мов програмування.

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
  platformio
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

### 5. Встановлення PlatformIO Core

```bash
# Через pip (рекомендований спосіб)
pip3 install platformio

# Або через homebrew (macOS)
brew install platformio

# Або через snap (Ubuntu)
sudo snap install --classic platformio

# Перевірка встановлення
pio --version
```

### 6. Встановлення NVim-IDE конфігурації

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
echo -e "\n\nCloning NvChad..."
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

### PlatformIO - Embedded Development
- Автоматичне виявлення PlatformIO проектів (platformio.ini)
- LSP підтримка для C/C++ з clangd
- Автоматична генерація `compile_commands.json`
- Підтримка популярних плат: Arduino, ESP32/ESP8266, STM32, Raspberry Pi Pico
- Інтеграція з термінальними командами PlatformIO
- Швидка навігація по коду з IntelliSense
- Підсвічування синтаксису для Arduino скетчів

#### Підтримувані платформи PlatformIO:
- **Arduino**: Uno, Nano, Mega, Leonardo
- **ESP**: ESP32, ESP8266 (всі варіанти)
- **STM32**: Bluepill, Nucleo, Discovery boards
- **Raspberry Pi**: Pico, Pico W
- **Teensy**: 3.x, 4.x серії
- **AVR**: ATmega, ATtiny мікроконтролери
- **ARM**: Cortex-M based MCUs
- **RISC-V**: CH32V, ESP32-C3/S3

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

### 5. PlatformIO швидкий старт
```
<leader>pn            # Створити новий PlatformIO проект
<leader>pb            # Зібрати проект
<leader>pu            # Завантажити на пристрій
<leader>pm            # Відкрити монітор серійного порту
<leader>pf            # Зібрати та завантажити (швидка команда)
```

### 6. Перенести файли в підкаталог (nvim-tree)
```
F9                    # Відкрити nvim-tree
x                     # Вирізати файл
Перейти до папки призначення
p                     # Вставити файл

Альтернативно:
c                     # Копіювати файл
p                     # Вставити копію
```

### 7. Закрити файл (та всі файли)
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
| `<leader>fp` | Знайти проекти (Telescope) |

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

### PlatformIO - Embedded Development

| Клавіші | Дія |
|---------|-----|
| `<leader>pb` | Зібрати проект (pio run) |
| `<leader>pu` | Завантажити на пристрій (pio run --target upload) |
| `<leader>pm` | Монітор серійного порту (pio device monitor) |
| `<leader>pc` | Очистити збірку (pio run --target clean) |
| `<leader>pf` | Зібрати та завантажити (швидка команда) |
| `<leader>pt` | Запустити тести (pio test) |
| `<leader>pl` | Список бібліотек (pio lib list) |
| `<leader>pi` | Встановити бібліотеку (pio lib install) |
| `<leader>ps` | Список пристроїв (pio device list) |
| `<leader>pn` | Створити новий проект (інтерактивно) |
| `<leader>pg` | Генерувати compile_commands.json |
| `<leader>po` | Відкрити platformio.ini у новій вкладці |

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
| `<leader>xx` | Показати діагностику у плаваючому вікні |
| `gl` | Показати діагностику у плаваючому вікні |
| `<leader>xl` | Відкрити список помилок (quickfix) |

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

### Теми та UI

| Клавіші | Дія |
|---------|-----|
| `<leader>ut` | Перемикач тем (попередній перегляд) |
| `<leader>us` | Встановити постійну тему |
| `<leader>ui` | Інформація про поточну тему |
| `<leader>ud` | Показати доступні теми (debug) |

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
| **C/C++** | clangd | clang-format | PlatformIO support, compile_commands.json |
| **Go** | gopls | goimports | Автоматичні imports |
| **Lua** | lua_ls | stylua | Neovim API support |
| **JSON** | jsonls | Prettier | Schema validation |
| **YAML** | yamlls | Prettier | GitHub Actions, Docker Compose |
| **Docker** | dockerls | - | Dockerfile підтримка |
| **Bash** | bashls | - | Shell scripting |

## PlatformIO робочий процес

### 1. Створення нового проекту
```bash
<leader>pn          # Інтерактивне створення проекту
# Оберіть назву проекту та плату з списку

# Доступні популярні плати:
arduino-uno         # Arduino Uno
arduino-nano        # Arduino Nano
arduino-mega        # Arduino Mega
esp32dev           # ESP32 Development Board
esp8266            # ESP8266 (NodeMCU, Wemos D1)
bluepill_f103c8    # STM32 Blue Pill
nucleo_f401re      # STM32 Nucleo
raspberry-pi-pico  # Raspberry Pi Pico
```

### 2. Розробка та налагодження
```bash
<leader>po          # Відкрити platformio.ini для налаштування
<leader>pg          # Генерувати compile_commands.json для LSP
<leader>pb          # Зібрати проект
<leader>pu          # Завантажити на пристрій
<leader>pm          # Відкрити серійний монітор
<leader>pf          # Зібрати та завантажити (швидка команда)
```

### 3. Управління бібліотеками
```bash
<leader>pl          # Показати встановлені бібліотеки
<leader>pi          # Встановити нову бібліотеку
<leader>ps          # Показати підключені пристрої
```

### 4. Тестування
```bash
<leader>pt          # Запустити unit тести
<leader>pc          # Очистити збірку (при проблемах)
```

## Приклад структури PlatformIO проекту

```
my_arduino_project/
├── platformio.ini              # Конфігурація проекту
├── src/
│   └── main.cpp               # Основний код програми
├── include/
│   └── README                 # Заголовочні файли
├── lib/
│   └── README                 # Приватні бібліотеки
├── test/
│   └── README                 # Unit тести
└── .pio/                      # Збірка та кеш (auto-generated)
    ├── build/
    │   └── compile_commands.json  # Для LSP підтримки
    └── libdeps/
```

### Приклад platformio.ini:
```ini
[env:uno]
platform = atmelavr
board = uno
framework = arduino
monitor_speed = 9600
lib_deps =
    arduino-libraries/Servo@^1.1.8
    adafruit/Adafruit NeoPixel@^1.10.7

[env:esp32]
platform = espressif32
board = esp32dev
framework = arduino
monitor_speed = 115200
lib_deps =
    bblanchon/ArduinoJson@^6.19.4
    knolleary/PubSubClient@^2.8
```

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
        ├── footer.lua                   # Статусна лінія (lualine)
        ├── formatting.lua               # null-ls для форматування
        ├── lsp.lua                      # LSP конфігурація для всіх мов
        ├── mason.lua                    # Менеджер LSP серверів
        ├── nvim-tree.lua               # Файловий менеджер з режимом вкладок
        ├── platformio.lua              # PlatformIO інтеграція
        ├── scroll.lua                   # Scrollbar з індикаторами
        ├── tabs-list.lua               # Незалежний список вкладок
        ├── theme.lua                    # Багатотемна підтримка з перемикачем
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

### Автоматичне виявлення середовищ
**Python:**
1. Перевіряє змінну `VIRTUAL_ENV`
2. Шукає `.venv` в поточній директорії
3. Шукає `venv` в поточній директорії
4. Використовує системний `python3`

**PlatformIO:**
1. Виявляє `platformio.ini` у корені проекту
2. Автоматично генерує `compile_commands.json`
3. Налаштовує clangd для роботи з `.pio/build`
4. Підключає специфічні термінальні команди

### Багатотемна підтримка
- Catppuccin (Mocha, Latte, Frappe, Macchiato)
- Tokyo Night (Night, Storm, Moon, Day)
- Gruvbox Material
- Kanagawa (Wave, Dragon, Lotus)
- Nord
- One Dark
- Telescope перемикач з попереднім переглядом
- Збереження обраної теми між сесіями

### Розумні номери рядків
- Гібридні в Normal режимі (відносні + поточний абсолютний)
- Абсолютні в Insert режимі та при втраті фокусу
- Приховані в спеціальних буферах (NvimTree, Dashboard)

### Оптимізовані діагностики
- Приглушені кольори для віртуального тексту
- Спеціальні іконки для різних типів повідомлень (☣ ⚠ 💡 ℹ)
- Плаваючі вікна з закругленими кутами
- Scrollbar індикатори для помилок у файлі

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

### PlatformIO проекти не розпізнаються
```bash
# Переконайтесь, що файл platformio.ini існує
ls platformio.ini

# Генеруйте compile_commands.json для LSP
<leader>pg
# або
pio run --target compiledb

# Перезапустіть LSP сервер
:LspRestart
```

### Форматування не працює
```bash
# У віртуальному середовищі
pip install black isort

# Для C/C++ (PlatformIO)
sudo apt install clang-format

# Перевірити статус
:lua print(vim.g.format_on_save)
<leader>tf  # Увімкнути авто-форматування
```

### Telescope не знаходить файли
```bash
# Встановити ripgrep
sudo apt install ripgrep  # Ubuntu/Debian
brew install ripgrep      # macOS

# Для PlatformIO файлів (.cpp, .h в src/)
<leader>ff  # Telescope знаходить усі файли
```

### PlatformIO команди не працюють
```bash
# Перевірити встановлення PlatformIO
pio --version

# Встановити глобально
pip3 install platformio

# Додати до PATH (якщо потрібно)
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
source ~/.bashrc
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

### Проблеми з clangd у PlatformIO
```bash
# Генерувати compile_commands.json
cd /path/to/your/platformio/project
pio run --target compiledb

# Перевірити, чи створився файл
ls .pio/build/compile_commands.json

# Перезапустити LSP
:LspRestart
```

## Кастомізація

### Зміна теми
```bash
<leader>ut              # Попередній перегляд тем
<leader>us              # Встановити постійну тему
```

Або вручну у `lua/plugins/theme.lua`:
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

### Налаштування PlatformIO для нових плат
У `lua/plugins/platformio.lua` додайте нову плату до списку:
```lua
-- У функції project initialization
"your-custom-board",
```

### Зміна формату вкладок
У `lua/config/nvim-tabs.lua` змініть стиль у функції `tab_name()`.

### Додавання нових PlatformIO команд
У `lua/config/keymaps.lua`:
```lua
map("n", "<leader>px", ":TermExec cmd='pio run --target clean'<CR>",
    {desc = "PlatformIO: Custom command"})
```

## Додаткові поради

### PlatformIO Best Practices
1. **Організація коду**: Використовуйте `lib/` для власних бібліотек
2. **Версіонування**: Вказуйте конкретні версії бібліотек у `platformio.ini`
3. **Тестування**: Створюйте unit тести у папці `test/`
4. **Документація**: Коментуйте код для кращого LSP досвіду

### Оптимізація продуктивності
- Використовуйте `.pio/` у `.gitignore`
- Регулярно очищуйте збірку: `<leader>pc`
- Генеруйте `compile_commands.json` після зміни залежностей: `<leader>pg`

### Інтеграція з Git
```bash
# .gitignore для PlatformIO проектів
.pio/
.vscode/
*.tmp
*.bak
```

### Робота з великими проектами
1. Використовуйте `<leader>fs` для навігації по символах
2. `<leader>fw` для пошуку у всій робочій області
3. `gr` для знаходження всіх використань функції
4. `gd` для швидкого переходу до визначення

## Продуктивність

- Lazy loading плагінів для швидкого запуску
- Оптимізовані autocmd групи
- Мінімальні затримки для інтерфейсу
- Ефективне використання пам'яті
- Спеціальна оптимізація для PlatformIO проектів
- Автоматична генерація LSP метаданих
- Scrollbar з індикаторами помилок для швидкої навігації

## Підтримка спільноти

Конфігурація розроблена для максимальної продуктивності при збереженні всієї необхідної функціональності IDE. Підтримує як веб-розробку (Python/Django, JavaScript/Vue.js), так і embedded розробку (PlatformIO, Arduino, ESP32).

### Корисні ресурси
- [PlatformIO Documentation](https://docs.platformio.org/)
- [Arduino Reference](https://www.arduino.cc/reference/en/)
- [ESP32 Documentation](https://docs.espressif.com/projects/esp-idf/en/latest/)
- [Neovim LSP Configuration](https://neovim.io/doc/user/lsp.html)

Ця конфігурація перетворює Neovim на повноцінне IDE, яке конкурує з VSCode та інтегрованими середовищами розробки, при цьому залишаючись швидким та ефективним.