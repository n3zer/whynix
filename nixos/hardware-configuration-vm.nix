# Hardware description for the VirtualBox guest (.#n3zer-vm).
#
# Captured from the VM's own ‘nixos-generate-config’ run. UUIDs are stable
# for that virtual disk only — do NOT reuse this file on real hardware.
# The bare-metal target uses ../hardware-configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  boot.initrd.availableKernelModules = [ "ata_piix" "ohci_pci" "ehci_pci" "ahci" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/b1650e09-1c8e-4096-897d-9d0d2ccf89ef";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/C04C-C63B";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
