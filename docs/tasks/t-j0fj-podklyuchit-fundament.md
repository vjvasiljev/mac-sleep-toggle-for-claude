---
id: t-j0fj
title: Подключить Фундамент
type: task
status: open
priority: 1
role: executor
size: m
parent:
blocked_by: []
from:
workstream:
area: [setup]
assignee:
claimed:
due:
question:
repeat:
source:
created: 2026-11-14
closed:
not_before:
---
## Что сделать

Подключить Фундамент 2.1.1 по эталону vjvasiljev/Skill-spawner; положить в репозиторий установщик SleepToggle, README и лицензию для публичного репозитория.

## Готово, когда

Скрипты эталона в tools/, стенд PASS, CLAUDE.md, docs/, check-commands.txt, install.sh, README, LICENSE; check.py зелёный.

## Как проверить

python3 tests/stand.py --quick; python3 tools/check.py; bash -n install.sh

## Журнал


## Результат
