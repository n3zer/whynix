# n3z dotfiles — NixOS + Home Manager

A fully-declarative NixOS flake configuration for a scrolling **niri** compositor
desktop with a **Quickshell** shell ("Brain Shell" style), Catppuccin/Material-You
them rings, and a complete plug-and-use application stack.

Host: `n3zer`, user: `n3z`, flake target: `.#n3zer`.

---

## 1. Repository layout

```
flake.nix                       # inputs (nixos-unstable + home-manager) and wiring
nixos/
  configuration.nix             # imports the NixOS modules
  modules/
    hardware.nix                # bootloader (limine), VirtualBox guest, bluetooth
    display.nix                 # SDDM (catppuccin-mocha) + niri compositor
    system.nix                  # locale, network, keyring, gvfs, gc, users, ssh
    software.nix                # fonts, xdg portal, system packages, daemons
    sound.nix                   # pipewire/rtkit
  packages/
    opencode.nix                # pinned opencode binary (v1.18.31)
    omniroute.nix               # local AI router as a systemd service (port 20128)
home/
  home.nix                      # user + module imports
  modules/
    packages.nix                # all per-user software
    shell.nix                   # fish + starship + fastfetch
    git.nix                     # git + gh credential helper
    config.nix                  # dotfile symlinks, seeded niri overrides, env vars
    theming.nix                 # GTK/Qt themes, icons, cursor, fonts, dconf
  config/                       # the actual dotfiles (niri, quickshell, ...)
```

---

## 2. Software inventory

### User shell & UI

| Package | Purpose |
|---|---|
| `quickshell` | The desktop shell: top bar, dashboards, popups, system services |
| `niri` (system) | Scrollable-tiling Wayland compositor (window manager) |
| `alacritty` | GPU-accelerated terminal emulator (default `$TERMINAL`) |
| `swayosd` | On-screen display for volume/brightness changes (spawned at startup) |
| `hyprlock` | Screen locker; shown by the power menu, `Mod+L`, and on idle/sleep |
| `kando` | Radial "pie" menu for quick actions (`Mod+Space`) |
| `fastfetch` | System info printed on shell start |
| `cava` | Audio visualizer fed to the shell's visualizer bars |
| `wallpaper-cycle` | Built-in wrapper over `config/scripts/wallpaper-cycle.sh` — cycles/restores wallpapers (`Mod+W`) |

### Input / clipboard / wayland helpers

| Package | Purpose |
|---|---|
| `wl-clipboard`, `cliphist` | Wayland clipboard history (stores via `wl-paste --watch`) |
| `wtype` | Injects Ctrl+C/V/X so copy/paste work even on the Cyrillic layout |
| `wl-clipboard` | X11-binary fallbacks |
| `xwayland`, `xwayland-satellite` | X11 app support on Wayland |
| `xdg-utils` | `xdg-open` / MIME opening for yazi & other apps |

### Applications

| Package | Purpose |
|---|---|
| `firefox` | Default browser |
| `thunar` | Graphics file manager (GUI) |
| `yazi` | Terminal file manager with thumbnails/previews |
| `telegram-desktop` | Telegram messenger |
| `discord` | Discord messenger |
| `spotify` | Music streaming |
| `mpv` + `yt-dlp` | Video/media player with YouTube support |
| `imv` | Lightweight image viewer |
| `zathura` | PDF/DJVU/CBZ document viewer (all backends bundled) |
| `neovim` | Editor (`$EDITOR`) with LSP + Copilot, plugins fetched at first run |
| `lazygit` | TUI git client |
| `btop` | System monitor (CPU/mem/disk/net) |

### Screenshots & capture

| Package | Purpose |
|---|---|
| `grim`, `slurp`, `wf-recorder` | screen grab / region picker / screen recording |
| `swappy` | Screenshot annotation editor |
| `screenshot-edit` (custom bin) | `grim -g "$(slurp)" - \| swappy -f -` — region → editor |
| `yt-dlp` | media download / mpv streaming |

