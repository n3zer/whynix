{ config, lib, pkgs, ... }:

let
  # Оборачивает GUI-пакет для запуска через dgpu-offload с безопасным fallback.
  # symlinkJoin сохраняет .desktop-файлы, иконки и ресурсы пакета, подменяя бинарники в bin/.
  wrapDgpu = pkg: bins: pkgs.symlinkJoin {
    name = "${pkg.name}-dgpu";
    paths = [ pkg ];
    postBuild = lib.concatMapStringsSep "\n" (bin: ''
      if [ -e $out/bin/${bin} ]; then
        rm -f $out/bin/${bin}
        cat > $out/bin/${bin} <<'EOF'
#!/usr/bin/env bash
if command -v dgpu-offload >/dev/null 2>&1; then
  exec dgpu-offload ${pkg}/bin/${bin} "$@"
else
  exec ${pkg}/bin/${bin} "$@"
fi
EOF
        chmod +x $out/bin/${bin}
      fi
    '') bins;
  };
in
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
    (pkgs.writeShellScriptBin "open-browser" ''
      exec ${config.home.sessionVariables.BROWSER} "$@"
    '')
    # fastfetch with a random ASCII logo per run.
    #
    # The only reason this wrapper exists is the randomness — fastfetch itself
    # does the rendering via `--logo <file> --logo-type file`. It shadows
    # pkgs.fastfetch on purpose, so do NOT also list pkgs.fastfetch here: two
    # providers of one name collide.
    #
    # Art is plain .txt, one drawing per file, merged from two dirs:
    #   ~/.local/share/fastfetch/ascii  yours, writable — just drop a file in
    #   <repo>/ascii                    built-in, read-only, shadowed by name
    # Override the user dir with FASTFETCH_ASCII_DIR.
    (pkgs.writeShellScriptBin "fastfetch" ''
      set -eu

      # The quickshell SystemStats panel calls `fastfetch -c systemstats` and
      # wants its key/value layout, logo-less. Any explicit --config/-c (or
      # --logo from the caller) means "run me exactly as asked".
      for arg in "$@"; do
        case "$arg" in
          -c|--config|--logo) exec ${pkgs.fastfetch}/bin/fastfetch "$@" ;;
        esac
      done

      # Glob, not find: the repo dir is a symlink into the nix store and find
      # will not descend into a symlinked directory without -L.
      art="$({
        for d in "''${FASTFETCH_ASCII_DIR:-''${XDG_DATA_HOME:-$HOME/.local/share}/fastfetch/ascii}" "${../config/fastfetch/ascii}"; do
          [ -d "$d" ] || continue
          for f in "$d"/*.txt; do
            [ -f "$f" ] && printf '%s\n' "$f"
          done
        done
      } | awk -v seed="$$-$(date +%s 2>/dev/null)" '
        BEGIN { srand(seed); n = 0 }
        {
          i = split($0, p, "/"); b = p[i]
          if (b in seen) next
          seen[b] = 1
          a[++n] = $0
        }
        END { if (n) print a[1 + int(rand() * n)] }
      ')"

      if [ -n "$art" ]; then
        exec ${pkgs.fastfetch}/bin/fastfetch --logo "$art" --logo-type file "$@"
      fi
      exec ${pkgs.fastfetch}/bin/fastfetch "$@"
    '')

    cava # audio visualizer bars (quickshell CavaService)
    matugen # wallpaper→theme color generator (WallpaperService re-themes on set)
    hyprlock # lock screen (PowerMenu / loginctl lock-session)
    neovim
    yazi
    playerctl
    brightnessctl
    (wrapDgpu spotify [ "spotify" ])
    unzip # copilot.lua extracts copilot-language-server with unzip

    # GUI file manager (Cabinet/zathura_pdf_mupdf/zen-browser не в этом ревизии nixpkgs)
    thunar
    xdg-utils # xdg-open / mime opening из yazi и других приложений

    # chat / messaging
    (wrapDgpu ayugram-desktop [ "AyuGram" ])
    (wrapDgpu discord [ "Discord" "discord" ])

    # Obsidian — Electron-приложение (unfree, allowUnfree уже включён в
    # nixos/modules/software.nix). Намеренно БЕЗ wrapDgpu, в отличие от
    # Discord/AyuGram выше: там оффлоад выигрывает, потому что кадры идут
    # из видео/голоса, здесь же интерфейс — текст и WebView, то есть растеризации
    # тяжёлой нет. А переключение на NVIDIA в обёртке dgpu-offload заставит
    # Electron брать EGL-вендор NVIDIA, и каждый кадр будет копироваться
    # dGPU -> iGPU, потому что композитит niri на Intel (eDP-1 подключён к
    # iGPU). Чистый проигрыш. Если всё же понадобится — `dgpu-offload obsidian`.
    #
    # Wayland: NIXOS_OZONE_WL в системе не выставлен, поэтому флаг
    # --ozone-platform=wayland из обёртки nixpkgs не добавится. Нативный
    # Wayland всё равно включится через ELECTRON_OZONE_PLATFORM_HINT=auto
    # из nixos/modules/nvidia.nix (electron 43), как у discord/antigravity.
    # Даёт .desktop, иконки hicolor и obsidian-cli (headless-заметки).
    obsidian

    # settings / utils
    blueman # bluetooth GUI manager (blueman-manager)
    hyprsunset # night light support for quicksettings

    # media / вьюверы
    (wrapDgpu mpv [ "mpv" "umpv" ])
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
    # bottom — Rust-монитор (github.com/clementtsang/bottom), бинарь btm.
    # Рядом с btop, а не вместо: btop в nixpkgs C++/с heavy widgets, bottom
    # легче и без GTK. Оба в ~/.local/state/nix профиле — конфликта имён нет
    # (btop против btm). Кто что показывает: btop — привычный вид, bottom —
    # если упёрлось в раскладку/производительность btop.
    bottom
    gcc
    gnumake
    pkg-config

    # rust: компилятор + утилиты, всё из nixpkgs (rustup сюда нельзя —
    # он тянет proxies bin/rustc и bin/cargo и ломает nix-тулчейн)
    rustc
    cargo
    clippy
    rustfmt
    rust-analyzer
    sccache # кэш компиляции
    cargo-edit # cargo add/rm/upgrade/install
    cargo-watch # cargo watch -x run
    bacon # фоновый cargo check с TUI
    cargo-expand # раскрыть макросы
    cargo-nextest # быстрые тесты
    cargo-llvm-cov # покрытие кода
    cargo-machete # неиспользуемые зависимости
    fd
    lsd # замена ls в интерактивных шеллах (алиас в modules/shell.nix)
    ripgrep
    hyperfine # бенчмарки
    just # task-раннер
    cmake zlib libgit2 protobuf # библиотеки для -sys crate'ов (prost/git2/...)
    gdb strace valgrind # отладка
    trunk wasm-pack # сборка wasm

    # idle / suspend (spawned by niri; locks + powers off monitors via swayidle)
    swayidle
    kando # круговое меню (Mod+Space)

    # LSP servers (nvim-lspconfig)
    pyright # python
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

  # Antigravity — IDE от Google (форк VS Code). Через home-manager-модуль,
  # а не просто пакетом: он даёт .desktop для меню приложений.
  # package указывается явно: в nixpkgs атрибут переименован в
  # antigravity-ide, и именно он заворачивается на dGPU (см. wrapDgpu).
  programs.antigravity = {
    enable = true;
    package = wrapDgpu pkgs.antigravity-ide [ "antigravity-ide" ];
  };
}