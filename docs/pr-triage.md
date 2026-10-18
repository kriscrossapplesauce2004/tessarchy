# Pull request triage — 2026-10-17

The owner requested an effort-ordered review, taking straightforward changes
and deferring disruptive or difficult work. This is a source-review assessment,
the starting point for focused integration work.
PRs #1–#8 and #24 were already merged when this pass started.

| Order | PR | Effort | Decision and reason |
| --- | --- | --- | --- |
| 1 | #15 Media controls | Low | Merged; glass pull-down icon controls with capability and player-disappearance guards. |
| 2 | #17 Audio panel | Low–medium | Merged; current pull-down integration, readiness/tracking fixes, playback-only filtering and guarded writes. |
| 3 | #14 Screenshots | Medium | Merged; unique private files, failure cleanup and manifest safety. VM acceptance pending. |
| 4 | #18 Power panel | Medium | Defer: installed PowerProfiles API exposes no availability flag; add reliable missing-service detection before enabling mode writes. |
| 5 | #21 Idle blanking | Medium | Defer: changes session startup and display wake behavior; current Lua dispatch and capture wake input need validation. |
| 6 | #23 Wi-Fi | Medium | Defer: scan ownership, connection lifecycle and NetworkManager acceptance need more work; no password agent. |
| 7 | #22 Rotation | Medium | Defer as disruptive: current keyword command is incompatible with Lua; rotation must preserve monitor/touch settings and be recoverable. |
| 8 | #13 Notifications | Medium–high | Defer: new D-Bus server, popup/history lifecycle, withdrawal handling and safe external text need integration. |
| 9 | #19 Brightness/night light | Medium–high | Defer: hardware coverage and PID ownership safety; current helper can target a reused, unrelated PID. |
| 10 | #9 System theme | High | Defer broad theme/app/keyboard changes; substantial local review is preserved uncommitted in build/integration. |
| 11 | #11 Keyboard sizing | High dependency cost | Small incremental patch, but its branch includes #9/#10; defer until those are reviewed. Width exception is already authorized. |
| 12 | #20 Keyboard page guard | High dependency cost | Includes #9/#10/#11; current shell already hides the keyboard for pages and pull-down. Review incremental differences later. |
| 13 | #12 Tablet split | High/disruptive | Defer: compositor layout/focus/workspace changes and an obsolete Recents implementation must be reconciled with the current card switcher. |
| 14 | #10 Touch file picker | High/disruptive | Defer: new C portal backend and GTK module, IPC/FIFO paths, cancellation and save/overwrite behavior require a dedicated review. |
| — | #16 Window previews | Superseded | Leave open for now: previews already exist in the current card switcher; merging the old grid would regress the requested interface. |

All changes must preserve the existing glass phone interface, application focus,
48-pixel targets (approved keyboard-width exception only), and close/exit
confirmations. Keep published Alpha 2 provenance unchanged. Record actual checks
in docs/testing.md and public merge results in docs/github-review.md.

Results: #15, #17 and #14 passed Ubuntu, Arch and ISO CI and were merged. That
integration checkpoint passed 35 Python and 30 Qt Quick checks; the latest source
baseline is 44 Python and 37 Qt Quick results. Real-player,
real-audio and screenshot/visual VM acceptance remains pending because the
previous SSH control session expired. The other 12 PRs remain open and deferred.
