{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./modules/hardware.nix
      ./modules/system.nix
      ./modules/display.nix
      ./modules/software.nix
      ./modules/sound.nix
    ];

  system.stateVersion = "26.05";
}
