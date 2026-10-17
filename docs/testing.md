# Validation and manual acceptance

## Actually performed, 2026-10-16

Environment: Omarchy/Arch, Hyprland 0.56.2-2, Quickshell 0.3.1-1,
QEMU 11.1.1, Foot 1.28.0. archiso and Firefox were not installed in this session.
The repository was new; no earlier Tessarchy prototype files were found in the
workspace. Existing projects and host session configuration were preserved.

`./scripts/check.sh` passed:

- Bash syntax for scripts, launchers and package recipes.
- Six integration tests: install/uninstall preservation, existing-path refusal,
  modified-launcher refusal, removal-marker/extra-file safety, nested-session
  refusal, and ISO staging against a minimal fixture with boot-asset and
  account-database preservation. This is not an archiso build test.
- Lua syntax and Hyprland's actual `--verify-config` parser: `config ok`.
- Qt qmllint against installed Quickshell metadata: exit 0. It warns that
  PanelWindow is not creatable; Quickshell chooses its backend at runtime, and
  the warning does not demonstrate working rendering. Shellcheck was absent
  and was explicitly skipped.

A sparse 32GiB qcow2 was created and inspected using qemu-img; initially only
about 200KiB was allocated. The launcher printed a TCG VM plan. A headless,
paused QEMU/TCG smoke test with the disk in snapshot mode initialized and stayed
alive for three seconds; then it was terminated. This tests the emulator engine
and disk attachment only, not firmware, boot, graphics, NAT, or the OS.

A Quickshell offscreen attempt failed because no PanelWindow backend exists
without a Wayland/X11 backend. The session also restricts local IPC sockets.
It is **not** a GUI pass. The installed host desktop was not altered or used
to run the prototype. Outbound download DNS is blocked here; /dev/kvm is not
exposed and privilege escalation is unavailable. Real ISO staging stops with
an explicit missing-archiso diagnostic. No Arch guest or Tessarchy ISO boot was
performed. Both local Arch packages were subsequently built successfully with
`./scripts/package.sh`; package metadata and file lists were inspected. They
have not been installed or runtime-tested. No built ISO is claimed.

## Manual checklist (detailed acceptance pending)

Record guest package versions, output mode/scale, input device, and logs. Treat
any failure below as a blocker for claiming the first session milestone works.

- [ ] Boot a stock Arch VM and install the documented dependencies explicitly.
- [ ] Install the dev copy as a normal user; confirm existing host/guest configs survive.
- [ ] Launch from a local TTY; verify no Hyprland configuration error banner.
- [ ] At 320×480 and 360×640 logical portrait sizes: all three dock buttons fit,
      labels remain usable, drawer scrolls, all controls are at least 48px, and
      close confirmation remains reachable. Test touch scrolling on hardware.
- [ ] At 800×1280 and 1280×800 tablet sizes: panels fit without excessive stretching,
      no unexpected tiling/split claims, dialogs and app minimum sizes are usable.
- [ ] Repeat at 1×, 1.5× and 2× scale, including output resize/rotation.
- [ ] Apps opens Firefox and Foot; rapid separate taps are not silently dropped.
- [ ] New ordinary windows maximize initially; multiple open apps can be switched
      through Windows, including windows on another workspace/output.
- [ ] Maximize and Restore affect exactly the chosen window; the dock stays visible,
      remains 72px reserved, and the label follows actual compositor state.
- [ ] Restore with several windows demonstrates tiling; document any policy gaps.
- [ ] Close asks confirmation, Cancel preserves the window, confirm closes only the
      named window. Unsaved apps may show their own dialog. Test spontaneous
      target exit while confirmation is open; no crash or wrong-window close.
- [ ] With text typed into Foot/Firefox, opening/closing Apps and Windows keeps
      keyboard focus in the app. Explicitly selecting another window changes focus.
- [ ] No hover is required. Test actual touchscreen input separately from the VM
      absolute pointer; trackpad gesture behavior is not a touchscreen test.
