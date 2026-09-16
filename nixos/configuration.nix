{ config, lib, pkgs, ... }:

let
   # Декларативная сборка бинарника OpenCode из официального релиза
  opencode-bin = pkgs.stdenv.mkDerivation {
    pname = "opencode";
    version = "1.18.31";

    src = pkgs.fetchurl {
      url = "https://github.com/anomalyco/opencode/releases/download/v1.18.31/opencode-linux-x64-baseline.tar.gz";
      hash = "sha256-soPo2+nm/CJLtLeZks470hdLi3sMPn0bTmAkodEe3IQ=";
    };

    dontUnpack = true;
    dontBuild = true;
    dontStrip = true;
    dontPatchELF = true;

    installPhase = ''
      mkdir -p $out/bin
      tar -xzf $src -C $out/bin
      chmod +x $out/bin/opencode
    '';
  };
  in
{
  imports =
    [
      ./hardware-configuration.nix
    ];

  # nix features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # vm
  virtualisation.virtualbox.guest = {
    enable = true;
    dragAndDrop = true;
  };

  # boot loader
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = false;
  boot.loader.limine = {
    enable = true;
    maxGenerations = 5;
  };
  boot.loader.efi.canTouchEfiVariables = true;

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

  # locale
  time.timeZone = "Asia/Almaty";
  i18n.defaultLocale = "en_US.UTF-8";

  # user
  users.users.n3z = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    initialPassword = "changeme";
  };

  # display manager
  services.xserver.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "catppuccin-mocha";
    settings = {
      Theme = {
        Current = "catppuccin-mocha";
        CursorTheme = "Adwaita";
      };
    };
  };

  # niri
  programs.niri.enable = true;

  # Необходим для выполнения внешнего бинарника OpenCode
  programs.nix-ld.enable = true;

  # packages
  environment.systemPackages = with pkgs; [
    wl-clipboard 
    eww
    alacritty
    fuzzel
    mako
    xwayland
    git
    wget
    curl
    neovim
    fastfetch
    firefox
    catppuccin-sddm
    nodejs

    # Наш декларативный пакет
    opencode-bin
  ];

  # sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "26.05";
}
