#!/usr/bin/env python3
import ctypes
import glob
import os
import select
import signal
import struct
import sys
import time

PR_SET_PDEATHSIG = 1
IN_ATTRIB = 0x00000004
IN_CLOSE_WRITE = 0x00000008
IN_OPEN = 0x00000020
IN_CREATE = 0x00000100
IN_DELETE = 0x00000200
WATCH_MASK = IN_OPEN | IN_CLOSE_WRITE | IN_ATTRIB
DEBOUNCE_MS = 400
VERIFY_S = 3.0

MEDIA_STACK = ("pipewire", "pulseaudio", "wireplumber")

libc = ctypes.CDLL("libc.so.6", use_errno=True)
libc.prctl(PR_SET_PDEATHSIG, signal.SIGTERM)
if os.getppid() == 1:
    sys.exit(0)

fd = libc.inotify_init1(0o4000)
if fd < 0:
    raise OSError(ctypes.get_errno(), "inotify_init1 failed")

devices = {}
libc.inotify_add_watch(fd, b"/dev", IN_CREATE | IN_DELETE)

def watch_all() -> None:
    for path in sorted(glob.glob("/dev/video*")):
        if path not in [d for d in devices.values()]:
            wd = libc.inotify_add_watch(fd, path.encode(), WATCH_MASK)
            if wd >= 0:
                devices[wd] = path

def users() -> dict:
    out = {}
    for pid in os.listdir("/proc"):
        if not pid.isdigit():
            continue
        try:
            with open(f"/proc/{pid}/comm") as f:
                comm = f.read().strip()
            if comm in MEDIA_STACK:
                continue
            for entry in glob.glob(f"/proc/{pid}/fd/*"):
                target = os.readlink(entry)
                if target.startswith("/dev/video"):
                    out.setdefault(os.path.realpath(target), (comm, pid))
                    break
        except OSError:
            continue
    return out

def still_held(known: dict) -> dict:
    alive = {}
    for device, (comm, pid) in known.items():
        try:
            for entry in glob.glob(f"/proc/{pid}/fd/*"):
                if os.readlink(entry) == device:
                    alive[device] = (comm, pid)
                    break
        except OSError:
            continue
    return alive

def report(current: dict, previous: dict) -> None:
    for device, (name, _pid) in sorted(current.items()):
        if previous.get(device, ("",))[0] != name:
            print(f"CAPTURE {device} {name}", flush=True)
    for device in sorted(set(previous) - set(current)):
        print(f"RELEASE {device}", flush=True)

watch_all()
previous = users()
report(previous, {})

poll = select.poll()
poll.register(fd, select.POLLIN)
last_scan = time.monotonic()
pending = False
next_verify = last_scan + VERIFY_S

while True:
    timeout = -1
    if pending:
        timeout = max(0.0, last_scan + DEBOUNCE_MS / 1000 - time.monotonic())
    if previous:
        timeout = max(0.0, min([t for t in (timeout, next_verify - time.monotonic()) if t >= 0], default=0.0))
    for _ in poll.poll(timeout):
        data = os.read(fd, 8192)
        off = 0
        while off < len(data):
            _wd, _mask, _cookie, length = struct.unpack_from("iIII", data, off)
            off += 16 + length
            name = data[off - length:off].split(b"\0")[0].decode(errors="replace")
            if name.startswith("video"):
                watch_all()
        pending = True

    now = time.monotonic()
    if pending and (now - last_scan) * 1000 >= DEBOUNCE_MS:
        last_scan = now
        next_verify = last_scan + VERIFY_S
        pending = False
        current = users()
        report(current, previous)
        previous = current
        continue

    if previous and now >= next_verify:
        last_scan = now
        next_verify = last_scan + VERIFY_S
        current = still_held(previous)
        if current != previous:
            current = users()
            report(current, previous)
            previous = current