- [ ] Exclusive fullscreen behavior is recorded: dock may be hidden. App controls
      must provide a touch exit or keyboard recovery is required. No universal
      touch-only escape from exclusive fullscreen is implemented in milestone 1.
- [ ] Session → Cancel preserves session; Session → End returns to TTY; restarting
      works. Recovery shortcuts and alternative TTY work through QEMU Send Key.
- [ ] Uninstall preserves preferences/other configs; install again successfully.
- [ ] Build local packages and explicitly install/remove them in the guest.
- [ ] Stage with actual archiso, review profile, build, record output/hash and log.
- [ ] Boot Tessarchy ISO in BIOS and OVMF modes; test user creation, autologin,
      ownership, non-root rendering, apps, networking, audio and session exit.
- [ ] Confirm root rescue behavior, disabled SSH, no accidental sudo grant, and
      lack of persistence; review services/sockets before distributing an image.

Secure locking and on-screen typing are not implemented and cannot be marked
passed. First-milestone touch accessibility is limited to shell navigation with
maximized apps; application UI and exclusive fullscreen escape remain constraints.

## Basic guest conversion workflow, 2026-10-16

The user reports that the official Basic image boots. This is user-reported
Arch boot success, not an agent-observed Tessera GUI pass. Added a launcher for
that existing image, fresh read-only source sharing, guest-only setup, and a
reversible tty1 login hook. All nine workflow tests pass, including a QEMU stub
that checks disk selection/share contents and preserves the guest image, plus
login-hook roundtrip, idempotence and modified/symlinked profile refusal.
The real launcher command was inspected using `run-basic-vm.sh plan`.
Hyprland config parsing and QML static checks still pass (same known tooling
warning); shellcheck remains unavailable. The actual guest has not been changed
by the agent. Dependency installation, Tessera graphics, tty1 login startup and
VM graphics compatibility still require running the documented guest commands.

## First graphical smoke test, 2026-10-16

The user confirms Tessera runs in the Basic Arch QEMU guest and its dock is
visible and working. This is a user-reported graphical smoke test; the agent
has not observed the guest screen. Exact guest package versions and detailed
results for switching/maximize/close/focus/scaling were not captured. The full
manual checklist remains pending; actual touch hardware and ISO boots remain
untested. Before the initial Git commit, all nine workflow tests and available
static checks passed again, with the previously documented qmllint warning and
shellcheck skip. Generated VM images, downloaded data, packages and build output
are excluded from Git.

## Phone shell and SSH guest validation, 2026-10-16

Actually performed by the agent on the existing Basic Arch qcow2 through SSH
on host loopback port 2222. The VM runs with KVM, 2GiB RAM, Hyprland 0.56.2-4
and Quickshell 0.3.2-1. Guest source and installed defaults were archived under
`~/tessarchy-backups/` before updating; the host desktop configuration was not
modified. No dependencies were installed.

- `./scripts/check.sh` passed on host and guest: nine workflow tests (including
  scratch-HOME install/uninstall), Lua parsing, Hyprland `--verify-config` and
  QML checks. Shellcheck is unavailable. qmllint retains its PanelWindow backend
  warning; an additional guest type-inference warning was resolved by using the
  screen model directly. Installed host/guest QML metadata was inspected.
- Guest `hyprctl reload` succeeds and `hyprctl configerrors` is empty.
- The agent inspected guest screenshots at 664×480 landscape and 432×768 logical
  portrait (1920×1080 output, transform 1, scale 2.5). Status and bottom navigation
  reserve 48 and 72 logical pixels respectively. The final app tiles and dialogs
  were inspected in portrait.
- Injected pointer clicks through a temporary guest-only uinput device: Home
  opens the launcher, Terminal launches Foot, and Recents shows the window.
  Foot is maximized at position (0,48), size 432×648, between both bars. Opening
  Recents keeps Foot as the active keyboard window. Close opens confirmation;
  Cancel preserves Foot. The top power control opens session confirmation.
- The gradient background, date/time, navigation icon alignment, launcher, recent
  apps, and confirmation screens were visually inspected. Evidence is local in
  ignored `build/phone-*.png`; no VM image or credentials are tracked.
