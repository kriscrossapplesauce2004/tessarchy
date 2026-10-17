# Build 6 boot failure root cause and fix, 2026-10-17

Builds 4 and 5 (integration with the rotation branch) booted Hyprland but the
shell never rendered: screenshots showed only Hyprland's empty-backdrop text
and a cursor at 600 s. A diagnostic ISO (same root, with journald forwarded
to the kernel serial console via `systemd.journald.forward_to_console=1` and
`console=ttyS0,115200`, plus the autostart line piped through `logger`) showed
the exact failure:

    ERROR: Failed to load configuration
    ERROR:   caused by @shell.qml[282:54]: Type SettingsPage unavailable
    ERROR:   caused by @components/SettingsPage.qml[118:5]: Type RotationControl unavailable
    ERROR:   caused by @components/RotationControl.qml[12:5]: Cannot override FINAL property

`RotationControl.qml` declared `readonly property int transform`, and
`Item.transform` is final in Qt Quick. The failed instantiation propagated up
through `SettingsPage` and aborted the whole `ShellRoot`, so no layer surfaces
existed and Hyprland only painted its backdrop.

Fix (feat/rotation, commit 4c5ace4; integration merge e56572f): rename the
property to `currentTransform` and note the constraint in the file. A grep for
the same class of collision (`transform`, `parent`, `data`, `resources`,
`states`, `transitions` declared as property names) finds no others.

Build 6 was rebuilt from the fixed integration tree. The diagnostic ISO for
build 6 (same serial wiring) then showed:

    INFO: Launching config: "/usr/share/tessarchy/shell/shell.qml"
    INFO: Saving logs to "/run/user/1000/quickshell/by-id/.../log.qslog"
    ERROR quickshell.network: Network will not work. Could not find an available backend.
    INFO: Configuration Loaded

The single remaining ERROR line is expected: the live ISO ships without
NetworkManager, so the Wi-Fi panel shows its explicit no-backend state.

A 1200-second capture of the unmodified build 6 ISO (BIOS, TCG) shows the full
Tessera shell: wallpaper, status bar, workspace strip, mode chip, dock.

Timing note for future boot checks: under TCG on this host the shell can appear
as late as ~600-700 s after power-on; the previous 600 s capture window could
photograph the boot mid-initialization and produce a false negative. Build 6
was verified with a 1200 s window.
