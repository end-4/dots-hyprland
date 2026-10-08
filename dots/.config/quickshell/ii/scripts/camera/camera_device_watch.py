#!/usr/bin/env python3
import ctypes
import ctypes.util
import glob
import os
import select
import signal
import struct
import sys
import time

PR_SET_PDEATHSIG = 1
IN_NONBLOCK = 0o4000
IN_ATTRIB = 0x00000004
IN_CLOSE_WRITE = 0x00000008
IN_CLOSE_NOWRITE = 0x00000010
IN_OPEN = 0x00000020
IN_CREATE = 0x00000100
IN_DELETE = 0x00000200
IN_IGNORED = 0x00008000
WATCH_MASK = IN_OPEN | IN_CLOSE_WRITE | IN_CLOSE_NOWRITE | IN_ATTRIB
DEBOUNCE_S = 0.4
VERIFY_S = 3.0

MEDIA_STACK = ("pipewire", "pulseaudio", "wireplumber")

libc = ctypes.CDLL(ctypes.util.find_library("c") or "libc.so.6", use_errno=True)
libc.prctl(PR_SET_PDEATHSIG, signal.SIGTERM)
if os.getppid() == 1:
    sys.exit(0)

fd = libc.inotify_init1(IN_NONBLOCK)
if fd < 0:
    raise OSError(ctypes.get_errno(), "inotify_init1 failed")

dev_wd = libc.inotify_add_watch(fd, b"/dev", IN_CREATE | IN_DELETE)
if dev_wd < 0:
    raise OSError(ctypes.get_errno(), "inotify_add_watch /dev failed")

devices = {}


def watch_all() -> None:
    watched = set(devices.values())
    for path in sorted(glob.glob("/dev/video*")):
        if path in watched:
            continue
        wd = libc.inotify_add_watch(fd, path.encode(), WATCH_MASK)
        if wd >= 0:
            devices[wd] = path


def forget(path: str) -> None:
    for wd in [wd for wd, watched in devices.items() if watched == path]:
        del devices[wd]


def users() -> dict:
    out = {}
    for pid in os.listdir("/proc"):
        if not pid.isdigit():
            continue
        try:
            with open(f"/proc/{pid}/comm") as f:
                comm = f.read().strip()
            if comm.startswith(MEDIA_STACK):
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


def read_events() -> None:
    try:
        data = os.read(fd, 8192)
    except BlockingIOError:
        return
    off = 0
    while off < len(data):
        wd, mask, _cookie, length = struct.unpack_from("iIII", data, off)
        off += 16 + length
        name = data[off - length:off].split(b"\0")[0].decode(errors="replace")
        if mask & IN_IGNORED:
            devices.pop(wd, None)
        elif wd == dev_wd and name.startswith("video"):
            if mask & IN_DELETE:
                forget(f"/dev/{name}")
            watch_all()


watch_all()
previous = users()
report(previous, {})
print("READY", flush=True)

poll = select.poll()
poll.register(fd, select.POLLIN)
last_scan = time.monotonic()
pending = False
next_verify = last_scan + VERIFY_S

while True:
    deadlines = []
    if pending:
        deadlines.append(last_scan + DEBOUNCE_S)
    if previous:
        deadlines.append(next_verify)
    timeout_ms = -1
    if deadlines:
        timeout_ms = max(0, int((min(deadlines) - time.monotonic()) * 1000) + 1)

    if poll.poll(timeout_ms):
        read_events()
        pending = True

    now = time.monotonic()
    if pending and now - last_scan >= DEBOUNCE_S:
        last_scan = now
        next_verify = now + VERIFY_S
        pending = False
        current = users()
        report(current, previous)
        previous = current
        continue

    if previous and now >= next_verify:
        last_scan = now
        next_verify = now + VERIFY_S
        if still_held(previous) != previous:
            current = users()
            report(current, previous)
            previous = current
