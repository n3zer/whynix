{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    quickshell
    alacritty
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
    matugen # wallpaper→theme color generator (WallpaperService re-themes on set)
    hyprlock # lock screen (PowerMenu / loginctl lock-session)
    neovim
    yazi
    playerctl
    brightnessctl
    spotify
    unzip # copilot.lua extracts copilot-language-server with unzip

    # GUI file manager (Cabinet/zathura_pdf_mupdf/zen-browser не в этом ревизии nixpkgs)
    thunar
    xdg-utils # xdg-open / mime opening из yazi и других приложений

    # chat / messaging
    telegram-desktop
    discord

    # media / вьюверы
    mpv
    yt-dlp # youtube/video в mpv
    imv # изображения
    zathura # pdf (все плагины идут в составе пакета)
    swappy # редактирование скриншотов
    grim # захват экрана (для screenshot-edit)
    chafa # yazi preview картинок в терминале
    ffmpegthumbnailer # yazi preview видео-обложек
    bat # подсветка текста в yazi preview
    (pkgs.writeShellScriptBin "screenshot-edit" ''
      exec ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.swappy}/bin/swappy -f -
    '') # region → swappy editor
    # polkit_gnome кладёт бинарь только в libexec (не на PATH) — даём wrapper,
    # чтобы spawn-at-startup "polkit-gnome-authentication-agent-1" находил его.
    (pkgs.writeShellScriptBin "polkit-gnome-authentication-agent-1" ''
      exec ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
    '')
    hyprpicker # пипетка цвета (тематизация от любого пикселя)
    tesseract # OCR из скриншотов (eng в комплекте)

    # dev utilities
    lazygit
    btop
    gcc
    gnumake
    pkg-config

    # idle / suspend (spawned by niri; locks + powers off monitors via swayidle)
    swayidle
    kando # круговое меню (Mod+Space)

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