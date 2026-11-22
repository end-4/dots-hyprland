#!/usr/bin/env python3
"""Fetch live slash commands directly from `agy -p /help --output-format stream-json`."""

import json
import os
import subprocess
import tempfile


def main() -> int:
    agy_bin = os.path.expanduser("~/.local/bin/agy")
    if not os.path.exists(agy_bin):
        agy_bin = "agy"

    env = dict(os.environ)
    env["BROWSER"] = "true"
    stdout = ""
    try:
        with tempfile.TemporaryDirectory() as tmpbin:
            noop = os.path.join(tmpbin, "xdg-open")
            with open(noop, "w", encoding="utf-8") as f:
                f.write("#!/bin/sh\nexit 0\n")
            os.chmod(noop, 0o755)
            env["PATH"] = f"{tmpbin}:{env.get('PATH', '')}"
            res = subprocess.run(
                [agy_bin, "-p", "/help", "--output-format", "stream-json"],
                capture_output=True,
                text=True,
                stdin=subprocess.DEVNULL,
                timeout=8,
                env=env,
                check=False,
            )
            stdout = res.stdout
    except subprocess.TimeoutExpired:
        stdout = ""

    commands = []
    seen = set()
    for line in stdout.splitlines():
        line = line.strip()
        if not line.startswith("{"):
            continue
        try:
            ev = json.loads(line)
        except json.JSONDecodeError:
            continue
        if ev.get("event") == "command_result":
            raw_cmds = ev.get("command", {}).get("data", {}).get("commands", [])
            for c in raw_cmds:
                name = c.get("name", "")
                if not name or name in seen:
                    continue
                seen.add(name)
                commands.append({
                    "name": name,
                    "description": c.get("description", ""),
                    "instant": name in ("model", "effort", "config", "help", "usage", "credits", "agents", "skills", "changelog"),
                })

    # Sidebar-specific helpers (login in terminal, clear local conversation)
    for extra in (
        {"name": "login", "description": "Sign in / authenticate Antigravity CLI", "instant": True},
        {"name": "clear", "description": "Start a new conversation", "instant": True},
    ):
        if extra["name"] not in seen:
            commands.append(extra)

    print(json.dumps(commands, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
