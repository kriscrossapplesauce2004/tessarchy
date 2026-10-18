# Development roadmap

The product direction is defined in [Operation Tessarchy](../Operation-TESSARCHY.md).
The [device roadmap](device-roadmap.md) tracks the path to a physical handheld.
Agents plan and claim implementation work in [AGENT-README.md](../AGENT-README.md).

## Current foundation

- Quiet Edge glass status bar, floating navigation, launcher and settings.
- Card switcher with live previews, icon actions and Alt+Tab.
- Automatic Phone/Tablet/Desktop layouts with saved overrides.
- Pull-down radio/layout controls and Bluetooth discovery/paired-device connections.
- Optional squeekboard, MPRIS and PipeWire integrations.
- Private screenshot helper and camera action.
- Phone PIN login through greetd/PAM, tested in the development VM.
- Alpha 2 live tester ISO with BIOS/UEFI VM boot evidence.
- GitHub Pages showcase, real captures, official branding and roadmap artwork.

The feature-by-feature validation record is in [testing.md](testing.md). Alpha 2
contains the earlier Quiet Edge build; release contents are listed on its page.

## Work order

1. Validate real media/audio services and screenshot actions in the VM.
2. Expand mobile input, switcher, settings and accessibility regression coverage.
3. Integrate the manageable portions of existing PRs using the
   [review order](pr-triage.md).
4. Select one reference device and document its component support.
5. Bring up the native session and measure connectivity, power and usability.
6. Complete enrollment, recovery and updates, then run a daily-use pilot.

The agent task board has stable IDs, ownership fields, dependencies and completion
results. Add new work there and update this overview when product priorities change.
