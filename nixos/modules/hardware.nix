{ config, lib, pkgs, ... }:

{
  # bluetooth (quickshell BluetoothTab / QuickSettings -> bluetoothctl)
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # boot loader
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = false;
  boot.loader.limine = {
    enable = true;
    maxGenerations = 5;
  };
  boot.loader.efi.canTouchEfiVariables = true;
}
