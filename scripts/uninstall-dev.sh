#!/usr/bin/env bash
set -euo pipefail
data=${XDG_DATA_HOME:-$HOME/.local/share}/tessarchy
[[ -f "$data/.tessarchy-dev-install" && ! -L "$data" ]] || {
    echo "No marked Tessarchy development installation at $data" >&2; exit 1;
}
[[ $(cat "$data/.tessarchy-dev-install") == tessarchy-dev-v1 ]] || exit 1
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# Preserve launchers edited since installation; report instead of deleting them.
for launcher in start-tessarchy tessera-shell; do
    target=$HOME/.local/bin/$launcher
    if [[ -e "$target" || -L "$target" ]]; then
        cmp -s -- "$root/session/$launcher" "$target" || {
            echo "Modified launcher: $target; preserve or remove it manually before uninstalling" >&2; exit 1;
        }
    fi
done
rm -f -- "$HOME/.local/bin/start-tessarchy" "$HOME/.local/bin/tessera-shell"
# Remove only installed files, never user preferences or unrelated files.
rm -f -- "$data/shell/shell.qml" "$data/shell/components/TouchButton.qml" "$data/shell/components/NavButton.qml" "$data/shell/components/AppTile.qml" "$data/shell/components/StatusIcon.qml" "$data/shell/components/AudioStatus.qml" "$data/shell/components/BrandMark.qml" "$data/shell/components/SettingsPage.qml" "$data/shell/components/LevelSlider.qml" "$data/shell/components/WifiPanel.qml" "$data/shell/LayoutPolicy.js"
for icon in back home recents power browser terminal wifi cellular volume volume-muted battery settings phone tablet desktop auto controls; do rm -f -- "$data/shell/icons/$icon.svg"; done
rm -f -- "$data/shell/artwork/aurora-fold.png" "$data/shell/artwork/tessarchy-mark.svg"
for face in 0 1 2 3 4 5; do rm -f -- "$data/shell/artwork/mark-face-$face.svg"; done
rm -f -- "$data/session/hyprland.lua" "$data/.tessarchy-dev-install"
rmdir -- "$data/shell/artwork" "$data/shell/icons" "$data/shell/components" "$data/shell" "$data/session" "$data" 2>/dev/null || true
echo "Development copy removed. ~/.config/tessarchy preferences retained."
