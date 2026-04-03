#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
from pathlib import Path


CHOICE_INPUTS = {
    "allow_once": "1\n",
    "allow_session": "2\n",
    "deny_suggest_changes": "3\n",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Send an Orbitbar choice back to a terminal session")
    parser.add_argument("--pid", required=True, type=int)
    parser.add_argument("--choice-id", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    payload = CHOICE_INPUTS.get(args.choice_id)
    if payload is None:
        raise SystemExit(f"Unknown choice id: {args.choice_id}")

    tty_path = Path(os.readlink(f"/proc/{args.pid}/fd/0"))
    if not tty_path.exists():
        raise SystemExit(f"TTY path does not exist: {tty_path}")

    fd = os.open(str(tty_path), os.O_WRONLY | os.O_NONBLOCK)
    try:
        os.write(fd, payload.encode("utf-8"))
    finally:
        os.close(fd)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
