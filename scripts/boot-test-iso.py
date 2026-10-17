#!/usr/bin/env python3
"""Capture a disposable, diskless QEMU ISO boot; screenshots need human review."""
import argparse
import json
from pathlib import Path
import shutil
import socket
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('iso', type=Path)
    parser.add_argument('output', type=Path, help='new directory; existing paths are refused')
    parser.add_argument('--firmware', choices=('bios', 'uefi'), default='bios')
    parser.add_argument('--accel', choices=('tcg', 'kvm'), default='tcg')
    parser.add_argument('--seconds', type=int, default=120)
    args = parser.parse_args()
    iso = args.iso.resolve(strict=True)
    if not iso.is_file() or not 30 <= args.seconds <= 600:
        parser.error('ISO must be a file and capture duration must be 30–600 seconds')
    if not shutil.which('qemu-system-x86_64'):
        parser.error('qemu-system-x86_64 is required; install it explicitly')
    from PIL import Image
    firmware = None
    if args.firmware == 'uefi':
        for code, variables in [
            ('/usr/share/OVMF/OVMF_CODE_4M.fd', '/usr/share/OVMF/OVMF_VARS_4M.fd'),
            ('/usr/share/edk2/x64/OVMF_CODE.4m.fd', '/usr/share/edk2/x64/OVMF_VARS.4m.fd')]:
            if Path(code).is_file() and Path(variables).is_file():
                firmware = (code, variables)
                break
        if firmware is None:
            parser.error('OVMF firmware is required for UEFI; install it explicitly')
    output = args.output.resolve()
    if ',' in str(output) or ',' in str(iso):
        parser.error('QEMU paths must not contain commas')
    output.mkdir(parents=True, exist_ok=False)
    qmp = output / 'qmp.sock'
    if len(str(qmp).encode()) >= 104:
        parser.error('output path is too long for the QMP Unix socket')
    command = [
        'qemu-system-x86_64', '-name', 'Tessarchy ISO boot capture',
        '-machine', 'q35', '-accel', args.accel, '-cpu', 'host' if args.accel == 'kvm' else 'max',
        '-m', '2048', '-smp', '2', '-device', 'virtio-vga',
        '-device', 'qemu-xhci', '-device', 'usb-tablet', '-display', 'none',
        '-qmp', 'unix:' + str(qmp) + ',server=on,wait=off',
        '-serial', 'file:' + str(output / 'serial.log'),
        '-cdrom', str(iso), '-boot', 'order=d', '-nic', 'none', '-no-reboot']
    if firmware:
        variables = output / 'OVMF_VARS.fd'
        shutil.copy2(firmware[1], variables)
        command += ['-drive', 'if=pflash,format=raw,readonly=on,file=' + firmware[0],
                    '-drive', 'if=pflash,format=raw,file=' + str(variables)]
    (output / 'command.json').write_text(json.dumps(command, indent=2) + '\n')
    with (output / 'qemu.log').open('wb') as log:
        process = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=log, stderr=log)
        try:
            for _ in range(100):
                if process.poll() is not None:
                    raise RuntimeError('QEMU exited during startup; see qemu.log')
                if qmp.exists():
                    break
                time.sleep(0.1)
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
                connection.settimeout(20)
                connection.connect(str(qmp))
                stream = connection.makefile('rwb')
                json.loads(stream.readline())

                def execute(name, arguments=None):
                    request = {'execute': name}
                    if arguments is not None:
                        request['arguments'] = arguments
                    stream.write((json.dumps(request) + '\n').encode())
                    stream.flush()
                    while True:
                        line = stream.readline()
                        if not line:
                            raise RuntimeError('QMP connection closed')
                        response = json.loads(line)
                        if 'error' in response:
                            raise RuntimeError(response['error'])
                        if 'return' in response:
                            return response['return']

                execute('qmp_capabilities')
                start = time.monotonic()
                time.sleep(3)
                execute('human-monitor-command', {'command-line': 'sendkey ret'})
                for second in sorted(set([10, 30, 60, args.seconds])):
                    if second > args.seconds:
                        continue
                    time.sleep(max(0, second - (time.monotonic() - start)))
                    # Wake a blanked panel so idle timeouts cannot hide the shell.
                    execute('human-monitor-command', {'command-line': 'sendkey ret'})
                    time.sleep(1)
                    name = 'final' if second == args.seconds else str(second)
                    ppm = output / (name + '.ppm')
                    execute('screendump', {'filename': str(ppm)})
                    with Image.open(ppm) as capture:
                        capture.save(output / (name + '.png'))
                    ppm.unlink()
                    print(f'{args.firmware}: captured {second}s', flush=True)
                (output / 'status.json').write_text(json.dumps(execute('query-status'), indent=2) + '\n')
                execute('quit')
        finally:
            if process.poll() is None:
                process.terminate()
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
            qmp.unlink(missing_ok=True)
    print('Capture complete; inspect screenshots before claiming boot success.', flush=True)


if __name__ == '__main__':
    main()
