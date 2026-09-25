{ config, lib, pkgs, ... }:

{
  #dotfiles symlinks
  xdg.configFile = {
    "niri" = { source = ../config/niri; force = true; };
    "quickshell" = { source = ../config/quickshell; force = true; };
    "alacritty/alacritty.toml".source = ../config/alacritty/alacritty.toml;
    "hyprlock/hyprlock.conf".source = ../config/hyprlock/hyprlock.conf;
    "yazi" = { source = ../config/yazi; };
    "swappy/config".source = ../config/swappy/config;
    "nvim/init.lua".source = ../config/nvim/init.lua;
    "nvim/lua".source = ../config/nvim/lua;
    "fastfetch" = { source = ../config/fastfetch; };
  };

  xdg.dataFile = {
    "wallpapers" = { source = ../config/wallpapers; };
  };

  # Seed the writable niri binds file so Mod+binds survive rebuilds (niri
  # includes it via binds.kdl; only copied when missing so live edits persist).
  home.activation.seedNiriBinds = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    mkdir -p "${config.xdg.stateHome}/niri"
    if [ ! -f "${config.xdg.stateHome}/niri/binds.user.kdl" ]; then
      cp "${../config/niri/binds.user.kdl}" "${config.xdg.stateHome}/niri/binds.user.kdl"
    fi
  '';

  # Seed the writable niri focus-ring override file (window-rules.kdl includes
  # it optional=true; WallpaperService updates it on every wallpaper apply).
  home.activation.seedNiriFocusRing = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    mkdir -p "${config.xdg.stateHome}/niri"
    if [ ! -f "${config.xdg.stateHome}/niri/focus-ring.user.kdl" ]; then
      cat > "${config.xdg.stateHome}/niri/focus-ring.user.kdl" <<'EOF'
// Auto-generated — managed by Brain Shell WallpaperService.
window-rule {
    match is-active=true
    focus-ring {
        active-color "#9e9fa4"
    }
}
EOF
    fi
  '';

  #environment variables
  home.sessionVariables = {
    BROWSER = "firefox";
    EDITOR = "nvim";
    TERMINAL = "alacritty";
  };
}