# AGENTS.md

## Nix + git: новые файлы обязаны попасть в индекс ДО пересборки

**Правило:** конфиги (quickshell, niri, home/etc.) собираются в nix-стор
**из git-индекса (flake)**, а НЕ из рабочего каталога.

- Новая папка/файл, добавленный конфигом (`:include`, `@import`,
  `source = ./...`) и **не застейдженный** = в сторе его НЕТ → ошибки
  вида "Included file `./modules/X/X.yuck` not found" / "not found".
- Поэтому: любой НОВЫЙ файл сначала `git add`, потом сборка.
  (Правки существующих файлов попадают автоматически через M/A.)

### Порядок работы с quickshell/niri/любым hm-модулем
1. Правки или создание файлов.
2. `git add <новые файлы>` — ОБЯЗАТЕЛЬНО для впервые добавленных.
3. Пересборка: `home-manager switch` (или nixos-rebuild).
4. Quickshell стартует из niri (spawn-at-startup) и сам перезагружается
   при изменении QML-файлов; рестарт при смене структуры:
   `pkill quickshell` + запуск снова.

### Напоминания
- `git status --short` после правок — untracked (`??`) файлы = кандидаты
  на `git add` ПО ДО пересборки nix.
- quickshell: конфиг = `~/.config/quickshell/shell.qml` (QML). Бар
  создаётся на каждый экран через `Variants` + `Quickshell.screens`.
  Рабочие столы niri опрашиваются `niri msg --json workspaces`
  (отдельный singleton `Niri.qml`).
