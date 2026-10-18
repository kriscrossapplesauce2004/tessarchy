"""Observable install safety and profile assembly; no GUI or privileged tests."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class Workflows(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory(prefix='tessarchy-test-')
        self.addCleanup(self.scratch.cleanup)
        self.home = Path(self.scratch.name)
        self.env = dict(os.environ, HOME=str(self.home),
                        XDG_DATA_HOME=str(self.home / 'data'),
                        XDG_CONFIG_HOME=str(self.home / 'config'))
        for variable in ('DISPLAY', 'WAYLAND_DISPLAY', 'TESSARCHY_DATA_DIR'):
            self.env.pop(variable, None)

    def run_script(self, name, expected=0, env=None):
        result = subprocess.run([str(ROOT / 'scripts' / name)], env=env or self.env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result

    def test_install_uninstall_preserves_preferences_and_other_configs(self):
        sentinel = self.home / 'config/hypr/hyprland.conf'
        sentinel.parent.mkdir(parents=True)
        sentinel.write_text('existing config')
        preferences = self.home / 'config/tessarchy/preferences.lua'
        preferences.parent.mkdir(parents=True)
        preferences.write_text('-- mine')
        shell_settings = preferences.with_name('shell.ini')
        shell_settings.write_text('[Shell]\nlayoutMode=tablet\n')
        self.run_script('install-dev.sh')
        data = self.home / 'data/tessarchy'
        self.assertEqual((data / 'shell/shell.qml').read_bytes(),
                         (ROOT / 'shell/shell.qml').read_bytes())
        self.assertTrue((data / 'shell/components/NotificationCard.qml').is_file())
        self.assertTrue((data / 'shell/icons/bell.svg').is_file())
        self.assertTrue((self.home / '.local/bin/tessera-screenshot').is_file())
        self.run_script('install-dev.sh', expected=1)
        self.run_script('uninstall-dev.sh')
        self.assertFalse(data.exists())
        self.assertFalse((self.home / '.local/bin/tessera-screenshot').exists())
        self.assertEqual(sentinel.read_text(), 'existing config')
        self.assertEqual(preferences.read_text(), '-- mine')
        self.assertEqual(shell_settings.read_text(), '[Shell]\nlayoutMode=tablet\n')

    def test_brightness_helper_validates_arguments(self):
        helper = ROOT / 'session/tessera-brightness'
        for args in ([], ['bogus'], ['get', 'extra'], ['set'], ['set', '0'], ['set', '101'],
                     ['set', 'abc'], ['set', '-5'], ['step', '10']):
            result = subprocess.run([str(helper), *args], env=self.env,
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 64, args)

    def test_nightlight_helper_validates_arguments(self):
        import shutil
        helper = ROOT / 'session/tessera-nightlight'
        for args in ([], ['bogus'], ['on', 'extra'], ['off', 'extra'], ['status', 'extra']):
            result = subprocess.run([str(helper), *args], env=self.env,
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 64, args)
        if shutil.which('hyprsunset') is None:
            for args in (['status'], ['on']):
                result = subprocess.run([str(helper), *args], env=self.env,
                                        capture_output=True, text=True)
                self.assertEqual(result.returncode, 3, args)

    def test_existing_launcher_refused_before_installing_data(self):
        launcher = self.home / '.local/bin/start-tessarchy'
        launcher.parent.mkdir(parents=True)
        launcher.write_text('unrelated')
        self.run_script('install-dev.sh', expected=1)
        self.assertEqual(launcher.read_text(), 'unrelated')
        self.assertFalse((self.home / 'data/tessarchy').exists())

    def test_modified_launcher_blocks_uninstall(self):
        self.run_script('install-dev.sh')
        launcher = self.home / '.local/bin/start-tessarchy'
        launcher.write_text('modified')
        self.run_script('uninstall-dev.sh', expected=1)
        self.assertEqual(launcher.read_text(), 'modified')
        self.assertTrue((self.home / 'data/tessarchy/.tessarchy-dev-install').exists())

    def test_uninstall_requires_marker_and_preserves_extra_files(self):
        self.run_script('uninstall-dev.sh', expected=1)
        self.run_script('install-dev.sh')
        extra = self.home / 'data/tessarchy/keep.txt'
        extra.write_text('keep')
        self.run_script('uninstall-dev.sh')
        self.assertEqual(extra.read_text(), 'keep')

    def test_bluetooth_panel_wires_adapter_without_pairing(self):
        shell = (ROOT / 'shell/shell.qml').read_text()
        self.assertIn('import Quickshell.Bluetooth', shell)
        self.assertIn('readonly property var bluetoothAdapter: Bluetooth.defaultAdapter', shell)
        self.assertIn('BluetoothPanel {', shell)
        self.assertIn('available: root.bluetoothAvailable', shell)
        panel = (ROOT / 'shell/components/BluetoothPanel.qml').read_text()
        self.assertIn('import Quickshell.Bluetooth', panel)
        self.assertIn('Policy.btAction(', panel)
        self.assertIn('device.connect()', panel)
        self.assertIn('device.disconnect()', panel)
        self.assertIn('panel.adapter.discovering = panel.visible', panel)
        self.assertIn('no adapter available', panel)
        # Pairing needs interactive input; the panel never claims to do it.
        self.assertNotIn('pair(', panel)
        self.assertNotIn('forget(', panel)
        # uninstall-dev.sh mirrors the installed shell tree (see the
        # install/uninstall roundtrip test), so no file list is asserted here.
        policy = (ROOT / 'shell/LayoutPolicy.js').read_text()
        self.assertIn('function btAction', policy)
        self.assertIn('function btBatteryLabel', policy)

    def test_session_refuses_nested_graphical_launch(self):
        env = dict(self.env, WAYLAND_DISPLAY='wayland-test')
        result = subprocess.run([str(ROOT / 'session/start-tessarchy')], env=env,
                                capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('local TTY', result.stderr)

    def test_login_startup_roundtrip_preserves_profile_and_is_idempotent(self):
        self.run_script('install-dev.sh')
        profile = self.home / '.bash_profile'
        original = b'# existing setup\nexport KEEP_ME=yes\n'
        profile.write_bytes(original)
        command = [str(ROOT / 'scripts/login-session.sh')]
        def change(operation):
            return subprocess.run(command + [operation], env=self.env,
                                  capture_output=True, text=True)
        self.assertEqual(change('enable').returncode, 0)
        enabled = profile.read_bytes()
        self.assertTrue(enabled.startswith(original))
        self.assertIn(b'/dev/tty1', enabled)
        self.assertEqual(change('enable').returncode, 0)
        self.assertEqual(profile.read_bytes(), enabled)
        self.assertEqual(change('disable').returncode, 0)
        self.assertEqual(profile.read_bytes(), original)
        self.assertEqual(change('disable').returncode, 0)
        self.assertTrue(list(self.home.glob('.bash_profile.tessarchy-backup-*')))

    def test_login_startup_preserves_symlinks_and_modified_blocks(self):
        self.run_script('install-dev.sh')
        profile = self.home / '.bash_profile'
        target = self.home / 'real-profile'
        target.write_text('keep')
        profile.symlink_to(target)
        command = [str(ROOT / 'scripts/login-session.sh'), 'enable']
        result = subprocess.run(command, env=self.env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(target.read_text(), 'keep')
        profile.unlink()
        original = '# BEGIN TESSARCHY LOGIN\nmodified\n# END TESSARCHY LOGIN\n'
        profile.write_text(original)
        result = subprocess.run(command, env=self.env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(profile.read_text(), original)

    def test_basic_vm_uses_downloaded_disk_and_readonly_fresh_share(self):
        # Stub QEMU rather than open a window or touch a running guest disk.
        fakebin = self.home / 'bin'
        fakebin.mkdir()
        fakeqemu = fakebin / 'qemu-system-x86_64'
        fakeqemu.write_text('#!/bin/bash\nprintf "%s\\n" "$@"\n'
                            'test -f "$VM_SOURCE_SHARE/tessarchy/scripts/setup-guest.sh"\n')
        fakeqemu.chmod(0o755)
        import shutil
        source = self.home / 'source'
        for directory in ('scripts', 'shell', 'session', 'packaging', 'iso', 'docs', 'tests', 'assets'):
            shutil.copytree(ROOT / directory, source / directory)
        for name in ('README.md', 'AGENTS.md', 'LICENSE'):
            shutil.copy2(ROOT / name, source / name)
        (source / 'vm').mkdir()
        disk = source / 'vm/Arch-Linux-x86_64-basic.qcow2'
        disk.write_bytes(b'keep running guest image')
        env = dict(self.env, PATH=str(fakebin) + ':' + os.environ['PATH'])
        result = subprocess.run([str(source / 'scripts/run-basic-vm.sh')], env=env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(str(disk), result.stdout)
        self.assertIn('readonly=on', result.stdout)
        self.assertEqual(disk.read_bytes(), b'keep running guest image')
        self.assertFalse(list((source / 'build').glob('source-share.*')))

    def test_new_windows_follow_saved_mode_without_touching_dialogs(self):
        import shutil
        if not shutil.which('lua'):
            self.skipTest('Lua interpreter unavailable')
        folder = self.home / 'config/tessarchy'
        folder.mkdir(parents=True)
        script = r'''local callbacks, actions, binds, execs = {}, {}, {}, {}
hl = {
    monitor = function() end, config = function() end,
    bind = function(keys, dispatcher, flags) binds[keys] = { dispatcher = dispatcher, flags = flags } end,
    exec_cmd = function(command) table.insert(execs, command) end,
    on = function(name, callback) callbacks[name] = callback end,
    dispatch = function(action) table.insert(actions, action) end,
    dsp = { exec_cmd = function(command) return { exec = command } end, exit = function() end,
            focus = function(target) return target end,
            window = { fullscreen = function(action) return action end,
                       close = function() return {} end,
                       cycle_next = function() return {} end,
                       move = function(target) return target end,
                       drag = function() return {} end,
                       resize = function() return {} end } }
}
dofile(arg[1])
-- Desktop bindings stay present and are built from fixed keys and dispatchers.
for i = 1, 5 do
    assert(binds["SUPER + " .. i], "missing workspace bind " .. i)
    assert(binds["SUPER + " .. i].dispatcher.workspace == i, "workspace bind targets wrong workspace")
    assert(binds["SUPER + SHIFT + " .. i], "missing move-to-workspace bind " .. i)
    assert(binds["SUPER + SHIFT + " .. i].dispatcher.workspace == i, "move bind targets wrong workspace")
end
for _, name in ipairs({ "SUPER + Q", "SUPER + Tab", "SUPER + left", "SUPER + right",
    "SUPER + up", "SUPER + down", "SUPER + SHIFT + left", "SUPER + SHIFT + right",
    "SUPER + SHIFT + up", "SUPER + SHIFT + down" }) do
    assert(binds[name], "missing desktop bind: " .. name)
end
assert(binds["SUPER + mouse:272"].flags.mouse == true, "drag bind must be a mouse bind")
assert(binds["SUPER + mouse:273"].flags.mouse == true, "resize bind must be a mouse bind")
assert(binds["XF86AudioMute"].flags.locked == true and binds["XF86AudioMute"].flags.repeating == true,
    "volume keys must work on the lock screen and repeat")
assert(binds["XF86MonBrightnessUp"] and binds["XF86MonBrightnessUp"].dispatcher.exec == "tessera-brightness up",
    "brightness up binding missing")
assert(binds["XF86MonBrightnessDown"] and binds["XF86MonBrightnessDown"].dispatcher.exec == "tessera-brightness down",
    "brightness down binding missing")
assert(callbacks["hyprland.start"], "missing hyprland.start autostart")
callbacks["hyprland.start"]()
local shell, idle = 0, 0
for _, command in ipairs(execs) do
    if command:match("tessera%-shell") then shell = shell + 1 end
    if command:match("hypridle") then idle = idle + 1 end
end
assert(shell == 1, "tessera-shell must start exactly once from the session config")
assert(idle == 1, "hypridle must start exactly once from the session config")
local function check(mode, width, height, scale, transform, floating, fullscreen, expected)
    local f = assert(io.open(os.getenv("XDG_CONFIG_HOME") .. "/tessarchy/shell.ini", "w"))
    f:write("[Other]\nlayoutMode=desktop\n[Shell]\nlayoutMode=" .. mode .. "\n")
    f:close()
    actions = {}
    local window = { floating = floating, fullscreen = fullscreen,
        monitor = {width=width, height=height, scale=scale, transform=transform} }
    callbacks["window.open"](window)
    assert(#actions == expected, mode .. ": unexpected app startup policy")
    if expected == 1 then
        assert(actions[1].window == window and actions[1].mode == "maximized")
    end
end
check("auto", 400, 800, 1, 0, false, 0, 1)
check("auto", 800, 1280, 1, 0, false, 0, 1)
check("auto", 1280, 800, 1, 0, false, 0, 0)
check("auto", 1280, 800, 2, 0, false, 0, 1)
check("auto", 1280, 800, 1, 1, false, 0, 1)
check("desktop", 400, 800, 1, 0, false, 0, 0)
check("phone", 1280, 800, 1, 0, false, 0, 1)
check("invalid", 400, 800, 1, 0, false, 0, 1)
check("phone", 400, 800, 1, 0, true, 0, 0)
check("phone", 400, 800, 1, 0, false, 2, 0)
'''
        result = subprocess.run(['lua', '-', str(ROOT / 'session/hyprland.lua')],
                                input=script, text=True, capture_output=True, env=self.env)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_screenshot_script_saves_png_and_notifies(self):
        fakebin = self.home / 'bin'
        fakebin.mkdir()
        grim = fakebin / 'grim'
        grim.write_text('#!/bin/bash\nprintf png > "$1"\n')
        grim.chmod(0o755)
        log = self.home / 'notify.log'
        notifier = fakebin / 'notify-send'
        notifier.write_text('#!/bin/bash\nprintf "%s\\n" "$@" > ' + str(log) + '\n')
        notifier.chmod(0o755)
        env = dict(self.env, PATH=str(fakebin) + ':' + os.environ['PATH'],
                   XDG_PICTURES_DIR=str(self.home / 'pictures'))
        result = subprocess.run([str(ROOT / 'session/tessera-screenshot')], env=env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        saved = Path(result.stdout.strip())
        self.assertTrue(saved.is_file())
        self.assertTrue(saved.parent.as_posix().endswith('/pictures/Screenshots'))
        self.assertTrue(saved.name.startswith('tessarchy-') and saved.name.endswith('.png'))
        self.assertEqual(saved.read_text(), 'png')
        self.assertEqual(log.read_text().splitlines()[-1], saved.name)
        self.assertIn('Screenshot saved', log.read_text())
        grim.unlink()
        result = subprocess.run([str(ROOT / 'session/tessera-screenshot')], env=env,
                                capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('grim is required', result.stderr)
    def test_rotation_control_installs_and_removes_cleanly(self):
        uninstall = (ROOT / 'scripts/uninstall-dev.sh').read_text()
        # The mirror removes every file under the installed shell/ tree,
        # so new components need no list entry; session files stay explicit.
        self.assertIn("find . -type f", uninstall)
        self.assertIn('$data/shell/$relative', uninstall)
        self.assertIn('hypridle.conf', uninstall)
        page = (ROOT / 'shell/components/SettingsPage.qml').read_text()
        self.assertIn('RotationControl {', page)
        control = (ROOT / 'shell/components/RotationControl.qml').read_text()
        self.assertIn('Quickshell.execDetached([', control)
        self.assertIn('"keyword", "monitor"', control)
        self.assertIn('transform', control)
    def test_wifi_panel_uses_networking_api_without_psk_entry(self):
        shell = (ROOT / 'shell/shell.qml').read_text()
        self.assertIn('import Quickshell.Networking', shell)
        self.assertIn('WifiPanel {', shell)
        self.assertIn('available: root.networkBackend', shell)
        panel = (ROOT / 'shell/components/WifiPanel.qml').read_text()
        # Policy decides connect vs disconnect; no password is ever passed.
        self.assertIn('Policy.wifiAction(', panel)
        self.assertIn('network.connect()', panel)
        self.assertIn('network.disconnect()', panel)
        self.assertNotIn('connectWithPsk', panel)
        # Scanner runs only while the panel is visible.
        self.assertIn('scannerEnabled = panel.visible', panel)
        icon = (ROOT / 'shell/components/StatusIcon.qml').read_text()
        self.assertIn('property bool available', icon)

    def test_iso_staging_preserves_boot_assets_and_account_databases(self):
        # Minimal fixture exercises our assembly, not upstream archiso validity.
        repo = self.home / 'source'
        (repo / 'scripts').mkdir(parents=True)
        import shutil
        for directory in ('shell', 'session', 'iso', 'docs'):
            shutil.copytree(ROOT / directory, repo / directory)
        shutil.copy2(ROOT / 'scripts/stage-iso.sh', repo / 'scripts')
        base = self.home / 'releng'
        (base / 'airootfs/etc/systemd/system/multi-user.target.wants').mkdir(parents=True)
        (base / 'profiledef.sh').write_text('file_permissions=(["/etc/shadow"]="0:0:400")\n')
        (base / 'packages.x86_64').write_text('base\nlinux\nunused-rescue-tool\n')
        (base / 'airootfs/etc/passwd').write_text('root:x:0:0:root:/root:/usr/bin/zsh\n')
        boot = base / 'efiboot/loader/entries'
        boot.mkdir(parents=True)
        (boot / 'arch.conf').write_text('retained boot asset')
        ssh_link = base / 'airootfs/etc/systemd/system/multi-user.target.wants/sshd.service'
        ssh_link.symlink_to('/usr/lib/systemd/system/sshd.service')
        env = dict(self.env, ARCHISO_RELENG=str(base))
        command = [str(repo / 'scripts/stage-iso.sh')]
        result = subprocess.run(command, env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        profile = repo / 'build/iso-profile'
        self.assertEqual((profile / 'efiboot/loader/entries/arch.conf').read_text(),
                         'retained boot asset')
        self.assertEqual((profile / 'airootfs/etc/passwd').read_text(),
                         'root:x:0:0:root:/root:/usr/bin/bash\n')
        self.assertIn('/usr/bin/zsh', (base / 'airootfs/etc/passwd').read_text())
        self.assertFalse((profile / 'airootfs/etc/group').exists())
        self.assertFalse((profile / 'airootfs/etc/systemd/system/multi-user.target.wants/sshd.service').is_symlink())
        self.assertTrue(ssh_link.is_symlink())
        self.assertIn('quickshell', (profile / 'packages.x86_64').read_text())
        self.assertNotIn('unused-rescue-tool', (profile / 'packages.x86_64').read_text())
        self.assertNotIn('linux-firmware', (profile / 'packages.x86_64').read_text())
        self.assertTrue((profile / 'airootfs/etc/systemd/system/multi-user.target.wants/systemd-networkd.service').is_symlink())
        self.assertTrue((profile / 'airootfs/etc/systemd/system/multi-user.target.wants/systemd-timesyncd.service').is_symlink())
        self.assertEqual((profile / 'airootfs/etc/hostname').read_text().strip(), 'tessarchy')
        self.assertIn('en_US.UTF-8', (profile / 'airootfs/etc/locale.conf').read_text())
        self.assertIn('en_US.UTF-8', (profile / 'airootfs/etc/locale.gen').read_text())
        self.assertIn('/usr/share/tessarchy/docs', (profile / 'airootfs/etc/motd').read_text())
        self.assertIn('Storage=volatile',
                      (profile / 'airootfs/etc/systemd/journald.conf.d/volatile.conf').read_text())
        self.assertTrue((profile / 'airootfs/usr/share/tessarchy/docs/iso.md').is_file())
        self.assertTrue((profile / 'airootfs/usr/bin/start-tessarchy').stat().st_mode & 0o111)
        self.assertIn('u tess 1000 "Tessarchy live user" /home/tess /usr/bin/fish',
                      (profile / 'airootfs/etc/sysusers.d/tessarchy.conf').read_text())
        self.assertIn('fish', (profile / 'packages.x86_64').read_text().splitlines())
        self.assertTrue((profile / 'airootfs/home/tess/.config/fish/config.fish').is_file())
        self.assertIn('/home/tess/.config/fish/config.fish', (profile / 'profiledef.sh').read_text())
        self.assertTrue((profile / 'airootfs/usr/bin/tessera-screenshot').stat().st_mode & 0o111)
        self.assertTrue((profile / 'airootfs/usr/bin/tessera-brightness').stat().st_mode & 0o111)
        self.assertTrue((profile / 'airootfs/usr/bin/tessera-nightlight').stat().st_mode & 0o111)
        packages = (profile / 'packages.x86_64').read_text().splitlines()
        self.assertIn('grim', packages)
        self.assertIn('libnotify', packages)
        self.assertIn('brightnessctl', packages)
        self.assertIn('hyprsunset', packages)
        self.assertIn('/usr/bin/tessera-screenshot', (profile / 'profiledef.sh').read_text())
        self.assertTrue((profile / 'airootfs/usr/share/tessarchy/session/hypridle.conf').is_file())
        self.assertIn('hypridle', (profile / 'packages.x86_64').read_text())
        self.assertIn('u tess 1000', (profile / 'airootfs/etc/sysusers.d/tessarchy.conf').read_text())
        result = subprocess.run(command, env=env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)

    def test_idle_config_blanks_screen_without_locking(self):
        config = (ROOT / 'session/hypridle.conf').read_text()
        self.assertIn('timeout = 300', config)
        self.assertIn('on-timeout = hyprctl dispatch dpms off', config)
        self.assertIn('on-resume = hyprctl dispatch dpms on', config)
        self.assertNotIn('lock_cmd', config)
        self.assertNotIn('swaylock', config)


if __name__ == '__main__':
    unittest.main()