- The guest lacks UPower and desktop portals. Battery status shows an unavailable
  indicator rather than an invented charge value. Live tray registration, tray
  menus, battery changes, browser launch, actual touch, and session exit have not
  been tested in this pass. The VM remains running.

ISO/publishing result: pushing the existing `build/live-iso` branch was rejected
by GitHub because the current OAuth login lacks the `workflow` scope. The workflow
dispatch consequently returned 404. `archiso` is absent locally, local Docker
access requires administrator authentication, and no build has run. No Tessarchy
ISO artifact or ISO boot success is claimed. Grant the GitHub workflow scope,
push the branch, and dispatch `.github/workflows/build-iso.yml` to continue.

Remaining manual checks: destructive close/session exit, multiple windows,
restore/resize, 320×480 and tablet layouts, hardware touch and battery, tray menus,
ISO build and BIOS/UEFI ISO boots. Back dismisses shell panels; it does not inject
a browser/application Back key. Home opens the app launcher above running apps.

## QEMU orientation correction, 2026-10-16

The user reported that the rotated phone display appeared sideways in QEMU.
The earlier screenshot validated the compositor rendering, not the viewer's
orientation. Over SSH, backed up the guest preference and set Virtual-1 to
1280×960@60, scale 2, transform 0. Reload succeeded; `hyprctl configerrors` is
empty, and monitor state confirms transform 0 and 640×480 logical dimensions.
The updated compositor screenshot is `build/phone-upright.png`. User confirmation
of the viewer presentation is still pending. Host desktop configuration is unchanged.

## Native phone view, artwork, and status controls, 2026-10-16

Actually performed:

- Backed up guest source, installed shell, and Tessarchy preferences under
  `~/tessarchy-backups/` before deployment. No dependencies were installed.
- Selected a native 400×800@60 mode at scale 1, transform 0, over guest SSH.
  `hyprctl reload` succeeded and `configerrors` is empty; actual monitor state
  confirms 400×800 with 48px status and 72px navigation reservations.
- Made only the host's `QEMU (Tessarchy)` client float, then resized it to
  350×700. No host compositor configuration was edited. Inspected the viewer
  at its intermediate 390×700 size and final 350×700 size with the menu hidden:
  the full upright phone content fits without clipping or letterboxing.
- Generated and deployed an original wallpaper and editable SVG Tessarchy logo.
  Inspected guest screenshots showing both, translucent status/navigation bars,
  wireless/cellular unavailable indicators, volume and battery symbols.
- Clicked Home/Back with guest uinput and inspected the final launcher and
  wallpaper. Clicked the speaker and inspected Quick Controls: Wi-Fi
  unavailable, no modem, no audio output; sound buttons are disabled. The guest
  has no PipeWire service. Optional audio code loads only when its socket exists.
- Host checks pass: nine workflow tests including scratch-HOME installation and
  complete removal of the new artwork/components, Hyprland config verification,
  Lua and QML checks. qmllint retains the known PanelWindow warning; shellcheck
  remains unavailable. The final guest run of the same checks also passes.

During restart, Quickshell 0.3.2 aborted (guest PID 1131). `coredumpctl info`
shows SIGABRT in Qt's `QWindow::unsetCursor`/QQuickItem destruction path. Guest
memory remained available and no OOM kill was shown. This supports a Qt/window
teardown problem during restart; the exact upstream cause is unresolved.
Quickshell's crash handler restarted the shell and opened a crash dialog. The
old handler/dialog were stopped and the final configuration started cleanly.
PipeWire separately reported missing context configuration before the optional
backend guard was added; the core does not establish it as the crash cause.
No core dump or crash memory was copied into the repository.

Evidence: ignored `build/phone-branded.png`, `build/phone-controls.png`, and
`build/vm-phone-window-final.png`. Live Wi-Fi/cellular backends, real audio adjustment,
battery changes, hardware touch, and ISO builds/boots remain untested.

## Adaptive layouts, Settings, and logo animation, 2026-10-16

Actually performed:

