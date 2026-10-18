# Quiet Edge development captures

Captured directly from the installed Tessarchy QEMU/KVM development guest on
2026-10-17 and 2026-10-18 UTC. These are actual session screenshots, not mockups or captures of the
published Alpha 1 ISO. The ISO predates Quiet Edge and the card switcher.

- `phone-home.png`: automatic Phone mode, 400 × 800 logical pixels.
- `phone-launcher.png`: glass app launcher, 400 × 800.
- `phone-switcher.png`: real window previews and glass icon actions, 400 × 800.
- `phone-settings.png`: saved layout and appearance controls, 400 × 800.
- `phone-controls.png`: pull-down airplane/radio/volume panel and layout selector, 400 × 800.
- `tablet-home.png`: automatic Tablet mode, 800 × 1280.
- `desktop-home.png`: automatic Desktop mode, 1280 × 800.

Wi-Fi/cell indicators are unavailable placeholders. The VM has no battery backend
or audio device service. These captures do not validate physical touchscreens,
phone compatibility, calls, SMS or secure locking. Terminal content was created
for this development demonstration; no credentials or private files are shown.

The website builder packages these originals into a downloadable ZIP. Refresh
captures alongside UI changes; do not substitute concept boards for VM evidence.

The home and quick-controls captures include the newer compact 12-hour status
clock. Other captures preserve the clock preference used during their original
validation session. No hardware state is simulated in the controls capture.

`phone-bluetooth.png` shows PR #24's expanded Bluetooth controls in the existing
400x800 development VM, with the actual no-adapter state. It is development
evidence, not a capture of the published Alpha 2 ISO.

`login-preview-phone.png` (400x800) and `login-preview-small.png` (320x568)
show the phone sign-in preview in the development VM. They are explicitly
labelled preview: greetd/PAM boot login was not active for these captures. The
small-screen capture contains only synthetic partial entry, not a real PIN.

`phone-login.png`, `phone-login-rejected.png` and `phone-login-home.png` are real
greetd/PAM login evidence from the configured 400x800 development VM: entry page,
rejected PIN and authenticated Tessera home. No PIN is visible. These are distinct
from the earlier preview-labelled images and are not captures of Alpha 2.

## Updated tablet and desktop captures

`tablet-home.png`, `desktop-home.png`, `tablet-controls.png` and
`desktop-controls.png` were recaptured from source
`9c1f4a3f400a6358066b41ab9fb6720e4af33fb0` in the existing VM on 2026-10-18
UTC. The source was staged in an isolated directory and used a private copy of
the existing shell preferences. Auto selected Tablet at 800x1280 and Desktop at
1280x800. Home views show the current clock and floating navigation; controls
views include Bluetooth devices, audio controls, the camera action and media state.

The original private development source and preferences were preserved. The VM
returned to its original shell at 400x800 after capture. Capture details and
hashes are recorded in capture-manifest.json.
