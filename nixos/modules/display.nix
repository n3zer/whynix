{ pkgs, ... }:

{
  services.greetd.enable = false;
  services.displayManager.regreet.enable = false;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "sddm-astronaut-theme";
    extraPackages = [ pkgs.qt6.qtmultimedia ];
    settings = {
      Theme = {
        CursorTheme = "Adwaita";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    sddm-astronaut
  ];

  security.pam.services.sddm.enableGnomeKeyring = true;

  services.accounts-daemon.enable = true;

  hardware.graphics = {
    enable = true;
    # 32-битные драйверы GL — нужно для Steam/Wine/32-битных игр
    enable32Bit = true;

    extraPackages = with pkgs; [
      vulkan-loader # загрузчик ICD
    ];
  };

  programs.niri.enable = true;
}