- Archived guest source, installed defaults and preferences under
  `~/tessarchy-backups/` before updating. Host compositor configuration was not
  changed, and no dependencies were installed.
- `./scripts/check.sh` passes on host and guest: ten workflow tests and fifteen
  Qt Quick Test results (including fixture setup/cleanup). Tests cover auto-mode
  thresholds, portrait/landscape geometry, narrow manual override, Lua app policy
  with scaling/rotation and saved overrides, preservation of floating/fullscreen
  windows, finite logo playback, reduced-motion cancellation, and scratch-HOME
  install/uninstall preserving shell preferences and removing new assets.
  Hyprland verification returns `config ok`; QML checks retain only the known
  PanelWindow backend warning. Shellcheck remains unavailable.
- Resized the running guest to 400×800 Phone, 800×1280 Tablet, 1280×800 Desktop,
  and 320×480 Phone. Inspected Settings, header mode labels, adaptive navigation,
  launcher columns, scrollable controls, and a Desktop override at phone size.
  The final launcher uses row-based height rather than a mostly empty drawer.
- Used guest uinput to select Desktop/Automatic and Iris appearance. The actual
  `shell.ini` changed and the mode/accent loaded again after restarting Tessera.
  Inspected the longer Settings page after scrolling, including appearance,
  branded sliders, clock, labels, and motion controls.
- Guest `hyprctl reload` succeeds and `configerrors` is empty with the new Lua
  window-open policy. A temporary Foot test at 400×800 opens maximized at
  (0,48), size 400×680, fullscreen flag 1. Two temporary Foot windows opened
  at 1280×800 start tiled at (0,48) and (640,48), each 640×672, fullscreen
  flag 0. The test apps run `sleep` and exit naturally, with no user work in them.
- Rendered the actual BrandMark QML component offscreen into animation frames;
  inspected intermediate and final frames and produced the local preview
  `build/tessarchy-logo-animation.gif`. This is the component's animation, not
  a generated mockup. It assembles six original faces with rotation, runs once
  for 1.6 seconds, and settles. Qt tests verify no idle loop and reduced motion.

## Bundled fish live shell, 2026-10-17

Actually performed:

- Added `fish` to `iso/packages.x86_64`, changed the sysusers shell for `tess`
  to `/usr/bin/fish`, and gave the skel tree a fish profile: greeting off, two
  abbreviations, and the same gated tty1 one-shot Tessera start as
  `.bash_profile` (interactive only, tty1 only, no DISPLAY/WAYLAND_DISPLAY).
- `scripts/stage-iso.sh` now copies the whole skel tree to `/home/tess` and
  records `file_permissions` for the fish config; tmpfiles keeps the `.config`
  directories owned by `tess`.
- `fish -n` accepts the profile on the development host; `scripts/check.sh`
  now runs that syntax check whenever fish is installed.
- The ISO staging workflow test asserts fish in the package list, the fish
  login shell, the staged profile path, and the profiledef permission entry;
  all ten workflow tests pass on the development host.
- Not performed: building and booting the live image, verifying autologin
  lands in fish, or ending a session and returning to the fish prompt. Those
  remain part of the pending ISO boot checklist.

Screenshots are ignored under `build/`, including adaptive/tablet/desktop and
Settings captures. Hardware touch, real Wi-Fi/modem/audio/battery integration,
multiple physical outputs, exhaustive fractional scaling, and ISO builds/boots
remain pending. Auto detection classifies logical display size; it does not
identify physical device type or available input hardware. No secure lock claim.

## Desktop mode workspace strip and keybindings, 2026-10-17

Implemented, static validation only; GUI and guest acceptance pending.

- `LayoutPolicy.js` gains `showWorkspaces(mode, width)` and
  `workspaceSlots(ids)`; `tests/qml/tst_layout.qml` covers placement at
  desktop/tablet/phone widths and slot extension beyond five workspaces.
- The status bar renders numbered workspace buttons from
  `Hyprland.workspaces`, highlights the focused/active workspace, and falls
  back to a numeric-only `hl.dsp.focus` dispatch for not-yet-created
  workspaces. Existing workspaces use `HyprlandWorkspace.activate()`.
