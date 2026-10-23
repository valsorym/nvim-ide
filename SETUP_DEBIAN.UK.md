# Підготовка Neovim IDE на Debian

[English](SETUP_DEBIAN.md) · [Конфігурація редактора та клавіші](README.UK.md)

Ця інструкція описує підготовку Debian 13 (trixie) до роботи з Neovim IDE:
Neovim, шрифти, конфігурацію, мовні інструменти й необов'язковий пункт меню
для запуску в окремому вікні термінала. Команди розраховані на Bash і стандартні
XDG-шляхи. Якщо задано `XDG_CONFIG_HOME` чи інші XDG-змінні, використовуй свої шляхи.
Блоки `sh` виконуй у терміналі, а команди блоків `vim` — всередині Neovim після `:`.

На сервері або через SSH достатньо консольного запуску; шрифт встановлюється
на комп'ютері, який показує термінал. Для Alacritty й меню потрібна графічна сесія.
У Debian 12 старіші пакети, зокрема Alacritty з YAML-конфігурацією; перед відповідним
розділом встанови версію Alacritty з підтримкою TOML (0.13+).

## 1. Встанови базові інструменти

Пакети встановлюються через sudo; решта налаштувань належить звичайному користувачу.
Git завантажує плагіни, curl/unzip — архіви, build-essential надає компілятор і make
для парсерів та нативного сортувальника, fontconfig реєструє шрифти.
Ripgrep забезпечує пошук файлів і тексту.

```sh
sudo apt update
sudo apt install --no-install-recommends \
  git curl ca-certificates unzip build-essential fontconfig ripgrep
```

Підготуй каталог виконуваних файлів користувача:

```sh
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
```

Один раз додай наведений рядок до `~/.profile`, якщо його ще немає. Якщо оболонка
пізніше перевизначає PATH, вона також має залишати цей каталог у списку.

```sh
export PATH="$HOME/.local/bin:$PATH"
```

Після завершення встановлення вийди з графічної сесії та увійди знову, щоб програми
з меню отримали той самий PATH. Команда export вище змінює лише поточну оболонку;
відкриття ще одного термінала не замінює повторного входу до графічної сесії.

## 2. Встанови сумісний Neovim

