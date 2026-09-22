{ config, lib, pkgs, ... }:

{
  # locale
  time.timeZone = "Asia/Almaty";
  i18n.defaultLocale = "en_US.UTF-8";

  # network
  networking.networkmanager.enable = true;
  networking.hostName = "nixos-vm";

  # ssh
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
    };
  };

  # user
  users.users.n3z = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    initialPassword = "changeme";
    shell = pkgs.fish;
    ignoreShellProgramCheck = true;
  };
}