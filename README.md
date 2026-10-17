# Live ISO boot evidence, 2026-10-17

Boot validation of the Tessarchy live ISO on this machine (QEMU, software
emulation/TCG; q35, virtio-vga, 2 GB), captured by `scripts/boot-test-iso.py`:
diskless boot, automatic Enter at the boot menu, screenshots at 10/30/60/600
seconds. Each run completed the archiso boot into the Tessera shell.

- `baseline/` — `tessarchy-0.1.0-20261017-x86_64-baseline.iso`, sha256
  `2c753f5d574a10656c047d8992327d3f185243e2dd50eaa5940e77050d608cfd`
  (phone-shell + desktop mode + fish + rootfs hardening + portable checks):
  BIOS (SeaBIOS/isolinux) and UEFI (OVMF 4M, systemd-boot) both render the
  full desktop shell (workspace strip, tray, battery, clock, dock, wallpaper).
- `full/` — `tessarchy-0.1.0-20261017-x86_64.iso`, sha256
  `88a30d4f5105a0862375946060b94538cfdb8c382300e5d4b41dd1a4c613d57e`
  (all feature branches merged: notification center, screenshots, media
  controls, window previews, audio panel, power panel, display controls)
  from integration commit `5d22892`:
  boots to the same full desktop shell on both firmwares. The first build of
  this tree failed to render (an integration-only `shell.qml` brace merged
  badly — caught by this exact test), was fixed, and the rebuilt image is
  the one shown here.
- `*-serial.log` — the guest serial consoles for each run;
  `SHA256SUMS` and `packages.txt` describe the images.

Not covered: hardware boot, guest networking, and interacting with individual
panels in the guest (taps, real notifications). Those remain manual checks.