Конфігурація потребує **Neovim 0.11.3+**, перевірена версія — **0.11.5**.
Спочатку виконай `nvim --version`; якщо сумісна версія вже є, цей крок пропусти.
[Стандартний пакет Debian 13](https://packages.debian.org/trixie/neovim) має версію
0.10.4, якої недостатньо. Команди нижче встановлюють перевірений офіційний архів
0.11.5 для AMD64 або ARM64 з перевіркою SHA-256 із
[офіційного релізу](https://github.com/neovim/neovim/releases/tag/v0.11.5).

```sh
(
  set -eu
  nvim_version=0.11.5
  case "$(uname -m)" in
    x86_64)
      nvim_platform=linux-x86_64
      nvim_sha256=b2f91117be5b5ea39edd7297156dc2a4a8df4add6c95a90809a8df19e7ab6f52
      ;;
    aarch64|arm64)
      nvim_platform=linux-arm64
      nvim_sha256=ea4f9a31b11cc1477ff014aebb7b207684e7280f94ffa97abdab6cacd9b98519
      ;;
    *) printf '%s\n' 'Use the Neovim source-build instructions for this architecture.' >&2; exit 1 ;;
  esac
  nvim_prefix="$HOME/.local/opt/nvim-$nvim_version"
  if [ -e "$nvim_prefix" ]; then
    printf 'Already exists: %s; inspect it before reinstalling.\n' "$nvim_prefix" >&2
    exit 1
  fi
  nvim_download_dir=$(mktemp -d)
  trap 'rm -rf "$nvim_download_dir"' EXIT
  nvim_archive="nvim-$nvim_platform.tar.gz"
  curl -fL --retry 3 \
    "https://github.com/neovim/neovim/releases/download/v$nvim_version/$nvim_archive" \
    -o "$nvim_download_dir/$nvim_archive"
  (cd "$nvim_download_dir"; printf '%s  %s\n' "$nvim_sha256" "$nvim_archive" | sha256sum -c -)
  tar -xzf "$nvim_download_dir/$nvim_archive" -C "$nvim_download_dir"
  mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
  mv "$nvim_download_dir/nvim-$nvim_platform" "$nvim_prefix"
  if [ -e "$HOME/.local/bin/nvim" ] || [ -L "$HOME/.local/bin/nvim" ]; then
    mv "$HOME/.local/bin/nvim" "$HOME/.local/bin/nvim.bak.$(date +%Y%m%d-%H%M%S)"
  fi
  ln -s "$nvim_prefix/bin/nvim" "$HOME/.local/bin/nvim"
)
hash -r
command -v nvim
nvim --version | head -n 1
```

Увесь архів разом із runtime зберігається в `~/.local/opt/nvim-0.11.5`.
Системні файли Debian у `/usr/bin` не замінюються. Має вибиратися виконуваний файл
`~/.local/bin/nvim`, а рядок версії має містити `v0.11.5`. Якщо показано іншу версію,
перевір псевдоніми й порядок PATH через `type -a nvim`. Для інших архітектур
скористайся [офіційною інструкцією збирання](https://github.com/neovim/neovim/blob/v0.11.5/BUILD.md).

## 3. Встанови й вибери Nerd Font

Для піктограм потрібен Nerd Font, **вибраний у терміналі**, а не просто завантажений.
Достатньо однієї родини. Приклад встановлює UbuntuMono Nerd Font 3.4.0 для
поточного користувача зі збереженням наявних файлів шрифтів:

```sh
(
  set -eu
  font_archive=$(mktemp --suffix=.zip)
  trap 'rm -f "$font_archive"' EXIT
  curl -fL --retry 3 \
    https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/UbuntuMono.zip \
    -o "$font_archive"
  mkdir -p "$HOME/.local/share/fonts/UbuntuMonoNerdFont"
  unzip -nq "$font_archive" -d "$HOME/.local/share/fonts/UbuntuMonoNerdFont"
  fc-cache -f "$HOME/.local/share/fonts/UbuntuMonoNerdFont"
)
fc-match 'UbuntuMono Nerd Font Mono'
```

`fc-match` має показати `UbuntuMono Nerd Font Mono`, а не запасний шрифт на кшталт
DejaVu Sans Mono. Вибери цю точну назву в профілі термінала й відкрий його вікна
заново. Варіант Mono утримує піктограми в межах термінальних комірок.
Налаштування Alacritty наведене в кроці 6; можна вибрати іншу
[родину Nerd Fonts](https://www.nerdfonts.com/font-downloads). Для виправлення
відсутніх піктограм не потрібно перевстановлювати плагіни Neovim.

## 4. Клонуй конфігурацію й запусти Neovim

Перед заміною конфігурації закрий інші процеси Neovim. Команди нижче відкладають
наявний конфіг у резервну копію й клонують `master`; дані плагінів, сесії, історія
скасувань і кеш залишаються. Не видаляй `~/.local/share/nvim`, `~/.local/state/nvim`
чи `~/.cache/nvim` як звичайний крок встановлення.

```sh
(
  set -eu
  mkdir -p "$HOME/.config"
  if [ -e "$HOME/.config/nvim" ] || [ -L "$HOME/.config/nvim" ]; then
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak.$(date +%Y%m%d-%H%M%S)"
  fi
  git clone --branch master https://github.com/valsorym/nvim-ide.git "$HOME/.config/nvim"
)
nvim
```

Для фіксованої версії заміни `--branch master` на `--branch v2.4.0`; checkout тега
має відокремлений HEAD та оновлюється вибором іншого тега, а не через pull.
Перший запуск потребує інтернету для встановлення зафіксованих ревізій плагінів.
Дочекайся завершення, вийди через `:qa` і відкрий Neovim заново.

## 5. Додай пошук і потрібні мовні інструменти

Ripgrep уже встановлено в кроці 1. Для наступних команд оболонки вийди
з Neovim через `:qa` або скористайся другим терміналом.

Для Python/web мовних серверів встанови Node.js/npm; Python-проєктам також
потрібні Python і підтримка venv. Непотрібні середовища можна пропустити:

```sh
sudo apt install --no-install-recommends nodejs npm python3 python3-venv
node --version
npm --version
```

Новіші випуски мовних серверів іноді потребують новішого Node.js, ніж надає Debian.
Перевір помилку в `:MasonLog` і за потреби встанови підтримуваний LTS з
[офіційного сайту Node.js](https://nodejs.org/en/download). Якщо використовується
менеджер версій Node, вибране середовище має бути доступним і графічній сесії.

Відкрий `nvim` знову. У редакторі ці команди встановлюють усі підтримувані
синтаксичні парсери, два приклади мовних серверів та необов'язковий форматер Python:

```vim
:ParsersInstall
:LspInstall pyright lua_ls
:MasonInstall ruff
```

Альтернатива — встановити весь підтримуваний набір мовних серверів:

```vim
:LanguageToolsInstall
```

`:LanguageToolsInstall` встановлює сервери, а не всі середовища мов і форматери.
`:Mason` дає змогу вибрати інструменти окремо та показує помилки встановлення.
Для деяких архітектур готових збірок може не бути: тоді скористайся системним
пакетом або офіційною інструкцією самого інструмента. Після встановлення
перезапусти Neovim. Відкриття файла не завантажує парсери й сервери автоматично.

Додаткові системні інструменти — лише для мов, якими користуєшся:

| Мова | Встановлення | Призначення |
| --- | --- | --- |
| Go | `sudo apt install golang-go gopls` | Компілятор Go, gofmt і мовний сервер |
| C/C++ | `sudo apt install clangd clang-format` | Мовний сервер і форматер |
| Shell | `sudo apt install shfmt` | Форматер shell; bashls використовує Node.js |

Необов'язкові web/Lua форматери встановлюються через `:MasonInstall prettier stylua`.
Prettier також можна встановити як залежність розробки проєкту. Для Python Ruff
можна встановити в його власне середовище; виконуй у каталозі проєкту:

```sh
python3 -m venv .venv
.venv/bin/python -m pip install ruff
```

Глобальне встановлення через pip чи пакет Python-провайдера для цього конфіга
не потрібні. Pyright аналізує вибране середовище проєкту; `Пробіл cvc` дозволяє
вибрати інше. Повний перелік інтеграцій і відмінності між серверами, форматерами
та вбудованими командами є в [розділі підтримки мов](README.UK.md#підтримка-мов).

## 6. Необов'язково: окрема IDE у вікні Alacritty

Встанови Alacritty та інструменти меню програм:

```sh
sudo apt install --no-install-recommends alacritty desktop-file-utils
mkdir -p "$HOME/.config/alacritty"
```

Створи `~/.config/alacritty/alacritty.toml` із параметрами шрифту нижче. Якщо файл
уже є, збережи резервну копію та узгодь параметри з наявними таблицями font:
не дублюй таблиці й не перезаписуй решту налаштувань. Це типовий профіль Alacritty,
який використовується також іншими його вікнами.

```toml
[font]
size = 13.0

[font.normal]
family = "UbuntuMono Nerd Font Mono"
style = "Regular"

[font.bold]
family = "UbuntuMono Nerd Font Mono"
style = "Bold"

[font.italic]
family = "UbuntuMono Nerd Font Mono"
style = "Italic"

[font.bold_italic]
family = "UbuntuMono Nerd Font Mono"
style = "Bold Italic"
```

Встанови готовий скрипт запуску й пункт меню. Якщо файли з такими іменами вже
налаштовані під себе, спочатку збережи резервні копії. Пункт меню використовує
абсолютний шлях до скрипта:

```sh
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"
install -m 755 "$HOME/.config/nvim/bin/nvim-ide" "$HOME/.local/bin/nvim-ide"
nvim_executable=$(readlink -f "$(command -v nvim)")
nvim_prefix=$(dirname "$(dirname "$nvim_executable")")
if [ -f "$nvim_prefix/share/icons/hicolor/128x128/apps/nvim.png" ]; then
  install -Dm644 "$nvim_prefix/share/icons/hicolor/128x128/apps/nvim.png" \
    "$HOME/.local/share/icons/hicolor/128x128/apps/nvim.png"
fi
desktop-file-install \
  --dir="$HOME/.local/share/applications" \
  --set-key=Exec --set-value="\"$HOME/.local/bin/nvim-ide\" %F" \
  --set-key=TryExec --set-value="$HOME/.local/bin/nvim-ide" \
  "$HOME/.config/nvim/extras/nvim-ide.desktop"
update-desktop-database "$HOME/.local/share/applications"
nvim-ide
```

Після повторного входу до графічної сесії знайди **Neovim IDE** в меню програм
і за бажанням закріпи на панелі. Скрипт відкриває власне розгорнуте вікно Alacritty
з класом `NVimIDE`; wmctrl чи окремий графічний редактор не потрібні.
Це та сама конфігурація, що й у консольного nvim, зі звичайними аргументами:

```sh
nvim-ide -p first.py second.py
nvim-ide --terminal first.py
```

У Cinnamon для власного клавіатурного скорочення можна вказати абсолютний шлях
`/home/YOUR_USER/.local/bin/nvim-ide`. Не використовуй сам по собі `~` у полі Exec
desktop-файла. Параметри шрифту й вікна описані в
[довідці Alacritty](https://alacritty.org/config-alacritty.html).

## 7. Під'єднай системний буфер обміну

Перевір тип графічної сесії:

```sh
printf '%s\n' "$XDG_SESSION_TYPE"
```

Для X11, зокрема Cinnamon X11, встанови:

```sh
sudo apt install --no-install-recommends xclip
```

Для Wayland встанови:

```sh
sudo apt install --no-install-recommends wl-clipboard
```

Після встановлення провайдера перезапусти Neovim. Перевір його через
`:checkhealth vim.provider`; `"+yy` копіює рядок до системного буфера.
Для SSH потрібне окреме рішення: саме встановлення xclip на сервері без графічної
сесії не під'єднає його до буфера обміну локального робочого столу.

## 8. Необов'язково: правильні кольори у tmux

Встанови tmux і розширені описи терміналів:

```sh
sudo apt install --no-install-recommends tmux ncurses-term
infocmp tmux-256color >/dev/null
```

Додай цей рядок до наявного `~/.tmux.conf`, зберігаючи інші параметри:

```tmux
source-file ~/.config/nvim/extras/tmux.conf
```

Якщо сервер tmux уже працює, перечитай налаштування та перевір можливості клієнта:

```sh
tmux source-file "$HOME/.tmux.conf"
tmux display-message -p '#{client_termname} #{client_termfeatures}'
```

Від'єднай і повторно під'єднай клієнт, потім створи **нову панель**: старі панелі
зберігають попередній TERM. Фрагмент використовує всередині `tmux-256color` та
оголошує RGB для клієнтів Alacritty й xterm-256color. Для іншого зовнішнього
термінала додай його справжнє ім'я. Не підміняй TERM глобально в налаштуваннях
оболонки. Для SSH опис terminfo потрібен також на віддаленому хості.
Додаткові випадки описано у [FAQ tmux](https://github.com/tmux/tmux/wiki/FAQ).

## 9. Перевір результат і підтримуй встановлення

У терміналі:

```sh
command -v nvim
nvim --version | head -n 1
rg --version | head -n 1
cc --version | head -n 1
fc-match 'UbuntuMono Nerd Font Mono'
```

У Neovim:

```vim
:checkhealth nvim_ide
:checkhealth vim.provider
:checkhealth vim.lsp
:checkhealth nvim-treesitter
```

Перед перевіркою LSP відкрий файл мови, для якої встановлено сервер. Відсутність
необов'язкових серверів чи форматерів у звіті не заважає редагуванню іншими мовами.
Мають працювати стартовий екран, піктограми, провідник `Пробіл be` та довідка
`Пробіл h`. Віртуальна консоль Linux має обмеженіші шрифти й кольори, ніж
графічний емулятор термінала.

Щоб оновити чисту робочу копію master після перегляду змін:

```sh
git -C "$HOME/.config/nvim" pull --ff-only
```

Збережи власні зміни й резервну копію конфігурації до перевірки оновлення.
Перезапусти Neovim і віднови зафіксовані в репозиторії версії плагінів:

```vim
:Lazy restore
```

Після зміни ревізій плагінів онови встановлені парсери через `:TSUpdate`.
`:Lazy update` змінює залежності та є окремим оновленням, а не обов'язковим кроком
встановлення. Якщо оновлення змінило шаблони скрипта запуску чи пункту меню,
скопіюй їх повторно. Клавіші, українські розкладки й щоденна робота описані в
[README.UK.md](README.UK.md).
