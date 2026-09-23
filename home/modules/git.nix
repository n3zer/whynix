{ config, lib, pkgs, ... }:

{
  #git configuration
  programs.git = {
    enable = true;
    settings.user.name = "n3z";
    settings.user.email = "your.email@example.com"; # Замените на свою почту
    settings.credential."https://github.com".helper = "!gh auth git-credential";
  };
}