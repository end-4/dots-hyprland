#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess


def run_hyprctl(*args: str) -> str:
    proc = subprocess.run(["hyprctl", *args], check=True, capture_output=True, text=True)
    return proc.stdout


def dispatch(command: str) -> None:
    subprocess.run(["hyprctl", "dispatch", *command.split(" ", 1)], check=True)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Focus an Orbitbar agent terminal in Hyprland")
    parser.add_argument("--address", required=True)
    parser.add_argument("--special-name", default="agents")
    parser.add_argument("--move-to-special", action="store_true")
    parser.add_argument("--show-special", action="store_true")
    parser.add_argument("--focus", action="store_true")
    return parser.parse_args()


def special_visible(name: str) -> bool:
    monitors = json.loads(run_hyprctl("monitors", "-j"))
    target = f"special:{name}"
    return any((monitor.get("specialWorkspace") or {}).get("name") == target for monitor in monitors)


def main() -> int:
    args = parse_args()
    address = args.address

    if args.move_to_special:
        subprocess.run(
            [
                "hyprctl",
                "dispatch",
                "movetoworkspacesilent",
                f"special:{args.special_name},address:{address}",
            ],
            check=True,
        )

    if args.show_special and not special_visible(args.special_name):
        subprocess.run(
            ["hyprctl", "dispatch", "togglespecialworkspace", args.special_name],
            check=True,
        )

    if args.focus:
        subprocess.run(["hyprctl", "dispatch", "focuswindow", f"address:{address}"], check=True)
    elif args.move_to_special:
        # Keep the existing one-shot CLI behavior working for callers that only request move.
        subprocess.run(["hyprctl", "dispatch", "focuswindow", f"address:{address}"], check=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
