# Build 7 (Bluetooth merge) boot evidence, 2026-10-18 UTC

ISO: `dist/tessarchy-0.1.0-20261018-x86_64.iso`, 1,088,454,656 bytes, SHA-256
`2e93e66da19542249dd212896f41cbdb2edb7ebcdff25fc6beeaa594ff2b1df4`, built from
integration `83e2838` (Bluetooth quick controls merged on top of the build 6
tree). The image intentionally ships without BlueZ; the squashfs contains
`usr/share/tessarchy/shell/components/BluetoothPanel.qml`.

- `bios-1200s-final.png` — BIOS/SeaBIOS boot, TCG, 1200 s window. Full shell;
  status bar Bluetooth icon slashed and dimmed (no adapter, by design).
- `uefi-1800s-final.png` — UEFI boot, TCG, 1800 s window. Full shell with the
  same slashed icon. The first 1200 s attempt of the same ISO did not reach
  the shell (guest still on `Wait Until Kernel Time Synchronized`; diskless
  VM, no NIC, TCG boot) and is not counted as a pass.
- `diagnostic-iso-rendered-shell.png` and `diagnostic-serial-shell-lines.txt`
  — a diagnostic variant of the same ISO with journald forwarded to the
  serial console and the shell started through `logger -t tessera-shell`.
  The serial log shows `INFO: Configuration Loaded` with no QML errors; the
  only Bluetooth-related line is the expected
  `WARN quickshell.dbus.objectmanager: Failed to create DBusObjectManagerInterface for "org.bluez"`
  because BlueZ is absent, which the shell handles by showing the
  no-adapter state instead of failing.

Not performed: pairing, adapter toggling, discovery or battery readings on
hardware; no adapter exists on the image or the development host.
