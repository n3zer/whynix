
{ config, pkgs, ... }:

{
  #user info
  home.username = "n3z";
  home.homeDirectory = "/home/n3z";

  #packages
  home.packages = with pkgs; [
    eww
    alacritty
    fuzzel
    mako
    wl-clipboard
    fastfetch
    neovim
  ];

  #dotfiles symlinks 
  xdg.configFile = {
    "niri/config.kdl".source = ./config/niri/config.kdl;
    "eww".source = ./config/eww;
    "alacritty/alacritty.toml".source = ./config/alacritty/alacritty.toml;
    "nvim/init.lua".source = ./config/nvim/init.lua;
    "nvim/lua".source = ./config/nvim/lua;
  };

  #git configuration
  programs.git = {
    enable = true;
    userName = "n3z";
    userEmail = "your.email@example.com"; # Замените на свою почту
  };

  #environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
    TERMINAL = "alacritty";
  };

  #home manager state version
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
}
