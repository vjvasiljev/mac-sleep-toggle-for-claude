---
id: t-j0fj
title: Подключить Фундамент
type: task
status: closed
priority: 1
role: executor
size: m
parent:
blocked_by: []
from:
workstream:
area: [setup]
assignee: setup-fundament
claimed: 2026-11-14T21:44:18Z
due:
question:
repeat:
source:
created: 2026-11-14
closed: 2026-11-14T21:50Z
not_before:
---
## Что сделать

Подключить Фундамент 2.1.1 по эталону vjvasiljev/Skill-spawner; положить в репозиторий установщик SleepToggle, README и лицензию для публичного репозитория.

## Готово, когда

Скрипты эталона в tools/, стенд PASS, CLAUDE.md, docs/, check-commands.txt, install.sh, README, LICENSE; check.py зелёный.

## Как проверить

python3 tests/stand.py --quick; python3 tools/check.py; bash -n install.sh

## Журнал

- 2026-11-14T21:50Z Проверено: bash -n install.sh: OK; tests/stand.py --quick: 162/162 PASS; Swift в облаке не собирается — владелец на своём Mac 2026-11-14 проверил 2.0 (SleepDisabled 1, assertion PreventUserIdleDisplaySleep SleepToggle, screenLock is off) и возврат блокировки 300 с в 💤 после фикса 2.1

## Результат

Фундамент 2.1.1 подключён; в репо install.sh (SleepToggle 2.1), README EN+RU, LICENSE MIT, CLAUDE.md, docs/workstreams/setup.md.