- Desktop shows the focused window title beside the tray (display-only text).
- `session/hyprland.lua` adds fixed desktop bindings: Super+1-5,
  Super+Shift+1-5, Super+Q, Super+Tab, directional focus and window move,
  Super+drag/resize, and XF86Audio volume keys.
- Performed on the development host (Ubuntu ARM, no Wayland session):
  `luac -p` accepts the Lua config; `qmllint` (Qt 6.10) exits 0 for edited QML
  with only unresolved-module warnings; the Qt Quick Test suite was run
  directly against the multiarch Qt install and reports 17 passed, including
  the new `test_workspace_slots` and `test_workspace_strip_placements`.
  `scripts/check.sh` passes ten workflow tests with the documented skips
  (Hyprland and Quickshell absent).
- Not performed here: `Hyprland --verify-config`, Quickshell rendering,
  workspace strip taps, keybinding behavior, multi-output focus, or reduced
  width clipping. These require the Arch guest and remain on the manual list.

## Live rootfs hardening, 2026-10-17

Actually performed:

- Staged profile now pins hostname `tessarchy`, en_US.UTF-8 generation, a plain
  `us` virtual console, a live-console motd, a volatile journald drop-in
  (64M runtime cap), a `systemd-timesyncd` enablement link, and a `docs/`
  snapshot under `/usr/share/tessarchy/docs`; `noto-fonts-emoji` joined the
  package list.
- The ISO staging workflow test asserts each of those artifacts in the staged
  profile, and `./scripts/check.sh` passes on the development host.
- Not performed: building the image and reviewing the live console; autologin,
  motd rendering and the volatile journal still need a real ISO boot.

## Portable checks and a source-checks workflow, 2026-10-17

Actually performed:

- `scripts/check.sh` no longer assumes Arch paths: it accepts `python` or
  `python3`, `luac` or `luac5.4`, and discovers Qt tools and the QML import
  root under both `/usr/lib/qt6` and multiarch libdirs. `qmllint` now runs
  whenever it is installed instead of additionally requiring Quickshell.
- On this Ubuntu ARM host the full pass now executes: ten workflow tests, the
  seventeen-result Qt Quick Test run, `luac -p`, `qmllint` (warnings only) and
  `shellcheck`; only the Hyprland parser check skips.
- Added `.github/workflows/checks.yml` running the same script on
  ubuntu-24.04 with python3, lua5.4, fish, shellcheck and the Qt QML modules.
- Not performed: observing the new workflow run on GitHub, and the pre-existing
  `qs`-gated behavior change on a host with Quickshell installed.
## Notification center and pop-ups, 2026-10-17

Implemented, static validation only; live-session acceptance pending.

- `Quickshell.Services.Notifications` (verified in Quickshell 0.3.1 source):
  the shell registers `NotificationServer` on `org.freedesktop.Notifications`.
  Delivered items are marked `tracked` and listed in the alert center until
  `dismiss()`ed; capability flags advertise only plain-body support.
- `NotificationCard.qml` and `NotificationCenter.qml` render app name, summary,
  body (three lines max, elided) and an IMPORTANT tag for critical urgency;
  every interactive control is a TouchButton with at least 48 logical pixels.
  Pop-ups hide on tap, dismiss via the close button, and expire after 4s/8s
  for low/normal urgency (critical stays until dismissed). The "pop-ups muted"
  toggle persists in `shell.ini` and is also offered in Settings.
- `LayoutPolicy.notificationPlacement/timeout` were unit-tested: the Qt Quick
  suite reports 17 passed including the two new notification cases.
- `uninstall-dev.sh` no longer hardcodes the shell file list; it mirrors the
  repository tree so new shell files (such as these components) cannot leave
  stray files behind. The install/uninstall workflow test asserts the new
  component and icon are removed; 10/10 workflow tests pass.
- Not performed: running the shell against a live session bus, delivering a
  real `notify-send`, tapping cards, pop-up stacking on multiple outputs, and
  DND persistence across a restart. These stay on the manual list.
