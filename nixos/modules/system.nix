{ config, lib, pkgs, ... }:

{
  # locale
  time.timeZone = "Asia/Almaty";
  i18n.defaultLocale = "en_US.UTF-8";

  # network
  networking.networkmanager.enable = true;
  networking.hostName = "nixos-vm";

  # gnome-keyring — хранение паролей (Telegram/Discord/браузер), разблокируется
  # автоматически при входе через SDDM.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  # gvfs — монтирование USB/сетевых шаров/киоск-панели для thunar и xdg-open
  services.gvfs.enable = true;

  # местоположение для приложений
  services.geoclue2.enable = true;

  # обновление прошивок (fwupdmgr)
  services.fwupd.enable = true;

  # автообслуживание nix-стора
  nix.optimise.automatic = true;
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 14d";
  };

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