{ config, lib, pkgs, ... }:

{
  #fish shell (autosuggestions out of the box)
  programs.fish = {
    enable = true;
    # Приветствие выключено: set -g fish_greeting без аргументов убирает
    # дефолтный "Welcome to fish", а автозапуск fastfetch убран — баннер
    # печатался при каждом открытии терминала и тормозил старт. Теперь
    # fastfetch только по требованию: `fastfetch` руками, из панели
    # SystemStats он зовётся как `fastfetch -c systemstats` (обёртка в
    # home/modules/packages.nix этот вызов отдаёт pkgs.fastfetch без лого).
    interactiveShellInit = ''
      set -g fish_greeting
    '';
    # ls → lsd: иконки, раскраска, tree, human-readable размеры.
    # Именно алиас, а не подмена бинаря: скрипты, пайпы и make-рецепты
    # продолжают звать настоящий ls и получать его однострочный вывод
    # без escape-последовательностей (цвет lsd в не-tty отключается сам,
    # но формат всё равно отличается: -1, -h, exit codes).
    shellAliases = {
      ls = "lsd";
    };
  };

  #bash shell (fallback)
  programs.bash = {
    enable = true;
    enableCompletion = true;
    # тот же алиас ls = lsd, что и в fish
    shellAliases = {
      ls = "lsd";
    };
  };

  # atuin — история команд с полнотекстовым поиском, оговорками
  # (#!/usr/bin/env fish, rm -rf ...) и (после `atuin register`) синком
  # между машинами. Интеграция вешает поиск на Ctrl-R, а в fish ещё и на
  # стрелку вверх: без этого fish ищет только по СВОЕЙ истории, а не по
  # общей базе atuin. Отключить перехват стрелки — flags = ["--disable-up-arrow"].
  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    # daemon (18.13+): один писатель в sqlite вместо конкуренции всех
    # открытых шеллов — иначе при нескольких окнах терминала ловятся
    # "database is locked". Требует systemd.user.enable (на NixOS = true).
    daemon.enable = true;
    # settings намеренно не задаются: HM здесь генерирует config.toml, а
    # atuin дописывает/перезаписывает его сам после каждой команды, и файл
    # начинает прыгать между стором и ~/.config. Пусть создаст дефолтный
    # ~/.config/atuin/config.toml сам, а синк включается через `atuin register`.
  };

  #starship prompt
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[❯](bold green)" ;
        error_symbol = "[❯](bold red)";
      };
    };
  };
}