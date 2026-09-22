# Installing NixOS with dotfiles

A guide from disk partitioning to a full desktop (niri + quickshell).
Target config: **`nixos-vm`**, user **`n3z`**.

> Config: EFI, ext4 root, no swap, no encryption.
> Bootloader: **limine** (set automatically from the config).

---

## 0. Preparation

1. Download the [NixOS ISO](https://nixos.org/download) (minimal is enough).
2. Boot from the ISO; log in as `nixos` (no password) or `root`.

Network: `sudo systemctl start NetworkManager` (or `ip link` + `dhcpcd`), check with `ping -c1 nixos.org`.

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

The checked-in `hardware-configuration.nix` targets a different machine —
**disk UUIDs won't match**. Regenerate for the current layout:

```bash
nixos-generate-config --root /mnt --show-hardware-config > nixos/hardware-configuration.nix
```

Inspect the file: `fileSystems."/"` and `fileSystems."/boot"` must contain the
UUIDs of your freshly formatted partitions.

---

## 5. Installation

```bash
nixos-install --flake /mnt/etc/nixos-config#nixos
```

- `nixos-install` will ask for the **root password** — set it.
- User `n3z` gets `initialPassword = "changeme"`.
- Home-manager is installed as a NixOS module, nothing to run separately.

When done:

```bash
reboot
# remove the ISO from the drive
```

> Replace `#nixos` with the flake output name matching your machine
> (the checked-in flake defines `nixosConfigurations.nixos-vm`).

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
sudo nixos-rebuild switch --flake .#<hostname>
```

Home-manager is applied automatically (it's part of the system).

### 7.3 Rule for new files

**Every new file must be added to the git index BEFORE a rebuild:**

```bash
git add <new_files>
nixos-rebuild switch --flake .#<hostname>
```

The flake is built from the **git index**, not the working tree —
unstaged files are simply not included in the build.

### 7.4 First nvim run

On first open, lazy.nvim and plugins are fetched from GitHub — internet required:

```bash
nvim
```

---

## Checklist

- [ ] Partitioned: EFI (vfat) + root (ext4), both mounted at `/mnt` and `/mnt/boot`
- [ ] `hardware-configuration.nix` regenerated for current UUIDs
- [ ] `nixos-install --flake ...` finished without errors
- [ ] Logged in as `n3z`, password changed from `changeme`
- [ ] Email in `home/home.nix` replaced
- [ ] `nixos-rebuild switch --flake .#<hostname>` completes cleanly
- [ ] niri + quickshell are up, wallpapers in place

---

## Common issues

| Problem | Fix |
|---|---|
| `Included file ... not found` during build | File is new and not in git: `git add` → rebuild |
| Doesn't boot after install | EFI partition mounted at `/boot`, EFI enabled in firmware |
| quickshell silent | `pkill quickshell; quickshell &`, check `journalctl --user` |
| No network after reboot | `systemctl enable --now NetworkManager` |
| UUID errors at boot | Regenerate `hardware-configuration.nix` (§4) |