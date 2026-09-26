{ config, lib, pkgs, username ? "n3z", ... }:

{
  # locale
  time.timeZone = lib.mkDefault "Asia/Almaty";
  i18n.defaultLocale = "en_US.UTF-8";

  # network
  networking.networkmanager.enable = true;
  # hostName is set per host profile (nixos/profiles/laptop.nix, virtualbox-guest.nix)

  # gnome-keyring — хранение паролей (Telegram/Discord/браузер), разблокируется
  # автоматически при входе. greetd подключает PAM-стек `login`
  # (auth substack / session include), поэтому keyring вешаем на login.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # gvfs — монтирование USB/сетевых шаров/киоск-панели для thunar и xdg-open
  services.gvfs.enable = true;

  # местоположение для приложений
  services.geoclue2.enable = true;

  # обновление прошивок (fwupdmgr)
  services.fwupd.enable = true;

  # автообслуживание nix-стора
  nix.optimise.automatic = true; # weekly nix-store --optimise (хватает; auto-optimise избыточен)
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 14d";
  };

  # ssh
  services.openssh = {
    enable = true;
    startWhenNeeded = true; # поднимать sshd только по подключению (меньше демонов в стоке)
    settings = {
      PasswordAuthentication = lib.mkDefault false;
      PermitRootLogin = lib.mkDefault "no";
    };
  };

  environment.shells = [ pkgs.fish ];

  # user
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "render" "input" ];
    initialPassword = lib.mkDefault "changeme";
    shell = pkgs.fish;
    ignoreShellProgramCheck = true;
  };
}