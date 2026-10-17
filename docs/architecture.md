# Architecture and API evidence

Tessarchy is an Arch session, not Android/AOSP. Tessera runs as a normal user
under Hyprland, using Quickshell's layer-shell panels and window integration.
No privileged daemon or compositor fork is involved.

A per-output status bar reserves 48 logical pixels. Navigation reserves 72 in
Phone mode and 80 in Tablet/Desktop. Phone navigation spans the output;
Tablet/Desktop use centered, rounded panels bounded to 720/760 pixels. Launcher
columns and panel height follow available space, including manual modes on small
screens. Settings is loaded only when opened. Panels never acquire application
keyboard focus; buttons and sliders use NoFocus. No keyboard search or outside
click dismissal is implemented.

`LayoutPolicy.js` classifies logical screen geometry: a shortest edge below 600
is Phone; otherwise a landscape width >=1100 and height >=650 is Desktop;
remaining sizes are Tablet. This is a display-size heuristic, not physical device
or input-hardware identification. Automatic mode is evaluated per output whenever
geometry changes; an explicit override applies across outputs. The override and
appearance preferences persist through QtCore Settings in
`$XDG_CONFIG_HOME/tessarchy/shell.ini` (default `~/.config/tessarchy/shell.ini`).
Dev uninstall preserves this user-owned file.

Hyprland.toplevels supplies window identity/title/state; each `.wayland` handle
provides activate(), close() and writable maximized. Close confirmation retains
the selected object rather than whichever window later becomes active. Closed
handles clear the confirmation. Windows lacking a handle have disabled actions.
These requests can be ignored by a compositor/application and need manual tests.
Only fixed `hl.dsp.exit()` goes through Hyprland.dispatch. No application title
is interpolated into IPC or a shell command. App launch uses
Quickshell.execDetached([executable]) per action, so no shared Process can drop
rapid clicks. Startup executables in the Lua config are fixed strings.

Screenshots run through the shipped `tessera-screenshot` helper: Quick controls
and the Print key both exec it by name (tessera-shell keeps the install
directory on PATH). The helper refuses to run without grim, generates the
output name itself inside `Pictures/Screenshots` (or `XDG_PICTURES_DIR`), never
accepts a caller-supplied path, and sends a plain-text confirmation through the
notification service, if installed. No user or application text reaches the
command line.

Screen rotation uses Hyprland's runtime monitor keyword, not a dispatcher (the
Lua dispatcher set in 0.56 has no keyword/monitor transform dispatch).
`RotationControl.qml` reads the focused monitor's current transform from
`lastIpcObject` and calls fixed-argv
`Quickshell.execDetached(["hyprctl", "keyword", "monitor", name + ",transform," + n])`;
the monitor name comes from the compositor and `n` from `Policy.nextTransform`
(`(current + 1) % 4`). No user-supplied text reaches the command. After a 300 ms
timer the shell calls `Hyprland.refreshMonitors()` so the label reflects the new
orientation. Layout mode already treats rotated geometry through the same
size heuristic, so Phone/Tablet/Desktop re-evaluate after rotation.

The Lua `window.open` handler reads the saved mode for each new ordinary window.
It uses the same size thresholds, accounting for monitor scale/rotation. Mobile
modes request maximization; Desktop leaves ordinary dwindle tiling. Floating
windows and windows already fullscreen are left alone. A mode switch does not
rearrange existing windows. Tablet split layouts and continuous mobile window
policy remain future work. Multi-output navigation lists global windows;
per-output geometry is used for automatic mode and each new window's monitor.

Desktop mode extends the same shell with standard desktop affordances rather
than a second configuration. The status bar shows numbered workspace slots
(1-5, extended by higher existing ids) unless the output is too narrow; a tap
activates the workspace. Named workspaces have negative ids and get no slot.
When a workspace exists, `HyprlandWorkspace.activate()` is used because it
correctly emits Lua or classic dispatchers depending on `Hyprland.usingLua`;
for a not-yet-created workspace the shell dispatches a fixed
`hl.dsp.focus({ workspace = <n> })` expression containing only a number. The
focused window title sits next to the tray and is display-only; no title text
reaches IPC or shells. The Lua config adds fixed keybindings
(Super+1-5, Super+Shift+1-5, Super+Q, Super+Tab, directional focus/move,
Super+left-drag/resize, and XF86Audio* volume keys). All are fixed strings and
safe in every layout mode; volume keys require wpctl at press time.

