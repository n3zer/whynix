# VirtualBox guest host profile (.#n3zer-vm).
#
# The bare-metal host profile is ./laptop.nix
{ config, lib, ... }:

{
  imports = [ ../hardware-configuration-vm.nix ];

  networking.hostName = "nixos-vm";

  virtualisation.virtualbox.guest.enable = true;

  # The upstream unit prefixes ExecStart with "@", which systemd passes as
  # argv[0] — so "--foreground" is swallowed as the program name and
  # VBoxClient daemonizes. systemd then sees the main process exit and
  # Restart=always loops (measured: 2524 restarts for DnD, 654 for Vmsvga).
  systemd.user.services = {
    virtualboxClientClipboard = {
      serviceConfig.ExecStart = lib.mkForce
        "${config.boot.kernelPackages.virtualboxGuestAdditions}/bin/VBoxClient --foreground --clipboard";
    };
    virtualboxClientDragAndDrop = {
      serviceConfig.ExecStart = lib.mkForce
        "${config.boot.kernelPackages.virtualboxGuestAdditions}/bin/VBoxClient --foreground --draganddrop";
    };
    virtualboxClientSeamless = {
      serviceConfig.ExecStart = lib.mkForce
        "${config.boot.kernelPackages.virtualboxGuestAdditions}/bin/VBoxClient --foreground --seamless";
    };
    virtualboxClientVmsvga = {
      serviceConfig.ExecStart = lib.mkForce
        "${config.boot.kernelPackages.virtualboxGuestAdditions}/bin/VBoxClient --foreground --vmsvga-session";
    };
  };
}
