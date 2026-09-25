{ config, lib, pkgs, ... }:

{
  # bluetooth (quickshell BluetoothTab / QuickSettings -> bluetoothctl)
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # switcheroo-control: D-Bus-демон, который опрашивает DRM-карты и отвечает,
  # можно ли переключиться на интегрированную графику. На гибридной связке
  # Intel UHD 630 + NVIDIA он даёт `switcherooctl list` / `-c launch`, чем
  # пользуются niri, Thunar и часть файловых менеджеров для выбора GPU
  # у отдельного приложения. Ставится в systemPackages и в multi-user.target.
  services.switcherooControl.enable = true;

  # boot loader
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = false;
  boot.loader.limine = {
    enable = true;
    maxGenerations = 5;
  };
  boot.loader.efi.canTouchEfiVariables = true;
}
