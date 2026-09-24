{ config, lib, pkgs, ... }:

{
  # dconf — обязателен для того, чтобы GTK (и Qt через gtk3-платформу)
  # читали настройки темы/иконок/курсора, выставленные ниже.
  dconf.enable = true;

  gtk = {
    enable = true;

    theme = {
      name = "catppuccin-mocha-mauve-standard";
      package = pkgs.catppuccin-gtk.override {
        variant = "mocha";
        accents = [ "mauve" ];
        size = "standard";
      };
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
    };

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 10;
    };
  };

  # Qt (telegram и пр.) тянется через GTK3-платформу → берёт catppuccin-gtk
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };

  home.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
  };
}