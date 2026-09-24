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
    firefox
    catppuccin-sddm
    nodejs
    swayosd
    opencode
    omniroute.package
  ];

  # omniroute daemon — autostart at boot (systemd service defined in omniroute.nix)
  systemd.services.omniroute = omniroute.service;

}
