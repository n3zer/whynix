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
    # firefox НАМЕРЕННО ОТСУТСТВУЕТ в этом общем модуле.
    #
    # Он host-specific, потому что способ запуска различается:
    #   • nixos/profiles/laptop.nix        — обёртка dgpu-offload (dGPU есть)
    #   • nixos/profiles/virtualbox-guest.nix — обычный пакет (dGPU нет)
    #
    # Если объявить его здесь, оба профиля получат по TWO записи с именем
    # "firefox" ( NixOS склеивает списки environment.systemPackages ), и в
    # профиле ноутбука одна из них перекроет другую непредсказуемо.
    # Декодирование видео в обоих случаях остаётся на iGPU через
    # LIBVA_DRIVER_NAME — NVDEC на Pascal не понимает AV1.
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
