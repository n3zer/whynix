{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./modules/packages.nix
      ./modules/shell.nix
      ./modules/git.nix
      ./modules/config.nix
      ./modules/theming.nix
    ];

  #user info
  home.username = "n3z";
  home.homeDirectory = "/home/n3z";

  #home manager state version
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
}