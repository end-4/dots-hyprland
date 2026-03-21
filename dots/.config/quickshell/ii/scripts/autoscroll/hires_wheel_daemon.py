#!/usr/bin/env python3
import argparse
import fcntl
import os
import signal
import sys
import time

from evdev import UInput, ecodes


RUNNING = True


def on_term(signum, frame):
    global RUNNING
    RUNNING = False


def read_velocity(path: str) -> float:
    try:
        with open(path, "r", encoding="utf-8") as f:
            raw = f.read().strip()
        if not raw:
            return 0.0
        return float(raw)
    except Exception:
        return 0.0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--state-file", required=True)
    parser.add_argument("--loop-ms", type=float, default=1.0)
    parser.add_argument("--hires-per-line", type=float, default=120.0)
    args = parser.parse_args()

    os.makedirs(os.path.dirname(args.state_file), exist_ok=True)
    lock_path = f"{args.state_file}.lock"
    lock_file = open(lock_path, "w", encoding="utf-8")
    try:
        fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        return 0

    signal.signal(signal.SIGTERM, on_term)
    signal.signal(signal.SIGINT, on_term)

    capabilities = {
        ecodes.EV_REL: [ecodes.REL_WHEEL, ecodes.REL_WHEEL_HI_RES],
    }
    ui = UInput(capabilities, name="qs-autoscroll-hires", version=0x1)

    hires_acc = 0.0
    detent_acc = 0.0
    dt = max(0.0005, args.loop_ms / 1000.0)

    try:
        while RUNNING:
            velocity = read_velocity(args.state_file)

            hires_acc += velocity * args.hires_per_line * dt
            hires_whole = int(hires_acc)
            hires_acc -= hires_whole

            if hires_whole != 0:
                ui.write(ecodes.EV_REL, ecodes.REL_WHEEL_HI_RES, hires_whole)

                detent_acc += hires_whole / 120.0
                detent_whole = int(detent_acc)
                detent_acc -= detent_whole
                if detent_whole != 0:
                    ui.write(ecodes.EV_REL, ecodes.REL_WHEEL, detent_whole)

                ui.syn()

            time.sleep(dt)
    finally:
        ui.close()

    return 0


if __name__ == "__main__":
    sys.exit(main())
