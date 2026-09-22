
{ config, pkgs, ... }:

{
  #user info
  home.username = "n3z";
  home.homeDirectory = "/home/n3z";

  #packages
  home.packages = with pkgs; [
    quickshell
    alacritty
    walker
    elephant
    wl-clipboard
    libnotify # notify-send (VPNTab / shell notifications)
    cliphist
    wf-recorder # screen recording (quickshell ScreenRecService)
    slurp # region/window picker for wf-recorder
    python3 # list_apps.py / ScreenRecService pickers
    awww # бывший swww (Rust-перезапись)
    (pkgs.writeShellScriptBin "wallpaper-cycle" (builtins.readFile ./config/scripts/wallpaper-cycle.sh)) # cycle wallpaper (Mod+W)
    fastfetch
    neovim
    yazi
    playerctl
    brightnessctl

    # LSP servers (nvim-lspconfig)
    pyright # python
    rust-analyzer # rust
    gopls # go
    csharp-ls # c#
    typescript-language-server # js/ts
    clang-tools # c/c++ (clangd)
    jdt-language-server # java
    vscode-langservers-extracted # html/css

    # github copilot (copilot.lua deps)
    jq
    openssl
  ];

  #dotfiles symlinks 
  xdg.configFile = {
    "niri" = { source = ./config/niri; force = true; };
    "quickshell" = { source = ./config/quickshell; force = true; };
    "alacritty/alacritty.toml".source = ./config/alacritty/alacritty.toml;
    "autostart/elephant.desktop".source = ./config/autostart/elephant.desktop;
    "autostart/walker.desktop".source = ./config/autostart/walker.desktop;
    "nvim/init.lua".source = ./config/nvim/init.lua;
    "nvim/lua".source = ./config/nvim/lua;
  };

  xdg.dataFile = {
    "wallpapers" = { source = ./config/wallpapers; };
  };

  #fish shell (autosuggestions out of the box)
  programs.fish = {
    enable = true;
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
