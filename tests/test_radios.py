"""Radio controls use reported hardware state, never optimistic UI flags."""
from pathlib import Path
import json
import subprocess
import types
import unittest
from unittest.mock import Mock

ROOT = Path(__file__).resolve().parents[1]
radios = types.ModuleType('test_radio_helper')
exec(compile((ROOT / 'shell/helpers/radios.py').read_text(), 'radios.py', 'exec'), radios.__dict__)


def device(kind, soft='unblocked', hard='unblocked'):
    return {'type': kind, 'soft': soft, 'hard': hard, 'id': 1, 'device': 'test-device'}


class RadioControls(unittest.TestCase):
    def test_absent_hardware_is_not_airplane_mode(self):
        state = radios.describe([], True)
        for name in ('wifi', 'bluetooth', 'cellular', 'airplane'):
            self.assertFalse(state[name]['available'])
            self.assertFalse(state[name]['enabled'])
        with self.assertRaises(ValueError):
            radios.action_command('toggle-airplane', state)

    def test_independent_radios_and_hardware_block(self):
        state = radios.describe([device('wlan'), device('bluetooth', 'blocked'),
                                 device('wwan', hard='blocked')], True)
        self.assertTrue(state['wifi']['enabled'])
        self.assertFalse(state['bluetooth']['enabled'])
        self.assertEqual(state['cellular']['label'], 'Hardware blocked')
        self.assertFalse(state['airplane']['enabled'])
        with self.assertRaises(ValueError):
            radios.action_command('toggle-cellular', state)

    def test_airplane_switches_all_and_reports_external_changes(self):
        state = radios.describe([device('wlan'), device('bluetooth', 'blocked')], True)
        self.assertEqual(radios.action_command('toggle-airplane', state), ['rfkill', 'block', 'all'])
        blocked = radios.describe([device('wlan', 'blocked'), device('bluetooth', 'blocked')], True)
        self.assertTrue(blocked['airplane']['enabled'])
        self.assertEqual(radios.action_command('toggle-airplane', blocked), ['rfkill', 'unblock', 'all'])
        self.assertEqual(radios.action_command('toggle-wifi', blocked), ['rfkill', 'unblock', 'wlan'])

    def test_no_privilege_escalation_or_arbitrary_commands(self):
        state = radios.describe([device('wlan')], False)
        self.assertEqual(state['wifi']['label'], 'Permission needed')
        with self.assertRaises(ValueError):
            radios.action_command('toggle-wifi', state)
        with self.assertRaises(ValueError):
            radios.action_command('toggle-wifi; reboot', radios.describe([device('wlan')], True))

    def test_explicit_json_columns_and_invalid_state_refused(self):
        run = Mock(return_value=subprocess.CompletedProcess([], 0, json.dumps({'rfkilldevices': [device('wlan')]})))
        self.assertEqual(radios.read_devices(run), [device('wlan')])
        self.assertEqual(run.call_args.args[0], ['rfkill', '--json', '--output', 'ID,TYPE,DEVICE,SOFT,HARD'])
        run.return_value.stdout = '{"rfkilldevices":[{"soft":"unknown","hard":"unblocked"}]}'
        with self.assertRaises(ValueError):
            radios.read_devices(run)

    def test_failed_bulk_action_refreshes_partial_hardware_changes(self):
        from contextlib import redirect_stdout
        from io import StringIO
        from unittest.mock import patch
        before = [device('wlan'), device('bluetooth')]
        after = [device('wlan', 'blocked'), device('bluetooth')]
        output = StringIO()
        with patch.object(radios, 'read_devices', side_effect=[before, after]), \
             patch.object(radios.os, 'access', return_value=True), \
             patch.object(radios.shutil, 'which', return_value='/usr/bin/rfkill'), \
             patch.object(radios.subprocess, 'run', side_effect=subprocess.CalledProcessError(1, 'rfkill')), \
             patch('sys.argv', ['radios.py', 'toggle-airplane']), redirect_stdout(output):
            radios.main()
        state = json.loads(output.getvalue())
        self.assertFalse(state['wifi']['enabled'])
        self.assertTrue(state['bluetooth']['enabled'])
        self.assertFalse(state['airplane']['enabled'])
        self.assertTrue(state['error'])
