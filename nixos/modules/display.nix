{ config, lib, pkgs, ... }:

{
  # display manager
  services.xserver.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "catppuccin-mocha";
    settings = {
      Theme = {
        Current = "catppuccin-mocha";
        CursorTheme = "Adwaita";
      };
    };
  };

  # compositor
  programs.niri.enable = true;
}