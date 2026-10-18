# Pull-down radio controls

Pull down from the 48px status bar, or tap its clock/volume button, to open the
glass quick-controls sheet. Swipe up on the bar or bottom handle, or tap the
handle/clock, to collapse it. Opening controls dismisses the bottom sheet and
preserves the application's keyboard focus.

The status clock uses compact semibold digits without a leading hour zero or
AM/PM suffix. It follows the saved 12/24-hour choice; its accessible name and
the expanded clock retain AM/PM when appropriate.

The layout selector is in this sheet rather than on the home screen or status
bar. Choose Auto, Phone, Tablet, or Desktop; the active layout is shown above
the buttons. Manual choices persist, and Auto resumes size-based detection.
The same preferences remain available in Settings.

## What the switches control

`RadioBackend.qml` runs the installed Python helper with argument arrays. The
helper reads explicit JSON columns from `rfkill`, then blocks/unblocks Wi-Fi
(`wlan`), Bluetooth, or cellular (`wwan`) transmitters that the kernel exposes.
These are radio power controls, not network selection, Bluetooth pairing, calls,
or mobile-data configuration. Some modem drivers do not expose an rfkill switch;
those devices are not treated as controllable cellular hardware.

Airplane mode blocks all detected rfkill radios. Turning it off unblocks all
software-blocked radios, rather than restoring a previous per-radio selection.
Its displayed on-state requires a nonempty set with every radio software-blocked.
A hardware block remains effective after a software unblock and is shown in the UI.
The switches do not claim to override physical switches or unsupported devices.

No state is changed optimistically. The helper refreshes after each action,
including a failed/partially successful bulk action. A ten-second poll and a
refresh on opening controls pick up external changes. Unavailable devices,
hardware blocks, and missing write permission disable the respective control.
No sudo, dependency installation, or privilege prompt is launched by the shell.
A normal active local session needs access to `/dev/rfkill` through its system's
existing device/session policy. Errors remain visible in the sheet.

Python and util-linux are declared packaging/live-image dependencies. They are
not installed onto the host or guest by development commands. The current QEMU
guest exposes no radio devices, so all four radio controls correctly show
Unavailable. Actual transmitter changes still require hardware validation.
