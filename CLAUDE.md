# mac-sleep-toggle-for-claude

SleepToggle: значок в строке меню macOS, переключает «не спит с закрытой крышкой, экран не гаснет, без пароля» и обычный режим. Публичный репозиторий для всех, кто держит Claude/агентов на MacBook.

## Работа (Фундамент 2.1)

- Задачи: `docs/tasks/`, только через `python3 tools/tasks.py` (prime, claim, land, ready, board).
- Перед PR: `python3 tools/check.py --title "<id>: …"`, вывод в описание PR.
- Процедуры: скилл `fundament`. Постоянные правила: инструкции проекта.
- Знания по направлениям: `docs/workstreams/<area>.md`; пиши только в файл своей области.
- В main напрямую ничего, кроме карточек. `--force` и force-push запрещены.
- Не трогать `tools/check*.py`, `tools/tasks.py`, `tools/VERSION-etalon` вне задачи про эталон.

## Стек и команды

- Один файл `install.sh`: bash-установщик, внутри Swift-исходник (heredoc `SWIFT`), компилируется на Mac через `swiftc`.
- Установка на Mac: `bash install.sh`; удаление: `bash install.sh --uninstall`.
- Линтер / тесты: в `tools/check-commands.txt`. Swift в облаке не собирается (Linux, нет `swiftc`) — сборку и работу проверяет владелец на Mac.

## Устройство

- `install.sh` — установщик и весь код виджета.
- `README.md` — для пользователей (EN + коротко RU).
- Ставит: `~/Applications/SleepToggle.app`, `~/Library/LaunchAgents/com.local.sleeptoggle.plist`, `/etc/sudoers.d/sleeptoggle`, элемент Связки ключей `SleepToggle`, `~/Library/Application Support/SleepToggle/lock` (прежняя задержка блокировки).

## Выкладка

- Сайта нет. «Публикация» = main публичного репозитория: README даёт команду `curl …/main/install.sh`, значит слияние в main сразу уходит пользователям.
- Поэтому код в main сливается только после «да» владельца. Карточки и `docs/` — как обычно.
- GitHub Actions нет; `[skip ci]` ни на что не влияет.

## Нельзя

- Коммитить секреты, `.env`, базы, `.har`, `.DS_Store`, сборку (`check.py` ловит).
- Править файлы из `docs/tasks/frozen.txt`.
- Удалять что-либо без решения владельца.

## Подводные камни

- `sysadminctl` пишет в stderr с меткой времени в начале строки: число брать только после «delay is» (была ошибка: сохранялся год 2026).
- Браузер сохраняет повторную загрузку как `install (1).sh` — в инструкциях давать `curl` или явное имя.
- Блокировку экрана виджет меняет только при переключении, запрет гаснуть экрану держит всё время в 😳.
