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
    qt6.qtmultimedia
  ];

  services.accounts-daemon.enable = true;

  hardware.graphics.enable = true;

  programs.niri.enable = true;
}
