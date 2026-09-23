{ config, lib, pkgs, ... }:

{
  #fish shell (autosuggestions out of the box)
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
      fastfetch
    '';
  };

  #bash shell (fallback)
  programs.bash = {
    enable = true;
    enableCompletion = true;
  };

  #starship prompt
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[❯](bold green)" ;
        error_symbol = "[❯](bold red)";
      };
    };
  };
}