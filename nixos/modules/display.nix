{ config, lib, pkgs, ... }:

{
  # display manager: greetd + ReGreet (GTK4-грейтер, запускается в cage).
  # Модуль сам включает services.greetd и задаёт default_session:
  #   dbus-run-session cage -s -d -- regreet   (user = "greeter")
  services.displayManager.regreet = {
    enable = true;

    # тема/иконки/курсор/шрифт грейтера — под catppuccin-mocha, как в системе
    theme = {
      name = "catppuccin-mocha-mauve-standard";
      package = pkgs.catppuccin-gtk.override {
        variant = "mocha";
        accents = [ "mauve" ];
        size = "standard";
      };
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
    };
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
      package = pkgs.nerd-fonts.jetbrains-mono;
    };

    settings = {
      # тёмная GTK-тема
      GTK.application_prefer_dark_theme = true;

      # фон логина (картинка из репозитория; в сторе world-readable)
      background = {
        path = ../../home/config/wallpapers/brain-shell-default-0.png;
        fit = "Cover";
      };

      appearance.greeting_msg = "Welcome back, n3z";
    };
  };

  # VirtualBox: vmwgfx/SVGA3D не открывает 3D-канал (vmw_msg_ioctl Failed to
  # open channel) → cage падает на GL-инициализации и greetd уходит в
  # restart-loop. Форсим программный рендеринг wlroots (pixman), отключаем
  # аппаратные курсоры и переводим GTK4 на software-рендер (cairo).
  # Переопределяем mkDefault-команду модуля, сохраняя dbus-run-session и -d.
  services.greetd.settings.default_session.command =
    "${pkgs.coreutils}/bin/env WLR_RENDERER=pixman WLR_NO_HARDWARE_CURSORS=1 GSK_RENDERER=cairo "
    + "${pkgs.dbus}/bin/dbus-run-session ${lib.getExe pkgs.cage} -s -d -- ${lib.getExe pkgs.regreet}";

  # FALLBACK (если cage всё равно падает): текстовый грейтер без композитора.
  # Раскомментировать и убрать command выше:
  # services.greetd.settings.default_session.command =
  #   "${lib.getExe pkgs.tuigreet} --time --remember --cmd niri-session";
  # services.greetd.useTextGreeter = true;

  # greeter: прямой доступ к DRM/вводу в VM (libseat/DRM backend)
  users.users.greeter.extraGroups = [ "video" "input" ];

  # compositor
  programs.niri.enable = true;
}
