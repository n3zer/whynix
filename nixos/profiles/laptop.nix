# Bare-metal host profile (.#n3zer).
#
# The VM has its own profile: ./virtualbox-guest.nix
{ config, lib, pkgs, ... }:

{
  imports = [ ../hardware-configuration.nix ];

  networking.hostName = "nixos-laptop";

  # laptop-only hardware services; harmless on a desktop too
  services.auto-cpufreq = {
    enable = true;
    settings = {
      charger = {
        governor = "performance";
        turbo = "auto";
      };
      battery = {
        governor = "powersave";
        turbo = "never";
      };
    };
  };

  services.upower.enable = true;

  # laptop lid handling
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };
}
