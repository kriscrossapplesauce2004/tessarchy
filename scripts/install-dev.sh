#!/usr/bin/env bash
# Copy-only, namespaced, non-root installation. Refuse unknown existing files.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
[[ $EUID != 0 ]] || { echo "Run as a development user, not root" >&2; exit 1; }
data=${XDG_DATA_HOME:-$HOME/.local/share}/tessarchy
bin=$HOME/.local/bin
marker=$data/.tessarchy-dev-install
for path in "$data" "$bin/start-tessarchy" "$bin/tessera-shell" "$bin/tessarchy-osk" "$bin/tessera-screenshot"; do
    if [[ -e "$path" || -L "$path" ]]; then
        echo "Refusing existing path: $path (uninstall this dev copy first)" >&2; exit 1
    fi
done
mkdir -p -- "$data/session" "$bin"
cp -R -- "$root/shell" "$data/"
cp -- "$root/session/hyprland.lua" "$data/session/"
cp -- "$root/session/start-tessarchy" "$root/session/tessera-shell" "$root/session/tessarchy-osk" "$root/session/tessera-screenshot" "$bin/"
printf '%s\n' 'tessarchy-dev-v2' > "$marker"
# Record installed data files relative to the private data directory.
manifest=$data/.tessarchy-dev-files
{
    find "$data" -mindepth 1 \( -type f -o -type l \) ! -name '.tessarchy-dev-files' -printf '%P\n' | sort
} > "$manifest"
echo "Installed to $data. From a local TTY: $bin/start-tessarchy"
