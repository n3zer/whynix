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
    geist-font
  ];

  # packages
  environment.systemPackages = with pkgs; [
    xwayland
    xwayland-satellite
    xdg-desktop-portal-gnome
    polkit_gnome
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