The original T logo is built from six SVG faces. BrandMark animates assembly and
rotation once, settles after 1.6 seconds, and supports tap/replay and reduced
motion. It has no idle animation loop. The clock updates once per minute; mode
selection is reactive, with no polling. Optional PipeWire integration is loaded
only when the service socket exists at launch; its quick-controls panel
switches the default output via `Pipewire.preferredDefaultAudioSink`, controls
the default sink's volume and mute, and lists playback streams with per-app
volume and mute, keeping every displayed node alive with `PwObjectTracker`.
The power panel reads UPower's
display device reactively (percentage, charge state, time to empty/full, health
when reported) and sets the power-profiles-daemon profile, disabling the
performance button when the daemon reports no such profile.
Brightness control probes the first backlight once at shell start (nothing is
shown without one), writes through `session/tessera-brightness` (brightnessctl
when present, else sysfs) with rapid changes coalesced into one call, and the
brightness keys invoke the same helper, which is silent on machines with no
backlight. The night-light toggle starts and stops hyprsunset through
`session/tessera-nightlight` (pid file in the runtime directory, fixed 4000K
command), hidden when hyprsunset is missing, and re-applied from the stored
preference on shell start. Screen idle behavior is owned by
hypridle, started from the session's `hyprland.start` hook with Tessarchy's own
config: after 300 seconds without input it runs `hyprctl dispatch dpms off`,
and the next input brings the panel back. It honors idle inhibitors, configures
no lock command.

Wi-Fi uses Quickshell's Networking service (NetworkManager over D-Bus), loaded
only when a NetworkManager backend is present; with none, the panel says so and
no Wi-Fi control is offered. The status bar's Wi-Fi icon binds
`Networking.wifiEnabled`/the connected network's `signalStrength` through the
same `StatusIcon.available` state that says "disconnected" rather than
"unavailable". The panel enables the device scanner only while it is visible,
sorts connected-then-strongest, and decides taps with `Policy.wifiAction`:
connected networks disconnect, saved or open networks connect, anything else
stays disabled with an explanatory label. No password is ever passed: new
secured networks need a saved profile (nmcli) until the on-screen keyboard
lands. Only monitor-backed displays are trusted for labels; nothing device- or
network-supplied reaches a command or path. Cellular modem control and secure
locking are not claimed.

## Notification delivery

Tessera registers Quickshell's `NotificationServer`, which claims
`org.freedesktop.Notifications` on the session bus, so ordinary D-Bus
notifications reach the shell without any extra daemon. Every delivered
notification is marked tracked, which is the history model the alert center
lists; `dismiss()` removes an item from both pop-ups and history, and an
application withdrawing a notification does the same. The server advertises
only what the card renders: a plain-text body. Markup, hyperlinks, inline
images, actions and persistence are explicitly disabled rather than advertised
and ignored. Notification text is untrusted input and is only ever displayed
as plain text; no body content reaches IPC, a command line or a filename.

Pop-ups are views over at most the three newest tracked items and render once,
on the first screen. Phones show full-width cards below the status bar;
tablet/desktop right-align a column of at most 360/420 logical pixels. Tapping
a pop-up hides it but keeps it in the center; the close button dismisses it
everywhere. Low-urgency pop-ups leave after 4 seconds, normal after 8, and
critical ones stay until acted on. The "pop-ups muted" preference persists in
`shell.ini`; muted notifications still collect in the center. Nothing is
persisted across sessions, and no notification history is written to disk.

## Verified against installed files, 2026-10-16

- Hyprland 0.56.2: `/usr/share/hypr/hyprland.lua`,
  `/usr/share/hypr/stubs/hl.meta.lua`, and `Hyprland --verify-config`.
- Quickshell 0.3.1: installed QML metadata under `/usr/lib/qt6/qml/Quickshell/`,
  especially Hyprland/_Ipc, Wayland/_ToplevelManagement and _WlrLayerShell;
  `qs --help` confirms path selection and duplicate protection.
- [Quickshell Toplevel API](https://quickshell.org/docs/types/Quickshell.Wayland/Toplevel/)
  documents activation, close and maximize as compositor requests.
- [Quickshell Hyprland workspace API](https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/HyprlandWorkspace/)
  documents `workspaces`, `focused`/`active`, `toplevels` and `activate()`.
- Hyprland 0.56 source (`LuaBindingsDispatchers.cpp`, `LuaBindingsToplevel.cpp`)
  confirms `hl.dsp.focus`, `window.move/close/cycle_next/drag/resize` and bind
  flags `mouse`/`locked`/`repeating`.
- [Hyprland window rules](https://wiki.hypr.land/configuring/core/rules/window-rules/)
  documents the Lua maximize rule.
- [Official archiso profile specification](https://github.com/archlinux/archiso/blob/master/docs/README.profile.rst)
  and [releng profile](https://github.com/archlinux/archiso/blob/master/configs/releng/profiledef.sh)
  inform the overlay; installed archiso supplies the actual bootloader files.
- Quickshell 0.3.1 notification service source (`NotificationServer`,
  `Notification`): `tracked` keeps an item in `trackedNotifications`, and
  `dismiss()`/`expire()` remove it from the model via `deleteNotification`.
  The capability properties are honored exactly; unsupported features are
  advertised as false rather than silently dropped.

No overlays claim secure locking. No lock button is included. A complete input
method integration needs research into Hyprland's input-method-v2/text-input-v3,
client toolkit support, focus behavior and whether the chosen keyboard actually
implements the required protocols. Squeekboard/Maliit are not assumed compatible.
