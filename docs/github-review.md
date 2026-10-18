# GitHub integration status

Snapshot: 2026-10-17. Query GitHub for current heads before beginning a review.

## Merged

| PRs | Result |
| --- | --- |
| #1–#8 | Shell, tooling, desktop controls, live defaults, checks, keyboard and mobile window policy |
| #24 | Bluetooth adapter discovery and already-paired device connections |
| #15 | Guarded MPRIS media controls |
| #17 | Optional PipeWire output and application controls |
| #14 | Private collision-safe screenshots and camera action |
| #25 | Phone PIN login, supported Hyprland launch path and official logo exports |
| #26 | Current showcase, device roadmap and sharing assets |

## Open review queue

Twelve contributor PRs remain open: #9, #10, #11, #12, #13, #16, #18, #19, #20,
#21, #22 and #23. Their scope, dependencies and review order are in
[pr-triage.md](pr-triage.md). Agent tasks T09–T20 cover this queue.

The working tree at `build/integration` preserves an unfinished #9 integration.
Continue it in place only when assigned that work; keep its contributor changes.

## Integration workflow

1. Fetch the exact contributor head and compare it with current main.
2. Identify dependencies and overlapping implementations.
3. Preserve author history and make focused integration fixes.
4. Run source checks and the affected runtime workflow.
5. Record evidence, merge after checks pass and synchronize public branches.

Latest source baseline: 44 Python tests and 37 Qt Quick results. Actual feature
acceptance is recorded in [testing.md](testing.md).

## Release and site

Alpha 2 remains the tester ISO from source
`aa8b59a73a8d5d6b1d3fab6c17272e68e0bfac58`. Later merged contributions are in
development source. Its release assets contain the exact image provenance.

The website deploys from approved `main`/`build/live-iso` pushes and manual
workflow dispatch. It reads current public release/commit metadata. Branding
assets use their own release; tester download selection requires an ISO asset.
