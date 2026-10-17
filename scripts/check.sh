#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
for script in scripts/*.sh session/start-tessarchy session/tessera-shell session/tessera-screenshot packaging/*/PKGBUILD; do bash -n "$script"; done
# Arch ships only python; Debian/Ubuntu split out python3. Accept either.
py=$(command -v python || command -v python3 || true)
[[ -n "$py" ]] || { echo "FAIL: neither python nor python3 is installed" >&2; exit 1; }
"$py" -m unittest discover -s tests -v
# Qt installs tools under /usr/lib/qt6/bin (Arch) or a multiarch libdir
# (Debian/Ubuntu); the QML import root differs the same way.
qml_root=""
for dir in /usr/lib/qt6/qml /usr/lib/*/qt6/qml; do
    if [[ -d "$dir/QtTest" ]]; then qml_root=$dir; break; fi
done
runner=$(command -v qmltestrunner || true)
if [[ -z "$runner" && -x /usr/lib/qt6/bin/qmltestrunner ]]; then runner=/usr/lib/qt6/bin/qmltestrunner; fi
if [[ -n "$runner" && -n "$qml_root" ]]; then
    HOME="$scratch" XDG_CONFIG_HOME="$scratch/config" QT_QPA_PLATFORM=offscreen \
        QML2_IMPORT_PATH="$qml_root" "$runner" -input tests/qml
else echo "SKIP: Qt Quick Test unavailable"; fi
compiler=$(command -v luac || command -v luac5.4 || true)
if [[ -n "$compiler" ]]; then "$compiler" -p session/hyprland.lua session/preferences.example.lua; else echo "SKIP: luac unavailable"; fi
if command -v fish >/dev/null; then fish -n iso/airootfs/etc/skel/.config/fish/config.fish; else echo "SKIP: fish unavailable"; fi
if command -v Hyprland >/dev/null; then
    # Verification must not load the current user's preferences.
    XDG_CONFIG_HOME="$scratch" Hyprland --verify-config -c "$root/session/hyprland.lua"
else echo "SKIP: Hyprland config parser unavailable"; fi
lint=$(command -v qmllint || true)
if [[ -z "$lint" && -x /usr/lib/qt6/bin/qmllint ]]; then lint=/usr/lib/qt6/bin/qmllint; fi
if [[ -n "$lint" ]]; then
    # Only missing Quickshell/Qt modules are expected warnings; errors fail.
    if [[ -n "$qml_root" ]]; then
        "$lint" -I "$qml_root" shell/shell.qml shell/components/*.qml
    else
        "$lint" shell/shell.qml shell/components/*.qml
    fi
else echo "SKIP: qmllint unavailable"; fi
if command -v shellcheck >/dev/null; then
    shellcheck scripts/*.sh session/start-tessarchy session/tessera-shell session/tessera-screenshot
else echo "SKIP: shellcheck unavailable"; fi
echo "Available static/integration checks passed; GUI and ISO boot tests remain manual."
