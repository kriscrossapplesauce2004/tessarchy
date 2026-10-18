#!/usr/bin/env bash
# Download data only; never executes fetched content. Verify detached signature.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
for tool in curl gpgv sha256sum; do command -v "$tool" >/dev/null || { echo "Missing $tool" >&2; exit 1; }; done
keyring=${ARCH_ISO_KEYRING:-/usr/share/pacman/keyrings/archlinux.gpg}
[[ -f "$keyring" ]] || { echo "Install/update archlinux-keyring first" >&2; exit 1; }
mkdir -p "$root/vm"
work=$(mktemp -d "$root/vm/.download.XXXXXX")
trap 'rm -rf -- "$work"' EXIT
base=${ARCH_ISO_MIRROR:-https://geo.mirror.pkgbuild.com/iso/latest}
base=${base%/}
[[ $base == https://* ]] || { echo "ARCH_ISO_MIRROR must be an HTTPS ISO directory" >&2; exit 1; }
curl --fail --location --connect-timeout 15 --retry 2 "$base/sha256sums.txt" -o "$work/sha256sums.txt"
filename=$(sed -nE 's/^[a-f0-9]{64} +\*?(archlinux-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-x86_64\.iso)$/\1/p' "$work/sha256sums.txt")
[[ $filename =~ ^archlinux-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-x86_64\.iso$ ]] || { echo "No unique x86_64 ISO in manifest" >&2; exit 1; }
[[ ! -e "$root/vm/$filename" ]] || { echo "ISO already exists; use it or move it before downloading" >&2; exit 1; }
curl --fail --location --connect-timeout 15 --retry 2 "$base/$filename" -o "$work/$filename"
curl --fail --location --connect-timeout 15 --retry 2 "$base/$filename.sig" -o "$work/$filename.sig"
(cd "$work"; grep -F "$filename" sha256sums.txt | sha256sum -c -)
gpgv --keyring "$keyring" "$work/$filename.sig" "$work/$filename"
mv -- "$work/$filename" "$root/vm/"
echo "Verified Arch installation ISO: $root/vm/$filename"
