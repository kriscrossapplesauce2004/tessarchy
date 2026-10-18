#!/usr/bin/env python3
"""Report and control kernel radio switches without privilege escalation."""
import argparse
import json
import os
import shutil
import subprocess

TYPES = {"wifi": "wlan", "bluetooth": "bluetooth", "cellular": "wwan"}


def read_devices(run=subprocess.run):
    result = run(["rfkill", "--json", "--output", "ID,TYPE,DEVICE,SOFT,HARD"],
                 capture_output=True, text=True, timeout=5, check=True)
    devices = json.loads(result.stdout)["rfkilldevices"]
    if not isinstance(devices, list):
        raise ValueError("Invalid radio state")
    for device in devices:
        if not isinstance(device, dict) or device.get("soft") not in ("blocked", "unblocked") or device.get("hard") not in ("blocked", "unblocked"):
            raise ValueError("Invalid radio state")
    return devices


def describe(devices, writable):
    state = {"canControl": writable, "error": ""}
    for name, kind in TYPES.items():
        group = [device for device in devices if device.get("type") == kind]
        hard = bool(group) and all(device["hard"] == "blocked" for device in group)
        enabled = any(device["soft"] == "unblocked" and device["hard"] == "unblocked" for device in group)
        state[name] = {"available": bool(group), "enabled": enabled, "hardBlocked": hard,
                       "label": "Unavailable" if not group else "Hardware blocked" if hard else
                       "Permission needed" if not writable else "Radio on" if enabled else "Off"}
    state["airplane"] = {"available": bool(devices), "enabled": bool(devices) and
                         all(device["soft"] == "blocked" for device in devices),
                         "hardBlocked": False,
                         "label": "Unavailable" if not devices else "Permission needed" if not writable else
                         "On" if all(device["soft"] == "blocked" for device in devices) else "Off"}
    return state


def action_command(action, state):
    name = action.removeprefix("toggle-")
    if name not in (*TYPES, "airplane"):
        raise ValueError("Unknown radio control")
    radio = state[name]
    if not radio["available"]:
        raise ValueError("No supported radio is available")
    if not state["canControl"]:
        raise ValueError("Radio control permission is required")
    if radio["hardBlocked"]:
        raise ValueError("A hardware switch is blocking this radio")
    if name == "airplane":
        return ["rfkill", "unblock" if radio["enabled"] else "block", "all"]
    return ["rfkill", "block" if radio["enabled"] else "unblock", TYPES[name]]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["status", "toggle-airplane", "toggle-wifi", "toggle-bluetooth", "toggle-cellular"])
    args = parser.parse_args()
    devices, error = [], ""
    writable = os.access("/dev/rfkill", os.W_OK)
    try:
        if not shutil.which("rfkill"):
            raise ValueError("Radio service is unavailable")
        devices = read_devices()
        if args.action != "status":
            command = action_command(args.action, describe(devices, writable))
            subprocess.run(command, capture_output=True, text=True, timeout=5, check=True)
            devices = read_devices()  # A successful command is not proof of a state change.
    except (ValueError, KeyError, TypeError, OSError, subprocess.SubprocessError):
        error = "Radio state is unavailable" if args.action == "status" else "Could not change radio state. Check the device and radio permissions."
        # A failed bulk operation may still have changed some devices.
        if args.action != "status" and devices:
            try:
                devices = read_devices()
            except (ValueError, KeyError, TypeError, OSError, subprocess.SubprocessError):
                devices = []
                error = "Radio state is unavailable"
    state = describe(devices, writable)
    state["error"] = error
    print(json.dumps(state))


if __name__ == "__main__":
    main()
