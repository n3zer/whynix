{ config, lib, pkgs, username ? "n3z", ... }:

{
  #git configuration
  programs.git = {
    enable = true;
    settings.user.name = username;
    settings.user.email = lib.mkDefault "your.email@example.com";
    settings.credential."https://github.com".helper = "!gh auth git-credential";
  };
}