### Theming

| Package | Purpose |
|---|---|
| `awww` | Wallpaper daemon (Rust rewrite of swww) — sets/animates wallpapers |
| `matugen` | Generates Material-You colors from the wallpaper; re-themes the shell live |
| `catppuccin-gtk` | GTK2/3/4 theme (mocha-mauve) applied via Home Manager |
| `papirus-icon-theme` | App icons (dark variant) |
| `bibata-cursors` | Cursor theme |
| `catppuccin-sddm` | Login manager theme |

### Development

| Package | Purpose |
|---|---|
| LSP servers | `pyright` (py), `rust-analyzer`, `gopls` (go), `csharp-ls`, `typescript-language-server`, `clang-tools` (c/c++), `jdt-language-server` (java), `vscode-langservers-extracted` (html/css) |
| `gcc`, `gnumake`, `pkg-config` | build toolchain |
| `nodejs` | JS runtime (LSP + scripts) |
| `jq`, `openssl`, `unzip` | Copilot / scripting deps |
| `github-cli` (`gh`) | GitHub auth, PRs, git credential helper |
| `opencode` | CLI coding agent (pinned release) |
| `omniroute` | local AI model router — systemd service on `:20128` |

### Other utilities

| Package | Purpose |
|---|---|
| `hyprpicker` | color picker (theme from any pixel) |
| `tesseract` | OCR from screenshots (English bundled) |
| `brightnessctl`, `playerctl`, `libnotify` | brightness/media-key/notification control |
| `python3` | shell scripts (app lists, screen recorder pickers) |

### System-level (NixOS)

| Module | Provides |
|---|---|
| `display.nix` | SDDM (Wayland, catppuccin-mocha) + niri |
| `hardware.nix` | limine bootloader, VirtualBox guest (clipboard), bluetooth (on at boot) |
| `sound.nix` | PipeWire (ALSA + PulseAudio) with RTKit |
| `system.nix` | NetworkManager, OpenSSH, gnome-keyring (+ PAM unlock at login), gvfs, geoclue2, fwupd, auto nix-gc + store optimisation, user `n3z` (wheel/networkmanager/video) |
| `software.nix` | flakes, `allowUnfree`, nix-ld, fonts, xdg-portal (niri→gnome), polkit |

### Fonts (system-wide)

`JetBrainsMono NF`, `Iosevka NF`, `DaddyTimeMono NF`, `Material Icons`, `Material Symbols`,
`Font Awesome`, `Geist`, `Noto Color Emoji`, `Noto CJK Sans`.

---

## 3. Feature walkthrough

### Startup (niri `spawn-at-startup`)

1. `quickshell` — the shell (bar + services)
2. `awww-daemon` + `wallpaper-cycle restore` — wallpaper restored on login
3. `wl-paste --watch cliphist store` — clipboard history grows automatically
4. `swayosd-server` — OSD for volume/backlight
5. `polkit-gnome-authentication-agent-1` — GUI sudo/privilege prompts
6. `swayidle` — idle management:
   - 5 min → screens power off (`niri msg action power-off-monitors`)
   - 10 min → `hyprlock`
   - 10:15 → `systemctl suspend`
   - before sleep → lock; after resume → monitors power on

### Shell (Quickshell)

- Top bar per screen: workspaces, clock, audio, network/BT, battery, system tray, notifications
- Dashboards (toggleable): **Home** (clock, calendar, media player, quick settings, profile), **Launcher**, **Stats**, **Kanban**, **Config** (live keybind editor)
- Popups: WiFi, Bluetooth, VPN, Hotspot, Audio (output/input/mixer), Notifications, Clipboard history, Wallpaper picker, Power menu, Screen-recorder options, Nix-menu
- Live theming: applying a wallpaper runs `matugen`, which recalculates accent colors and hot-reloads the shell; niri focus-ring color follows too
- System services polled for stats: CPU freq, memory, disk, network, GPU, thermals, fans, battery with warnings

