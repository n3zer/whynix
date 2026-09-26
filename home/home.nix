{ config, lib, pkgs, username ? "n3z", ... }:

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
  home.username = username;
  home.homeDirectory = "/home/${username}";

  #home manager state version
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;
}
