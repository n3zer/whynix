{ config, lib, pkgs, ... }:

let
  opencode = import ../packages/opencode.nix { inherit pkgs; };
  omniroute = import ../packages/omniroute.nix { inherit pkgs lib config; };
in
{
  # nix features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  # Необходим для выполнения внешнего бинарника OpenCode
  programs.nix-ld.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka
    nerd-fonts.daddy-time-mono
    material-icons
    material-symbols
    font-awesome
    geist-font
    noto-fonts-color-emoji # эмодзи (не тофу в TG/Discord)
    noto-fonts-cjk-sans # китайский/японский/корейский
  ];

  # xdg portal — point it at niri so GTK/Electron apps (file pickers, etc.)
  # work; gnome implementation handles FileChooser/Screenshot.
  xdg.portal = {
    enable = true;
    config.common.default = "gnome";
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };

  # packages
  environment.systemPackages = with pkgs; [
    xwayland
    xwayland-satellite
    polkit_gnome # polkit-gnome-authentication-agent-1 (spawned by niri)
    wget
    curl
    # firefox запускается на dGPU: внутренний экран подключён к iGPU, поэтому
    # сам компоновщик (niri) перенести нельзя, но тяжёлую растеризацию
    # браузера — можно. Обёртка dgpu-offload живёт в nixos/modules/nvidia.nix
    # (она подключается только в профиле laptop).
    #
    # Декодирование видео намеренно оставлено на iGPU (LIBVA_DRIVER_NAME=iHD
    # из сессии): NVDEC на Pascal не понимает AV1. Если AV1 не нужен и важнее
    # снять декод с iGPU — запускай вручную:
    #   DGPU_OFFLOAD_DECODE=nvidia dgpu-offload firefox
    #
    # Собирается через symlinkJoin, а не wrapProgram: в текущем nixpkgs
    # (nixos-unstable, rev ef34387dd) атрибут pkgs.wrapProgram отсутствует,
    # а через wrapProgram нельзя было бы сохранить desktop-файлы firefox —
    # они лежат в том же пакете. Имя пакета остаётся "firefox", чтобы в
    # environment.systemPackages не появилось двух записей с одним именем.
    (symlinkJoin {
      name = "firefox";
      paths = [ firefox ];
      postBuild = ''
        rm $out/bin/firefox
        cat > $out/bin/firefox <<'EOF'
        #!/usr/bin/env bash
        if command -v dgpu-offload >/dev/null 2>&1; then
          exec dgpu-offload ${firefox}/bin/firefox "$@"
        else
          exec ${firefox}/bin/firefox "$@"
        fi
        EOF
        chmod +x $out/bin/firefox
      '';
    })
    nodejs
    swayosd
    opencode
    omniroute.package
    # диагностика GPU/PCI: lspci для проверки драйверов и -kn (на чём
    # сидит HDA-контроллер), alsa-utils для карт/миксера, glxinfo +
    # vulkaninfo для проверки рендера, libva-utils для vainfo
    pciutils
    alsa-utils
    mesa-demos # даёт glxinfo
    vulkan-tools # даёт vulkaninfo
    # vainfo: без него не проверить, что iHD реально открылся и какие
    # профили декодирования доступны. Проверено — отдаёт
    # "Intel iHD driver ... 26.2.4" и VAEntrypointVLD для H264/HEVC/VP9.
    libva-utils
  ];

  # ── Steam ───────────────────────────────────────────────────────────────────
  # unfree-пакет, поэтому уже разрешён через nixpkgs.config.allowUnfree выше.
  #
  # Про openFirewall: все три опрокидываются на networking.firewall, который в
  # NixOS включён по умолчанию, а в этом репозитории нигде не выключен — без
  # них проброс портов не заработает вовсе.
  #
  # Про dGPU: внутренний экран (eDP-1) подключён к iGPU, поэтому сам компоновщик
  # niri переносить на NVIDIA нельзя, но игры запускаются отдельными процессами
  # и наследуют переменные окружения. Значит `dgpu-offload steam` (обёртка в
  # nixos/modules/nvidia.nix, подключается только в профиле laptop) отдаст
  # рендер игр на GTX 1060 — сам лаунчер при этом останется на Intel.
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  # omniroute: socket 20128 -> systemd-socket-proxyd -> backend 20129 on demand
  systemd.services = {
    omniroute = omniroute.service;
    omniroute-proxy = omniroute.proxy;
  };

  systemd.sockets.omniroute = omniroute.socket;

}
