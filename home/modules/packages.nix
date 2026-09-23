{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    quickshell
    alacritty
    walker
    elephant
    wl-clipboard
    wtype # clipboard actions from any keyboard layout (Mod+C/V/X)
    libnotify # notify-send (VPNTab / shell notifications)
    cliphist
    wf-recorder # screen recording (quickshell ScreenRecService)
    slurp # region/window picker for wf-recorder
    python3 # list_apps.py / ScreenRecService pickers
    awww # бывший swww (Rust-перезапись)
    (pkgs.writeShellScriptBin "wallpaper-cycle" (builtins.readFile ../config/scripts/wallpaper-cycle.sh)) # cycle wallpaper (Mod+W)
    fastfetch
    cava # audio visualizer bars (quickshell CavaService)
    neovim
    yazi
    playerctl
    brightnessctl
    spotify
    unzip # copilot.lua extracts copilot-language-server with unzip

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

    github-cli # gh: push, branches, PRs via GitHub
  ];
}