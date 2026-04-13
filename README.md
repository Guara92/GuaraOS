# GuaraOS 🦜

A personal, immutable Arch-based Linux image built on top of [CachyOS](https://cachyos.org/) using [bootc](https://bootc-dev.github.io/).

This is a private fork maintained for my own machines. It is not intended as a general-purpose distribution and comes with no support or stability guarantees.

---

## Targets

| Flavor | Arch | Desktop | Session | Machine |
|---|---|---|---|---|
| `guaraos-gnome` | `znver4` | GNOME | GNOME (GDM) | Daily driver (AMD Ryzen 7000+) |
| `guaraos-gamestation` | `znver4` | KDE Plasma | Gamescope → Plasma (plasmalogin) | Gaming rig (AMD Ryzen 7000+) |
| `guaraos-gamestation` | `v3` | KDE Plasma | Gamescope → Plasma (plasmalogin) | Gaming rig (generic x86-64) |
| `guaraos-cosmic` | `znver4` | COSMIC | COSMIC (cosmic-greeter) | Daily driver (AMD Ryzen 7000+) |

> **Swap:** On first boot, a 32 GiB swapfile is created at `/var/swap/swapfile` on a dedicated btrfs subvolume. zswap sits in front of it as a compressed in-RAM cache (`zstd` + `zsmalloc` + shrinker, 20% of RAM). `vm.swappiness=40`.
>
> **Snapshots:** Also on first boot, snapper is configured to take daily btrfs snapshots of the mutable state (`/etc` + `/var`). The `/var/swap` subvolume is excluded from snapshots by design.

---

## Build

Requires `just` and `podman`.

```bash
# Primary — znver4 / GNOME
just build znver4 base
just build znver4 gnome

# Primary — znver4 / COSMIC
just build znver4 base
just build znver4 cosmic

# Secondary — znver4 / Gamestation (AMD gaming rig)
just build znver4 base
just build znver4 gamestation

# Secondary — v3 / Gamestation (generic gaming rig)
just build v3 base
just build v3 gamestation
```

## Switch

To rebase a running `bootc` system to this image:

```bash
sudo bootc switch ghcr.io/guara92/guaraos-gnome:znver4
# or
sudo bootc switch ghcr.io/guara92/guaraos-cosmic:znver4
# or
sudo bootc switch ghcr.io/guara92/guaraos-gamestation:znver4
# or
sudo bootc switch ghcr.io/guara92/guaraos-gamestation:v3
```

> After switching from a Fedora-based OS run `sudo guara-migrate` on first boot to set up your systemd-homed account.

## Update

Once running:

```bash
guaraos-update
```

---

## User Management

GuaraOS uses [`systemd-homed`](https://systemd.io/HOME_DIRECTORY/) for user accounts. Home directories are self-contained and portable across upgrades.

When migrating from Bazzite or another Fedora-based OS, run:

```bash
sudo guara-migrate
```

This creates a homed user account, migrates preserved data (SSH keys, browser profiles, game libraries) from the old home, and resets shell configs from scratch.

---

## Swap

### zswap

GuaraOS uses **zswap** — a compressed in-RAM page cache that sits in front of a disk-backed swapfile:

```
RAM
 └─ zswap pool  (~20% of RAM, zstd + zsmalloc + shrinker, in RAM)
      └─ /var/swap/swapfile  (32 GiB, on disk — evicted pages only)
```

`vm.swappiness=40` — the kernel prefers evicting file cache (cheap, NVMe re-read) over compressing app/game memory; the pool is used only under genuine pressure.

On first boot, `guaraos-swap-setup.service`:
1. Creates `/var/swap` as a **dedicated btrfs nested subvolume** (required: the kernel refuses to activate a btrfs swapfile if its containing subvolume has snapshots; isolating `/var/swap` in its own subvolume keeps it snapshot-free)
2. Creates the 32 GiB swapfile inside it via `btrfs filesystem mkswapfile` (NOCOW + pre-allocation + mkswap in one step)
3. Activates swap and writes the `/etc/fstab` entry for persistence

`/var` is persistent across `bootc upgrade` — the subvolume and swapfile are created once and never touched again.

> **Hibernation:** the swapfile must be ≥ your RAM. Adjust size and update `/etc/fstab` + kernel `resume_offset` after first boot if you need it.

### Btrfs Snapshots

On first boot, `guaraos-snapper-setup.service` configures snapper using the `guaraos` template:

```
Daily timeline snapshots of:
  /             → captures /etc (config changes) + /var/* (app state, flatpaks, containers)
  excluding:
    /var/swap   → dedicated subvolume, never snapshotted (swapfile isolation)
    /var/cache  → @cache subvolume, excluded from parent snapshots
    /var/log    → @log subvolume, excluded from parent snapshots
    /var/tmp    → @tmp subvolume, excluded from parent snapshots
    /usr        → read-only bootc deployment, never changes between snapshots
```

Retention: **7 daily snapshots**, max 20% of disk. `snapper-cleanup.timer` and `snapper-timeline.timer` are both enabled.

`bootc rollback` handles OS-layer rollback. Snapper handles mutable-state rollback (`/etc` misconfigurations, corrupted app data). They complement each other.

> Manage snapshots via **Btrfs Assistant** (GUI) or `snapper list` / `snapper delete` (CLI).

---

## Credits

GuaraOS would not exist without the work of these projects:

- **[CachyOS](https://github.com/CachyOS)** — the Arch-based foundation, performance-tuned kernels, and repositories this image is built on
- **[BoppOS](https://github.com/bopp-os)** by [ripps818](https://github.com/ripps818) — the direct upstream fork this repo is derived from; most of the Containerfile architecture, build system, and custom scripts originate there
- **[cachyos-deckify-bootc](https://github.com/lumaeris/cachyos-deckify-bootc)** by [lumaeris](https://github.com/lumaeris) — the original project BoppOS forked from
- **[Bootcrew / mono](https://github.com/bootcrew/mono)** — shared bootc setup scripts used during the image build
- **[bootc](https://github.com/containers/bootc)** — the atomic image management layer that makes all of this possible

---

## License

Apache-2.0 — inherited from upstream. See [LICENSE](LICENSE).
