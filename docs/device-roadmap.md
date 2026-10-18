# From prototype to a device in hand

Tessarchy currently runs as an Arch Linux session with a Quickshell interface
in an x86_64 VM. The next milestone is one physical reference device. This roadmap
defines the work and acceptance gates from that prototype to a daily-use pilot.

## Current verified foundation

Quiet Edge provides mobile navigation, a card switcher and adaptive shell layouts.
The optional greetd/PAM phone login passed wrong-PIN rejection, successful login
and return-to-greeter checks in the development VM. The published Alpha 2 ISO has
separate BIOS/UEFI VM boot evidence and predates the login and recent contributor
integrations. See [testing.md](testing.md) for exact evidence and remaining checks.

## Planned gates

| Stage | Work | Acceptance gate |
| --- | --- | --- |
| 01 — Stabilize the experience | Navigation, app switching, keyboard, settings, accessibility, radio controls and failure handling. Validate newly merged media/audio/screenshot integrations in the VM. | Repeatable VM regression checks and a usable touch-oriented workflow; physical touch still needs stage 03. |
| 02 — Select reference hardware | Audit Linux boot access, kernel/device support, GPU/display/touch, Wi-Fi/Bluetooth, audio, power management, storage and recovery. Decide tablet-first or phone-capable hardware. Determine whether an architecture port is necessary; the current x86_64 ISO does not establish ARM support. | One documented device, support matrix, required firmware, recovery route and unresolved risks. |
| 03 — Boot on real hardware | Build for the selected device and bring up display, touch, graphics, networking, audio, charging, battery reporting and thermal monitoring. | A usable native session with repeatable boot, input and essential component checks. |
| 04 — Complete the device experience | Tablet: rotation, practical applications, accessibility, battery life and suspend/resume. Phone: add modem integration, cellular data, calls, SMS and audio routing. | Hardware feature acceptance with recorded failures. Validate emergency calling and relevant network/operator requirements before treating a phone as dependable for those uses. |
| 05 — Harden and recover | First-boot account/PIN enrollment, credential change/recovery, data protection, signed updates, rollback and supported-device recovery documentation. Session locking requires its own implementation and validation. | Update and recovery drills pass; authentication, storage and locking claims match actual evidence. |
| 06 — Pilot in hand | Daily-use testing, power/thermal measurements, crash collection, accessibility checks and a small tester cohort. Publish a reproducible device image, install guide, support matrix and known issues. | Reliable use on the reference device, repeatable installation and a proven recovery path. |

The tablet and phone tracks have separate acceptance results. Broader device
support, manufacturing, commercial distribution and long-term support follow
the reference-device pilot as separate project decisions.

## Presentation asset

The professional roadmap poster is
[tessarchy-device-roadmap.png](../assets/roadmap/tessarchy-device-roadmap.png).
The selected final image is a curated project artwork asset, copied into the
repository for publication. Intermediate generations remain outside source.
The phone/tablet renders are labelled concepts. Actual VM captures live in
`assets/screenshots/`.

Generated with the built-in image generation tool using the existing official
logo as reference. The [prompt and correction pass](device-roadmap-image-prompt.txt)
are retained for future updates. The website provides the same six stages as text
so the generated poster is not the only way to read the roadmap.
