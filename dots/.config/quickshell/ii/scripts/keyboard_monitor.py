#!/usr/bin/env python3
"""Monitor physical keyboard events via evdev and output JSON lines to stdout."""

import glob
import json
import os
import select
import struct
import sys

# Linux input event format: struct input_event { timeval time; __u16 type; __u16 code; __s32 value; }
# On 64-bit: timeval is 16 bytes (tv_sec: 8, tv_usec: 8), total = 24 bytes
EVENT_FORMAT = "llHHI"
EVENT_SIZE = struct.calcsize(EVENT_FORMAT)
EV_KEY = 1


def find_keyboard_devices():
    """Find keyboard event devices via /dev/input/by-path."""
    seen = set()
    devices = []
    for path in sorted(glob.glob("/dev/input/by-path/*-event-kbd")):
        real = os.path.realpath(path)
        if real not in seen:
            seen.add(real)
            devices.append(real)
    return devices


def emit(obj):
    sys.stdout.write(json.dumps(obj) + "\n")
    sys.stdout.flush()


def main():
    devices = find_keyboard_devices()
    if not devices:
        emit({"error": "No keyboard devices found"})
        return 1

    fds = {}
    for dev_path in devices:
        try:
            fd = os.open(dev_path, os.O_RDONLY | os.O_NONBLOCK)
            fds[fd] = dev_path
        except PermissionError:
            emit({"error": f"Permission denied: {dev_path}"})

    if not fds:
        emit({"error": "Could not open any keyboard devices"})
        return 1

    emit({"status": "ready", "devices": list(fds.values())})

    try:
        while True:
            readable, _, _ = select.select(list(fds.keys()), [], [])
            for fd in readable:
                try:
                    data = os.read(fd, EVENT_SIZE * 64)
                    for offset in range(0, len(data), EVENT_SIZE):
                        chunk = data[offset : offset + EVENT_SIZE]
                        if len(chunk) < EVENT_SIZE:
                            break
                        _, _, ev_type, code, value = struct.unpack(EVENT_FORMAT, chunk)
                        # value: 0=release, 1=press, 2=repeat (we ignore repeat)
                        if ev_type == EV_KEY and value in (0, 1):
                            emit({"keycode": code, "pressed": value == 1})
                except BlockingIOError:
                    pass
    except KeyboardInterrupt:
        pass
    finally:
        for fd in fds:
            os.close(fd)
    return 0


if __name__ == "__main__":
    sys.exit(main())
