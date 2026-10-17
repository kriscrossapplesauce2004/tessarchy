#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
for script in scripts/*.sh session/start-tessarchy session/tessera-shell packaging/*/PKGBUILD; do bash -n "$script"; done
python -m unittest discover -s tests -v
if [[ -x /usr/lib/qt6/bin/qmltestrunner && -d /usr/lib/qt6/qml/QtTest ]]; then
    HOME="$scratch" XDG_CONFIG_HOME="$scratch/config" QT_QPA_PLATFORM=offscreen \
        /usr/lib/qt6/bin/qmltestrunner -input tests/qml
else echo "SKIP: Qt Quick Test unavailable"; fi
if command -v luac >/dev/null; then luac -p session/hyprland.lua session/preferences.example.lua; else echo "SKIP: luac unavailable"; fi
if command -v fish >/dev/null; then fish -n iso/airootfs/etc/skel/.config/fish/config.fish; else echo "SKIP: fish unavailable"; fi
if command -v Hyprland >/dev/null; then
    # Verification must not load the current user's preferences.
    XDG_CONFIG_HOME="$scratch" Hyprland --verify-config -c "$root/session/hyprland.lua"
else echo "SKIP: Hyprland config parser unavailable"; fi
lint=$(command -v qmllint || true)
if [[ -z "$lint" && -x /usr/lib/qt6/bin/qmllint ]]; then lint=/usr/lib/qt6/bin/qmllint; fi
if [[ -n "$lint" ]] && command -v qs >/dev/null; then
    "$lint" -I /usr/lib/qt6/qml shell/shell.qml shell/components/*.qml
else echo "SKIP: qmllint/Quickshell unavailable"; fi
if command -v shellcheck >/dev/null; then
    shellcheck scripts/*.sh session/start-tessarchy session/tessera-shell
else echo "SKIP: shellcheck unavailable"; fi
echo "Available static/integration checks passed; GUI and ISO boot tests remain manual."
