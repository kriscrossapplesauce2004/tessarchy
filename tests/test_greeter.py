"""Isolated greetd protocol tests; synthetic credentials, no real PAM or users."""
import json
import os
from pathlib import Path
import shutil
import socket
import struct
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class PhoneGreeter(unittest.TestCase):
    def exchange(self, scenario):
        quickshell = shutil.which('qs')
        if not quickshell:
            self.skipTest('Quickshell runtime unavailable')
        with tempfile.TemporaryDirectory(prefix='tessarchy-greeter-') as temporary:
            scratch = Path(temporary)
            runtime = scratch / 'runtime'
            runtime.mkdir(mode=0o700)
            shutil.copytree(ROOT / 'shell', scratch / 'shell')
            harness = scratch / 'test.qml'
            harness.write_text('''import QtQuick
import Quickshell
import Quickshell.Services.Greetd
import "shell/components"
ShellRoot {
    PinLoginController { id: login; backend: Greetd; inactiveState: GreetdState.Inactive }
    Timer { interval: 100; running: true; onTriggered: login.begin("0123") }
    Timer {
        interval: 1300; running: true
        onTriggered: {
            if (login.pendingPin.length === 0 && !login.attemptActive && login.message.length > 0) {
                console.log("LOGIN_FAIL_CLOSED");
                if (login.message.startsWith("Passcode not recognized")) console.log("LOGIN_REJECTION_MESSAGE_OK");
            } else console.error("LOGIN_TEST_FAILED");
            Qt.quit();
        }
    }
}
''')
            if scenario == 'disconnect':
                harness.write_text(harness.read_text().replace(
                    'onTriggered: login.begin("0123")',
                    'onTriggered: { login.deadline.interval = 300; login.begin("0123"); }'))
            env = dict(os.environ, HOME=temporary, XDG_CONFIG_HOME=str(scratch / 'config'),
                       XDG_RUNTIME_DIR=str(runtime), QT_QPA_PLATFORM='offscreen',
                       QT_QPA_PLATFORMTHEME='', GREETD_SOCK=str(scratch / 'greetd.sock'))
            for key in ('WAYLAND_DISPLAY', 'DISPLAY', 'HYPRLAND_INSTANCE_SIGNATURE'):
                env.pop(key, None)
            with socket.socket(socket.AF_UNIX) as server:
                server.bind(env['GREETD_SOCK'])
                server.listen(1)
                server.settimeout(5)
                process = subprocess.Popen([quickshell, '--no-color', '-p', str(harness)],
                                           env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                           text=True)
                try:
                    connection, _ = server.accept()
                    with connection:
                        connection.settimeout(5)

                        def receive():
                            def exact(count):
                                data = b''
                                while len(data) < count:
                                    block = connection.recv(count - len(data))
                                    if not block:
                                        raise AssertionError('Unexpected greetd disconnect')
                                    data += block
                                return data
                            length = struct.unpack('=I', exact(4))[0]
                            self.assertLess(length, 65536)
                            return json.loads(exact(length))

                        def send(value):
                            data = json.dumps(value).encode()
                            connection.sendall(struct.pack('=I', len(data)) + data)

                        self.assertEqual(receive(), {'type': 'create_session', 'username': 'tess'})
                        if scenario == 'no-challenge':
                            send({'type': 'success'})
                        else:
                            send({'type': 'auth_message', 'auth_message_type':
                                  'visible' if scenario == 'visible' else 'secret',
                                  'auth_message': 'Synthetic test prompt'})
                            if scenario != 'visible':
                                self.assertEqual(receive(), {'type': 'post_auth_message_response',
                                                             'response': '0123'})
                                if scenario == 'failure':
                                    send({'type': 'error', 'error_type': 'auth_error',
                                          'description': 'Synthetic rejection'})
                                elif scenario == 'extra-secret':
                                    send({'type': 'auth_message', 'auth_message_type': 'secret',
                                          'auth_message': 'Unsupported second challenge'})
                                elif scenario == 'disconnect':
                                    connection.shutdown(socket.SHUT_RDWR)
                                else:
                                    send({'type': 'success'})
                        if scenario == 'success':
                            request = receive()
                            self.assertEqual(request['type'], 'start_session')
                            self.assertEqual(request['cmd'], ['/usr/bin/start-tessarchy'])
                            self.assertEqual(request.get('env', []), [])
                            send({'type': 'success'})
                        elif scenario in ('visible', 'no-challenge', 'extra-secret'):
                            self.assertEqual(receive(), {'type': 'cancel_session'})
                            send({'type': 'success'})
                        output, errors = process.communicate(timeout=8)
                        self.assertEqual(process.returncode, 0, output + errors)
                        self.assertNotIn('0123', output + errors)
                        self.assertNotIn('LOGIN_TEST_FAILED', output + errors)
                        if scenario == 'failure':
                            self.assertIn('LOGIN_REJECTION_MESSAGE_OK', output + errors)
                        if scenario != 'success':
                            self.assertIn('LOGIN_FAIL_CLOSED', output + errors)
                finally:
                    if process.poll() is None:
                        process.kill()
                        process.communicate()

    def test_successful_secret_challenge_launches_only_fixed_session(self):
        self.exchange('success')

    def test_auth_failure_never_launches(self):
        self.exchange('failure')

    def test_visible_prompt_does_not_receive_pin(self):
        self.exchange('visible')

    def test_second_secret_challenge_is_canceled(self):
        self.exchange('extra-secret')

    def test_passwordless_pam_success_is_not_accepted_as_pin_auth(self):
        self.exchange('no-challenge')

    def test_disconnect_clears_authentication_state(self):
        self.exchange('disconnect')

    def test_launcher_refuses_outside_greetd(self):
        env = dict(os.environ)
        env.pop('GREETD_SOCK', None)
        result = subprocess.run([str(ROOT / 'session/tessarchy-greeter')], env=env,
                                capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('through greetd', result.stderr)
