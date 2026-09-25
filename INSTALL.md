# Installing NixOS with dotfiles

A guide from disk partitioning to a full desktop (niri + quickshell).
Target config: **`n3zer`**, user **`n3z`**.

> Config: EFI, ext4 root, no swap, no encryption.
> Bootloader: **limine** (set automatically from the config).

---

## Flake targets

| Target | Purpose | VirtualBox |
|---|---|---|
| `.#n3zer` | **bare metal — use this on the laptop** | off |
| `.#n3zer-vm` | VirtualBox guest (this machine) | on |

Both share the same modules and Home Manager config. The only differences are
`nixos/profiles/laptop.nix` (hostname, auto-cpufreq, lid handling) and
`nixos/profiles/virtualbox-guest.nix` (guest additions + VBoxClient services).

Each target has its **own** hardware description:

- `nixos/hardware-configuration.nix` — bare metal. **Regenerate it on the
  target machine** (step 4); the committed copy points at a different disk.
- `nixos/hardware-configuration-vm.nix` — the VM's virtual disk. Leave it alone.

---

## 0. Preparation

1. Download the [NixOS ISO](https://nixos.org/download) (minimal is enough).
2. Boot from the ISO; log in as `nixos` (no password) or `root`.

Network: `sudo systemctl start NetworkManager` (or `ip link` + `dhcpcd`), check with `ping -c1 nixos.org`.

> Before installing on a laptop, **disable Secure Boot** in the firmware.
> limine does not chain-load through it.

---

## 1. Disk partitioning

Find your disk with `lsblk`. Below **`/dev/sdX`** = your disk.

```bash
fdisk /dev/sdX
```

In fdisk:

| Command | Action |
|---|---|
| `g` | new GPT table |
| `n` + Enter×3 | first partition, until end of disk |
| `t` + `1` | type = EFI System |
| `n` + Enter×3 | second partition (root), until end |
| `w` | write and exit |

Result:

```
/dev/sdX1  ~1G   EFI  (type EFI System)
/dev/sdX2  ~rest  root
```

> No swap — that's intended (`swapDevices = [ ];` in the config).
> You can add a swap partition, but then it will appear in hardware-config too.

---

## 2. Formatting and mounting

```bash
mkfs.vfat -F32 /dev/sdX1
mkfs.ext4 -L nixos /dev/sdX2

mount /dev/sdX2 /mnt
mkdir -p /mnt/boot
mount /dev/sdX1 /mnt/boot
```

Verify: `lsblk` — `/dev/sdX2 → /mnt`, `/dev/sdX1 → /mnt/boot`.

---

## 3. Cloning the repository

```bash
cd /mnt/etc
git clone <REPO_URL> nixos-config
# or copy it over manually:
# cp -r /path/to/dotfiles /mnt/etc/nixos-config
cd nixos-config
```

---

## 4. Generating hardware-configuration.nix

The checked-in `nixos/hardware-configuration.nix` targets a different machine —
**disk UUIDs won't match**. Regenerate for the current layout:

```bash
cd /mnt/etc/nixos-config
nixos-generate-config --root /mnt > nixos/hardware-configuration.nix
git add nixos/hardware-configuration.nix
```

Inspect the file: `fileSystems."/"` and `fileSystems."/boot"` must contain the
UUIDs of your freshly formatted partitions.

> The `git add` is **required** — the flake is built from the git index, so an
> untracked file never reaches the Nix store and the build fails with
> "Included file ... not found".

---

## 5. Installation

```bash
nixos-install --flake /mnt/etc/nixos-config#n3zer
```

- `nixos-install` will ask for the **root password** — set it.
- User `n3z` gets `initialPassword = "changeme"`.
- Home-manager is installed as a NixOS module, nothing to run separately.
- Hostname will be `nixos-laptop` — change it in `nixos/profiles/laptop.nix`.

When done:

```bash
reboot
# remove the ISO from the drive
```

> Use `#n3zer` for real hardware. `#n3zer-vm` is for the VirtualBox guest and
> would try to mount the VM's UUIDs.

---

## 6. First login

1. Log in at SDDM: **`n3z` / `changeme`**.
2. Change the password right away:

```bash
passwd
```

3. Should start: niri → quickshell (bar), walker/elephant (launcher),
   wallpaper-cycle (wallpapers). If quickshell doesn't come up:

```bash
pkill quickshell; quickshell &
```

---

## 7. Post-install dotfiles

### 7.1 Git identity

In `home/home.nix` replace the placeholder:

```nix
programs.git = {
  userName = "n3z";
  userEmail = "your.email@example.com";  # ← your address
};
```

### 7.2 Rebuild

```bash
cd ~
git clone <REPO_URL> # or the path of your repo, e.g. ~/dotfiles
cd dotfiles
sudo nixos-rebuild switch --flake .#n3zer
```

Home-manager is applied automatically (it's part of the system).

### 7.3 Rule for new files

**Every new file must be added to the git index BEFORE a rebuild:**

```bash
git add <new_files>
nixos-rebuild switch --flake .#n3zer
```

The flake is built from the **git index**, not the working tree —
unstaged files are simply not included in the build.

### 7.4 First nvim run

On first open, lazy.nvim and plugins are fetched from GitHub — internet required:

```bash
nvim
```

### 7.5 NVIDIA laptops (optional)

The power menu hides the "GPU Mode" section unless `envycontrol` is present —
it is **not** in nixpkgs, so it needs its own flake input. To enable GPU
switching on a hybrid-graphics laptop:

```nix
# flake.nix
inputs.envycontrol.url = "github:bayasdev/envycontrol";
```

```nix
# nixos/profiles/laptop.nix
environment.systemPackages = [ inputs.envycontrol.packages.x86_64-linux.default ];
```

```nix
# nixos/modules/display.nix
hardware.nvidia = {
  modesetting.enable = true;
  powerManagement.enable = false;   # envycontrol handles switching
  nvidiaSettings = true;
};
```

Integrated-only laptops (Intel/AMD) need none of this — Mesa handles them and
the section stays hidden.

---

## Checklist

- [ ] Secure Boot disabled in firmware (limine)
- [ ] Partitioned: EFI (vfat) + root (ext4), both mounted at `/mnt` and `/mnt/boot`
- [ ] `hardware-configuration.nix` regenerated for current UUIDs and `git add`ed
- [ ] `nixos-install --flake ...#n3zer` finished without errors
- [ ] Logged in as `n3z`, password changed from `changeme`
- [ ] Email in `home/home.nix` replaced
- [ ] `nixos-rebuild switch --flake .#n3zer` completes cleanly
- [ ] niri + quickshell are up, wallpapers in place
- [ ] Lid close suspends, screen brightness keys work (`brightnessctl`)

---

## Common issues

| Problem | Fix |
|---|---|
| `Included file ... not found` during build | File is new and not in git: `git add` → rebuild |
| Doesn't boot after install | EFI partition mounted at `/boot`, EFI enabled in firmware, Secure Boot off |
| Sticks at firmware / no boot entry | Secure Boot on, or the ISO wasn't booted in UEFI mode |
| Boots but black screen | Check `journalctl -b \| grep -i niri`; try `pkill quickshell; quickshell &` |
| No suspend on lid close | `services.logind.settings.Login.HandleLidSwitch` in `nixos/profiles/laptop.nix` |
| quickshell silent | `pkill quickshell; quickshell &`, check `journalctl --user` |
| No network after reboot | `systemctl enable --now NetworkManager` |
| UUID errors at boot | Regenerated `hardware-configuration.nix` (§4) and `git add`ed it |
| GPU Mode section missing in power menu | Expected — `envycontrol` is not installed (§7.5) |
| No network after reboot | `systemctl enable --now NetworkManager` |
| UUID errors at boot | Regenerate `hardware-configuration.nix` (§4) |