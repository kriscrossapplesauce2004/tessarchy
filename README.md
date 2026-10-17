# Tessarchy

**Touch-first Arch Linux, built around the Tessera shell.**

Tessarchy is an experimental Linux environment for tablets and phone-sized
screens. It brings together Arch Linux, Hyprland, and a Quickshell/QML shell
with visible navigation and large touch targets. Inspired by Omarchy's cohesive,
opinionated experience, Tessarchy is developing its own mobile-focused session.

The first target is an x86_64 QEMU/KVM guest, followed by touchscreen tablets.
Selected ARM devices are a later goal with explicit hardware support. The
project ships session source, development tooling and an experimental x86_64
live tester ISO.

[Download the tester ISO](https://github.com/thediamondsaint/tessarchy/releases/tag/v0.1.0-alpha.1) ·
[Getting started](#quick-start-use-the-basic-arch-vm) ·
[Architecture](docs/architecture.md) ·
[Roadmap](docs/roadmap.md) ·
[Testing](docs/testing.md) ·
[Contributing](CONTRIBUTING.md)

## What works today

- A top status bar with clock, registered tray icons, battery status when available,
  and session controls.
- A power panel in quick controls: battery charge state, time left/to full, and
  health when a battery is present, plus power-mode selection through
  power-profiles-daemon (shipped in the live image).
- Automatic Phone/Tablet/Desktop shell layouts with a saved manual override.
- A persistent navigation bar with 56px touch targets and a compact desktop dock.
- An original mint-and-navy wallpaper, animated tessellated logo, and responsive
  tile launcher.
- Settings for layout mode, accent, opacity, wallpaper shade, clock, navigation
  labels, and reduced motion.
- Translucent bars, Wi-Fi/cellular indicator slots, and an optional PipeWire
  audio panel with output-device switching, volume/mute, and per-app stream
  volumes. Wireless and modem backends remain to be connected.
- Screen brightness in quick controls wherever a backlight exists, with
  XF86MonBrightness keys wired to the same shipped helper, plus a persisted
  hyprsunset night-light toggle (both shipped in the live image).
- The panel blanks after five idle minutes (hypridle, shipped in the live
  image) and wakes on any input, with no lock screen and no locking claims.
- An expandable launcher for Firefox and Foot.
- A scrollable window overview with application switching and maximize/restore.
- A Desktop layout mode with a workspace strip, focused-window title, ordinary
  tiling for new apps, and keyboard shortcuts for workspaces, focus, moving,
  closing, dragging and resizing windows.
- Confirmation before closing a window or ending the session.
- Notification pop-ups and an alert center backed by Quickshell's
  `org.freedesktop.Notifications` server, with a persisted "mute pop-ups" toggle.
- Full-screen screenshots from Quick controls or the Print key, saved to
  Pictures/Screenshots and confirmed with a desktop notification when one
  is available.
- A dedicated Hyprland session, user installation, and reversible tty1 startup.
- A QEMU development workflow, local Arch package recipes, and an initial
  archiso staging/build pipeline.
- Fish bundled in the live image as the `tess` login shell, with the same
  one-shot tty1 session start as the Bash profile.

## Project status

**Early prototype.** A user has confirmed that Tessera runs in the basic Arch
QEMU guest. Ten workflow tests, Qt Quick layout/motion checks, and available
static checks pass.
Detailed touchscreen, scaling, focus, and window-action acceptance tests remain
pending. Two development packages have been built locally; they are not yet
published packages. The [Alpha 1 tester ISO](https://github.com/thediamondsaint/tessarchy/releases/tag/v0.1.0-alpha.1)
has been published and observed booting into Tessera in BIOS and UEFI QEMU/KVM.
It is a disposable live environment, not an installer or a hardware-certified release.

Text input currently requires a physical keyboard. New ordinary windows maximize
in Phone/Tablet modes and start tiled in Desktop mode. Existing windows stay in
place when switching modes; restoring a maximized app returns to ordinary tiling.
Continuous mobile window policy and tablet split layouts are planned. Exclusive
fullscreen can hide the dock. There is no secure lock screen or on-screen
keyboard integration yet. See the [validation record](docs/testing.md) for the
difference between implemented, user-tested, and planned behavior.

## Quick start: use the basic Arch VM

The basic Arch qcow2 is now the preferred development route. The user has
confirmed that the basic Arch image boots and Tessera runs in that guest.
Detailed touch/device acceptance testing remains pending. The separate tester
ISO has a BIOS/UEFI graphical boot smoke test; see the release validation notes.

Shut down the current guest with `sudo poweroff`. From the host repository:

```bash
./scripts/run-basic-vm.sh
```

This uses `vm/Arch-Linux-x86_64-basic.qcow2`, preserves the separate blank disk,
and exports a fresh read-only snapshot of the project on each launch. Stop the
previous VM before launching the same disk again. KVM is used when accessible;
TCG is the slow fallback. Defaults are 2GiB RAM and 2 vCPUs.

Log into the guest as `arch` (initial password `arch`). **Inside the guest**:

```bash
sudo pacman -Syu --needed hyprland quickshell firefox foot mesa qt6-declarative qt6-wayland ttf-dejavu python grim libnotify
sudo poweroff
```

Restart on the host with `./scripts/run-basic-vm.sh` (or
`VM_SSH_PORT=2222 ./scripts/run-basic-vm.sh` when using SSH), then log back in.
This ensures updated kernel modules match the running guest kernel. Continue
inside the guest:

```bash
sudo modprobe 9pnet_virtio
sudo modprobe 9p
sudo mkdir -p /mnt/tessarchy
sudo mount -t 9p -o trans=virtio,version=9p2000.L,ro tessarchy /mnt/tessarchy
cp -r /mnt/tessarchy/tessarchy ~/
cd ~/tessarchy
./scripts/setup-guest.sh --autostart
~/.local/bin/start-tessarchy
```

The pacman command explicitly updates the **guest** and installs dependencies.
Do not run it on the host for this workflow. The copy command assumes a new
`~/tessarchy` guest directory; preserve any existing guest work first. Setup
refuses Omarchy/the host, checks dependencies and syntax, then installs a
namespaced user copy. Nothing is installed automatically on the host.

With `--autostart`, Tessarchy starts after normal login on tty1 (no autologin).
Existing `.bash_profile` content is retained and backed up; ending Tessarchy
returns to the prompt. Omit the flag for manual startup. To undo the login hook:

```bash
./scripts/login-session.sh disable
```

The hook does not affect other TTYs. Initial text input needs a physical keyboard.
The virtual USB tablet is an absolute mouse, not a multitouch touchscreen.
See [VM setup](docs/vm.md) for recovery and the alternative stock-ISO route.

## Development install in an Arch guest

Dependencies are **a separate explicit opt-in step**, never installed by scripts:

```bash
sudo pacman -S --needed hyprland quickshell firefox foot mesa qt6-declarative qt6-wayland ttf-dejavu grim libnotify
./scripts/check.sh
./scripts/install-dev.sh
```

Assumptions: x86_64 Arch, Hyprland **0.56.x** Lua API and Quickshell **0.3.1**.
Newer versions require revalidation. Bash, Python 3, coreutils, D-Bus and Qt 6
are required. Optional integration: xdg-desktop-portal-hyprland,
xdg-desktop-portal-gtk, PipeWire, WirePlumber and XWayland. Dependencies must
match a consistent Arch system; scripts never upgrade the host.

Log out of other graphical sessions, switch to a **local TTY**, log in as the
development user, then:

```bash
~/.local/bin/start-tessarchy
```

Defaults are copied under `$XDG_DATA_HOME/tessarchy` (normally
`~/.local/share/tessarchy`); launchers go in `~/.local/bin`. Existing paths are
refused. Existing Hyprland/Quickshell/Omarchy configs are untouched. User
preferences live separately in `~/.config/tessarchy/preferences.lua`; see
`session/preferences.example.lua`. Dev installation does not register with a
display manager. Reloaded defaults require uninstall/reinstall; preserve any
custom source changes in the repository.

```bash
./scripts/login-session.sh disable  # if enabled
./scripts/uninstall-dev.sh
```

Uninstall preserves preferences and unknown extra files, and refuses to delete
modified launchers. Keep the source version used to install for uninstalling.

## Start the ISO work

On a normal Arch terminal with administrator access and internet:

```bash
sudo pacman -S --needed archiso
./scripts/stage-iso.sh
./scripts/build-iso.sh
./scripts/vm.sh run dist/tessarchy-0.1.0-YYYYMMDD-x86_64.iso
```

Use the actual ISO filename in `dist/`. Staging is unprivileged; building uses
sudo for `mkarchiso`, downloads signed repository packages, and creates mounts
in its work directory. Read [ISO design](docs/iso.md) before building. This
is a live development image, not an installer or supported distribution.

## Packaging and layout

`./scripts/package.sh` builds two local packages using makepkg without installing
them or resolving missing dependencies. These copy-only recipes use makepkg
`--nodeps` so both can be built before either is installed; dependency checks
still happen when pacman installs them. Build prerequisites: `base-devel` and
`pacman-contrib` if needed by your Arch tooling. Then explicitly install **both**
packages with `sudo pacman -U dist/tessera-shell-*.pkg.tar.zst dist/tessarchy-session-*.pkg.tar.zst`.
Remove with `sudo pacman -R tessarchy-session tessera-shell`. Remove a dev copy
first to avoid taking precedence over system packages. Local source archives
use `SKIP` checksums; release packaging and version pinning are future work.

- `shell/`: Tessera QML; `session/`: launcher, Lua config and desktop entry.
- `scripts/`: local install, checks, packaging, VM and ISO tools.
- `packaging/`: Arch recipes; `iso/`: package additions and live overlay.
- `tests/`: safety/integration checks; `assets/`: asset provenance.
- `docs/`: architecture, VM, ISO, roadmap and manual test checklist.

See [testing status](docs/testing.md) for what was actually checked.
