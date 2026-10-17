# First live ISO pipeline (experimental)

`stage-iso.sh` copies `/usr/share/archiso/configs/releng` into
`build/iso-profile`. It preserves the installed bootloader templates, hooks and
bootmode syntax rather than hardcoding a stale upstream layout. It adds the
packages in `iso/packages.x86_64` and stages the shell/session directly into
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
`build/iso-work/x86_64/airootfs/usr/share/archiso/pkglist.x86_64.txt` if generated
by your archiso version. No automatic system upgrades occur.

Staging refuses to overwrite its destination. For a fresh build, stop the VM,
check `findmnt` for any remaining mkarchiso mounts after a failed build, and
remove only `build/iso-profile` and `build/iso-work` after mounts are released.
The latter may require sudo because mkarchiso owns it. Scripts never recursively
clean a privileged build directory themselves.

Current status: pipeline source and fixture-based staging checks only. `archiso`
is absent here; downloads, privileged builds, boot, tty1 autologin, user creation,
rendering and networking have not been validated in the real image. There is no
Tessarchy ISO artifact yet. Arch guest bring-up precedes any release claims.
