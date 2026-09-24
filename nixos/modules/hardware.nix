{ config, lib, pkgs, ... }:

{
  imports = [ ../hardware-configuration.nix ];

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

  # vm (enable задан в hardware-configuration.nix — здесь только доп. опции)
  virtualisation.virtualbox.guest = {
    dragAndDrop = true;
  };

  # fix clipboard: the module's ExecStart uses "@" prefix which makes VBoxClient
  # daemonize + exit, so systemd restarts it and KillMode kills the daemon (flap).
  systemd.user.services.virtualboxClientClipboard = {
    serviceConfig.ExecStart = lib.mkForce
      "${config.boot.kernelPackages.virtualboxGuestAdditions}/bin/VBoxClient --foreground --clipboard";
  };
}