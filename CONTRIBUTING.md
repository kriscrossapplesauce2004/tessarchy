# Contributing to Tessarchy

Start with [AGENT-README.md](AGENT-README.md) for project context, the task board
and the contribution workflow. [AGENTS.md](AGENTS.md) contains repository rules;
An optional ignored `.HANDOFF.local.md` holds local session notes.

## Choose and plan work

Claim one task, record the branch and define a completion result. Keep changes
focused and preserve contributor history. Check existing pull requests before
starting a replacement implementation. The current review order and dependencies
are in [docs/pr-triage.md](docs/pr-triage.md).

Use standard technical English and one-line comments. Write direct descriptions
of behavior, commands and results. Record limitations once where they affect a
specific action or validation result.

## Build and validate

The API baseline is Hyprland 0.56 Lua and Quickshell 0.3.1. Development runs in an
Arch guest. Inspect installed type metadata when changing API usage.

```bash
./scripts/check.sh
```

Use scratch HOME for install/uninstall checks. Test affected UI behavior in the
VM and attach real screenshots. Record commands, results and remaining manual
checks in [docs/testing.md](docs/testing.md). The Ubuntu and Arch workflows run
the source checks with their toolchains.

## Submit a contribution

Lead the PR with the concrete problem and resulting behavior. Include the task
ID, validation and relevant screenshots. Update the task register with the commit/PR link and next action. Keep machine
paths and personal operational notes in the ignored local handoff. For bugs, include reproduction steps,
source revision, display size/scale, relevant package versions and error output.

Keep private credentials and disk images out of Git. Packages and images belong in
ignored output directories or GitHub release assets. The project uses the
[MIT License](LICENSE).
