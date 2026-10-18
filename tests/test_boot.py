"""Exercise generated boot configuration without changing a running system."""
import importlib.util
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('boot_configuration', ROOT / 'scripts/configure-vm-boot.py')
boot = importlib.util.module_from_spec(spec)
spec.loader.exec_module(boot)


class BootConfiguration(unittest.TestCase):
    def test_quiet_grub_preserves_entries_and_kernel_arguments(self):
        source = "menuentry 'Test' {\n\techo 'Loading Linux linux ...'\n\tlinux /vmlinuz root=UUID=test rw\n\techo 'Loading initial ramdisk ...'\n\tinitrd /initramfs.img\n\techo 'Recovery instructions'\n}\n"
        result = boot.quiet_grub(source)
        self.assertNotIn('Loading Linux', result)
        self.assertNotIn('Loading initial ramdisk', result)
        for line in ("menuentry 'Test'", 'root=UUID=test rw', 'initrd /initramfs.img', 'Recovery instructions'):
            self.assertIn(line, result)

    def test_initramfs_configuration_preserves_hooks_and_is_idempotent(self):
        script = 'MODULES=(test_driver); HOOKS=(base systemd kms keyboard block sd-encrypt filesystems fsck)\n'
        script += boot.MKINIT + boot.MKINIT
        script += 'printf "%s\\n" "${MODULES[*]}" "${HOOKS[*]}"\n'
        result = subprocess.run(['bash', '-c', script], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), [
            'test_driver virtio_gpu',
            'base systemd kms keyboard plymouth block sd-encrypt filesystems fsck'])

    def test_unsupported_initramfs_layout_fails(self):
        script = 'MODULES=(); HOOKS=(base systemd filesystems)\n' + boot.MKINIT
        result = subprocess.run(['bash', '-c', 'apply_config() {\n' + script + '\n}\napply_config'],
                                capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('requires the block', result.stderr)
