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
# The tree mirrors the repository's shell/ directory, so uninstall adapts
# automatically when the shell grows new files and never guesses at paths.
while IFS= read -r -d '' relative; do
    rm -f -- "$data/shell/$relative"
done < <(cd -- "$root/shell" && find . -type f -printf '%P\0')
rm -f -- "$data/session/hyprland.lua" "$data/.tessarchy-dev-install"
rmdir -- "$data/shell/artwork" "$data/shell/icons" "$data/shell/components" "$data/shell" "$data/session" "$data" 2>/dev/null || true
echo "Development copy removed. ~/.config/tessarchy preferences retained."