### Clipboard

Copy/paste/cut are bound to `Mod+C/V/X` through `wtype` so they work with the
Russian layout active; history is captured by `cliphist` and browsable via `Mod+V`.

### Screenshots

- `Print` — full screen · `Shift+Print` — area · `Ctrl+Print` — window (saved to `~/Pictures/Screenshots`)
- `Mod+Shift+Print` — area → opens in `swappy` for annotation
- `Mod+Z` — screen recording via `wf-recorder`

### Theming (GTK/Qt)

`dconf` + `gtk` + `qt(gtk3 platform theme)` in `home/modules/theming.nix` apply the
Catppuccin mocha-mauve GTK theme, Papirus icons, Bibata cursor, and JetBrains Mono
system font to *all* apps (including Qt-based Telegram and Electron apps).

---

## 4. Keybindings

`Mod` = <kbd>Super</kbd>. Editable at runtime from the **Config** dashboard;
bindings live in `~/.local/state/niri/binds.user.kdl`.

| Keys | Action |
|---|---|
| `Mod+T` | terminal (alacritty) |
| `Mod+A` | apps launcher (walker) |
| `Mod+Space` | kando pie menu |
| `Mod+W` | cycle wallpaper |
| `Mod+M` / `Mod+S` / `Mod+K` / `Mod+Shift+C` | home / stats / kanban / config dashboards |
| `Mod+L` | lock screen (hyprlock) |
| `Mod+Q` | close window |
| `Mod+F` / `Mod+Shift+F` | maximize column / fullscreen |
| `Mod+Ctrl+F` | float window |
| `Mod+↑↓←→` | focus window/column |
| `Mod+Ctrl+HJKL` | move window/column |
| `Mod+PageUp/Down` | workspace up/down |
| `Mod+1…9,0` | focus workspace n |
| `Mod+Ctrl+1…9,0` | move column to workspace n |
| `Mod+Shift+h/l/j/k` | resize column/window |
| `Mod+[` `Mod+]` | consume/expel column |
| `Mod+D` | workspace overview |
| `Print` / `Shift+Print` / `Ctrl+Print` / `Mod+Shift+Print` | screenshots (screen/area/window/edit) |
| `Mod+C` / `Mod+Shift+V` / `Mod+X` | copy / paste / cut (layout-independent) |
| `F9`–`F11`, `XF86Audio*` | mute / vol- / vol+ |
| `Mod+E` / `Mod+B` / `Mod+Y` / `Mod+H` | WiFi / Bluetooth / VPN / Hotspot popups |
| `Mod+N` / `Mod+V` / `Mod+Shift+W` | notifications / clipboard / wallpaper picker |
| `Mod+P` / `Mod+Z` / `Mod+Shift+S` | power menu / screen record / focus mode |
| `Mod+O` / `Mod+I` / `Mod+Shift+M` | audio output / input / mixer |

---

## 5. Maintenance

```bash
nixos-rebuild switch --flake .#n3zer
```

- The flake builds from the **git index**: every new file must be staged first
  (`git add`), or it won't exist in the Nix store and builds will fail.
- Home Manager is applied as part of `nixos-rebuild`; no separate command.
- `niri validate` checks the compositor config (`~/.config/niri/config.kdl`).
- Nix store is auto-optimised and garbage-collected (older than 14 days) nightly.

### OmniRoute (`:20128` lazy front → `:20129` backend)

The backend binary is **not** fetched via npx at runtime. Install it once into the
user npm prefix (already done on this machine), matching the service's `PATH`:

```bash
npm install --global omniroute --prefix ~/.npm-global
```

`omniroute.service` (socat front on `:20128`) lazily spawns the backend on the
first connection and forwards to `:20129`. Check: `systemctl status omniroute`
then `curl 127.0.0.1:20128`.