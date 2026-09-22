{ config, lib, pkgs, ... }:

{
  imports = [ ../hardware-configuration.nix ];

  # boot loader
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = false;
  boot.loader.limine = {
    enable = true;
    maxGenerations = 5;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # vm
  virtualisation.virtualbox.guest = {
    enable = true;
    dragAndDrop = true;
  };
}