# Roadmap

1. **Prototype, implemented with user-reported VM smoke test:** Tessera navigation,
   apps, windows, maximize/restore, confirmed close/exit, namespaced user install,
   package recipes and VM workflow. Validate on the installed API versions.
   Notification pop-ups and the alert center are implemented; a live session
   acceptance pass is pending.
2. **Live image, started:** assemble a releng overlay; build and boot it, fix
   boot/user/graphics failures, test BIOS/UEFI, then package payloads properly.
3. **Text input:** research compositor and input-method protocols; validate an
   on-screen keyboard with Foot and Firefox, touch focus and resize behavior.
   A physical keyboard is required until this is done. No keyboard is recommended
   purely because it works under another compositor.
4. **Mobile policy:** continuous primary-window behavior, transient dialogs,
   rotation, scale presets and actual touchscreen tests. Current rule only
   maximizes on map; restore falls back to tiling.
5. **Tablet/docked, partly implemented:** Desktop mode now offers ordinary
   tiling, a workspace strip, a focused-window title and keyboard window
   management (responsive, but not yet user-tested). Optional two-app split
   layouts and a docked profile remain to do.
6. **Hardware:** explicit x86_64 tablets first; selected ARM devices only with
   documented boot, graphics and input support.

Not in milestone 1: cellular/SMS, Android/Waydroid, secure lock screen, custom
kernel, arbitrary Android phone ports, universal ARM images or production updates.
