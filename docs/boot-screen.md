# Quiet Edge power-on screen

Tessarchy's startup sequence uses a navy Plymouth screen, the official mint mark
turning through 64 frames, and a clean transition to the phone PIN greeter.
Animation runs at 20 frames per second. The theme adapts to the boot display size.

## Startup path

1. GRUB selects the normal boot entry with a hidden one-second menu.
2. Early virtio GPU support provides the VM framebuffer.
3. Plymouth displays the animated Tessarchy mark during system startup.
4. The retained splash hands off to greetd on the same graphical VT.
5. Session and compositor output goes to the journal instead of the display.

The greeter supplies a system `PATH` because profile loading is disabled. This
lets Hyprland find its installed dialog utilities during startup. The default
compositor slogan is disabled in both session configurations.

The theme includes graphical password and question prompts. Normal service text
stays in logs. Console recovery remains available through the other VTs.

## Source and packaging

- `session/boot/`: Plymouth script, theme descriptor, daemon config and retained-splash unit override.
- `scripts/export-boot-assets.py`: renders the canonical SVG using the shared logo turntable implementation.
- `packaging/tessarchy-bootsplash/PKGBUILD`: builds the theme package.
- `scripts/configure-vm-boot.py`: plans or applies the QEMU/KVM boot configuration.
- `session/start-tessarchy`: journals compositor/session output.
- `session/greetd/`: coordinated VT and journal routing for the greeter.

Build assets into a new directory:

```bash
python3 scripts/export-boot-assets.py --output build/boot-theme-review
python3 scripts/configure-vm-boot.py
```

`scripts/package.sh` builds the optional bootsplash package alongside the shell,
session and greeter. Its build tools are Pillow and librsvg; runtime uses Plymouth
and DejaVu fonts. Installation and boot activation are explicit operations.

## VM activation

After the packages and generated theme are installed in the VM:

```bash
sudo python3 scripts/configure-vm-boot.py --apply
```

The helper verifies the VM and expected boot layout, refuses unrelated managed
files, saves the previous initramfs/GRUB configuration, adds namespaced drop-ins,
rebuilds the initramfs, validates the generated GRUB file and installs it atomically.
It preserves kernel arguments and removes only normal loader progress messages.
The selected VM mode is 400x800 on the virtual output.

Boot backups are under `/var/lib/tessarchy/boot-backups/`. Reapply after changing
the kernel or bootloader configuration to regenerate the managed boot files.

## Inspection

```bash
systemctl --failed
journalctl -b -t tessarchy-session
journalctl -b -t tessarchy-greeter
journalctl -b -u greetd
```

The initial audit found no failed services. A previous Xwayland abort coincided
with a manual greetd restart; no later instance was present in the core list.
The VM also reported a missing regulatory database. Current VM test results and
screenshots are recorded in [testing.md](testing.md).

## References

- [Arch Plymouth integration](https://wiki.archlinux.org/title/Plymouth)
- [Arch silent boot controls](https://wiki.archlinux.org/title/Silent_boot)
- [greetd terminal configuration](https://man.archlinux.org/man/greetd.5.en)

## Share the startup

- [Actual VM startup MP4](https://github.com/thediamondsaint/tessarchy/releases/download/brand-kit-20261017/Tessarchy-Boot-Preview.mp4): 400x800, 35 seconds.
- [Discord-ready startup GIF](https://github.com/thediamondsaint/tessarchy/releases/download/brand-kit-20261017/Tessarchy-Boot-Preview.gif): 320x640, 14.6 seconds.

The MP4 starts when Plymouth appears and continues through the PIN screen. The
GIF shortens the idle transition. Both use actual VM frames. Firmware and GRUB
run before this excerpt; their remaining text is tracked separately from Linux
service output. Capture provenance is in assets/boot/.
