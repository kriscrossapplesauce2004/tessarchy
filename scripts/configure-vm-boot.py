#!/usr/bin/env python3
"""Plan or activate the Tessarchy boot configuration in the development VM."""
import argparse
from datetime import datetime, timezone
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

GRUB = '''# Managed by Tessarchy: quiet graphical VM startup.
GRUB_DISTRIBUTOR="Tessarchy"
GRUB_TIMEOUT_STYLE=hidden
GRUB_TIMEOUT=1
GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT quiet splash loglevel=0 systemd.show_status=false rd.systemd.show_status=false udev.log_level=3 rd.udev.log_level=3 vt.global_cursor_default=0 logo.nologo video=Virtual-1:400x800@60"
'''
MKINIT = '''# Managed by Tessarchy: early virtual GPU and graphical startup.
if [[ ! " ${MODULES[*]} " == *" virtio_gpu "* ]]; then MODULES+=(virtio_gpu); fi
if [[ ! " ${HOOKS[*]} " == *" plymouth "* ]]; then
    tessarchy_hooks=()
    tessarchy_inserted=0
    for tessarchy_hook in "${HOOKS[@]}"; do
        if [[ $tessarchy_hook == block ]]; then
            tessarchy_hooks+=(plymouth)
            tessarchy_inserted=1
        fi
        tessarchy_hooks+=("$tessarchy_hook")
    done
    if (( ! tessarchy_inserted )); then
        echo "Tessarchy requires the block initramfs hook" >&2
        return 1
    fi
    HOOKS=("${tessarchy_hooks[@]}")
    unset tessarchy_hooks tessarchy_hook tessarchy_inserted
fi
'''
MANAGED = {
    Path('/etc/default/grub.d/60-tessarchy.cfg'): GRUB,
    Path('/etc/mkinitcpio.conf.d/60-tessarchy.conf'): MKINIT,
}


def quiet_grub(text):
    lines = text.splitlines(keepends=True)
    return ''.join(line for line in lines if not re.match(
        r'''^\s*echo\s+['"]Loading (?:Linux |initial ramdisk)''', line))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    if not args.apply:
        print('Plan: add quiet GRUB and early Plymouth/KMS configuration; back up boot files;')
        print('rebuild the VM initramfs; validate and install a quiet generated GRUB config.')
        print('Requires the installed Tessarchy Plymouth theme; does not install packages or reboot.')
        return
    if os.geteuid() != 0:
        parser.error('Activation requires root inside the development VM')
    virt = subprocess.run(['systemd-detect-virt', '--vm'], capture_output=True, text=True)
    if virt.returncode or virt.stdout.strip() not in ('kvm', 'qemu'):
        parser.error('Activation is restricted to a QEMU/KVM development VM')
    for tool in ('mkinitcpio', 'grub-mkconfig', 'grub-script-check', 'plymouth', 'plymouth-set-default-theme'):
        if not shutil.which(tool):
            parser.error(f'Missing prerequisite: {tool}')
    required = [Path('/boot/initramfs-linux.img'), Path('/boot/grub/grub.cfg'),
                Path('/usr/share/plymouth/themes/tessarchy/tessarchy.script')]
    if not all(path.exists() for path in required) or not any(Path('/sys/class/drm').glob('card*-Virtual-1')):
        parser.error('Expected VM boot files, theme or virtio display are missing')
    for path, content in MANAGED.items():
        if path.is_symlink() or (path.exists() and path.read_text() != content):
            parser.error(f'Refusing an unrelated existing configuration: {path.name}')
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    backup = Path('/var/lib/tessarchy/boot-backups') / stamp
    backup.mkdir(parents=True, mode=0o700)
    for path in [*MANAGED, *required[:2], Path('/etc/plymouth/plymouthd.conf')]:
        if path.exists():
            target = backup / path.relative_to('/')
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, target)
    for path, content in MANAGED.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
    subprocess.run(['plymouth-set-default-theme', 'tessarchy'], check=True)
    subprocess.run(['mkinitcpio', '-P'], check=True)
    candidate = backup / 'grub.candidate.cfg'
    subprocess.run(['grub-mkconfig', '-o', str(candidate)], check=True,
                   env=dict(os.environ, LC_ALL='C'))
    candidate.write_text(quiet_grub(candidate.read_text()))
    subprocess.run(['grub-script-check', str(candidate)], check=True)
    destination = Path('/boot/grub/grub.cfg')
    with tempfile.NamedTemporaryFile(dir=destination.parent, prefix='.tessarchy-', delete=False) as stream:
        temporary = Path(stream.name)
        stream.write(candidate.read_bytes())
    try:
        temporary.chmod(destination.stat().st_mode & 0o777)
        os.replace(temporary, destination)
    finally:
        temporary.unlink(missing_ok=True)
    print('VM boot configuration activated; previous boot files saved in the private backup directory.')


if __name__ == '__main__':
    main()
