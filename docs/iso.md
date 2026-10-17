# First live ISO pipeline (experimental)

`stage-iso.sh` copies `/usr/share/archiso/configs/releng` into
`build/iso-profile`. It preserves the installed bootloader templates, hooks and
bootmode syntax rather than hardcoding a stale upstream layout. It uses the VM-focused
package set in `iso/packages.x86_64` and stages the shell/session directly into
`/usr/share/tessarchy` and `/usr/bin`. These overlay files are not pacman-owned;
using the local packages in a signed repository is a later milestone.

The profile appends Tessarchy metadata, uses x86_64, and selects a relatively
light zstd squashfs compression. Upstream Arch boot menu branding is retained
for now. The image includes both the boot methods of the installed releng
profile; BIOS and UEFI must both be tested. It does not install onto a disk.

The live user `tess` is created through systemd-sysusers with a locked password,
no sudo grant, tty1 autologin, and fish as the login shell (`fish` is added to
the package list). tmpfiles and `file_permissions` establish home ownership for
the Bash and fish login profiles; both start Tessera once on tty1 and return to
the TTY on exit. Nothing in the fish profile is needed for development installs
where Bash starts the session. No secure locking or
login protection is provided. Releng's root rescue account remains available
according to upstream defaults. SSH enablement links are removed from the
staged profile; user-mode VM NAT exposes no forwarded ports. This is a disposable
development live environment. Do not use it for sensitive work or install it as
a daily driver. Package-provided services and sockets need review before any
public release.

The staged rootfs pins the hostname to `tessarchy`, generates the en_US.UTF-8
locale, sets a live-console motd that points at `/usr/share/tessarchy/docs`
(a snapshot of `docs/` staged into the image), keeps the journal volatile with
a 64M runtime cap, and enables `systemd-timesyncd` alongside networkd so guests
without a working RTC still get a sane clock. `noto-fonts-emoji` is included so
browser pages render emoji. None of this changes development installs.

## Build explicitly on Arch

```bash
sudo pacman -S --needed archiso
./scripts/check.sh
./scripts/stage-iso.sh
# Review build/iso-profile/profiledef.sh and airootfs before building.
./scripts/build-iso.sh
./scripts/vm.sh run dist/<actual-ISO-filename>.iso
VM_UEFI=1 ./scripts/vm.sh run dist/<actual-ISO-filename>.iso
```

Prerequisites: internet, a consistent current Arch installation, administrator
access for mkarchiso, and roughly 15–25GiB free disk. More than 2GiB memory is
recommended for building. ISO builds are not bit-reproducible yet: repository
versions and date metadata change. Record `pacman -Q archiso`, build log and
`build/iso-work/iso/arch/pkglist.x86_64.txt` if generated
by your archiso version. No automatic system upgrades occur.

Staging refuses to overwrite its destination. For a fresh build, stop the VM,
check `findmnt` for any remaining mkarchiso mounts after a failed build, and
remove only `build/iso-profile` and `build/iso-work` after mounts are released.
The latter may require sudo because mkarchiso owns it. Scripts never recursively
clean a privileged build directory themselves.

## Tester prerelease, 2026-10-17 UTC

[Alpha 1](https://github.com/thediamondsaint/tessarchy/releases/tag/v0.1.0-alpha.1)
contains the approximately 1 GiB `tessarchy-0.1.0-20261017-x86_64.iso`, checksum,
package manifest, build log, source provenance and BIOS/UEFI boot evidence.
The ISO is a Release asset; disk images remain excluded from Git history.

GitHub Actions run [38997819650](https://github.com/thediamondsaint/tessarchy/actions/runs/38997819650)
built the image with archiso 91-1 from commit
`90c5eee58f8be68ae9b9a670c3479f0ff453449b`. The checksum passed in CI and matches
the GitHub asset digest. The agent inspected final captures of both diskless
BIOS and non-Secure-Boot UEFI QEMU/KVM boots: Tessera's GUI was running after
live-user autologin. These used 2 GiB RAM, 2 vCPUs and virtio graphics.

To create a new tester draft, dispatch `Build Tessarchy ISO` on the desired
branch and supply a new `release_tag`. It builds, verifies the checksum,
collects BIOS/UEFI screenshots, and creates a draft prerelease. KVM is used when
available; software emulation gets a longer capture window. **Inspect the actual
captures before publishing or claiming graphical boot success.** The capture
script deliberately does not infer GUI success from a running QEMU process.

Application/device acceptance, networking/audio, touch, physical hardware,
Secure Boot and persistence behavior were not tested in this exact image.
Read the attached `BOOT-TESTING.md` and [validation record](testing.md).
