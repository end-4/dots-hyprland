#!/usr/bin/env python3
"""Read and update Antigravity CLI (~/.gemini/antigravity-cli/settings.json) settings."""

import json
import os
import pathlib
import subprocess
import sys

SETTINGS_PATH = pathlib.Path.home() / ".gemini/antigravity-cli/settings.json"

ENUMS = {
    "agentMode": ["auto", "plan", "accept-edits"],
    "toolPermission": ["always-proceed", "ask", "read-only"],
    "verbosity": ["low", "medium", "high"],
    "artifactReviewPolicy": ["asks-for-review", "always-proceed", "never"],
    "editorMode": ["default", "vim"],
    "queuedMessages": ["queue", "interrupt"],
    "runningLightSpeed": ["slow", "medium", "fast"],
}


def cmd_get() -> int:
    agy_bin = os.path.expanduser("~/.local/bin/agy")
    if not os.path.exists(agy_bin):
        agy_bin = "agy"

    cfg = {}
    res = subprocess.run([agy_bin, "-p", "/config", "--output-format", "stream-json"], capture_output=True, text=True, check=False)
    for line in res.stdout.splitlines():
        if not line.strip().startswith("{"):
            continue
        try:
            ev = json.loads(line)
        except json.JSONDecodeError:
            continue
        if ev.get("event") == "command_result":
            cfg = ev.get("command", {}).get("data", {}).get("config", {}) or {}
            break

    if not cfg and SETTINGS_PATH.exists():
        cfg = json.loads(SETTINGS_PATH.read_text(encoding="utf-8"))

    items = []
    for key in sorted(cfg.keys()):
        val = cfg[key]
        if val is None or val == "":
            continue
        if isinstance(val, bool):
            items.append({"key": key, "value": val, "kind": "bool", "options": [True, False]})
        elif key in ENUMS:
            items.append({"key": key, "value": val, "kind": "enum", "options": ENUMS[key]})
        elif isinstance(val, (str, int, float)):
            items.append({"key": key, "value": str(val), "kind": "readonly", "options": []})

    print(json.dumps(items, ensure_ascii=False))
    return 0


def cmd_set(key: str, raw_val: str) -> int:
    data = {}
    if SETTINGS_PATH.exists():
        try:
            data = json.loads(SETTINGS_PATH.read_text(encoding="utf-8"))
        except Exception:
            data = {}
    data[key] = json.loads(raw_val)
    SETTINGS_PATH.parent.mkdir(parents=True, exist_ok=True)
    SETTINGS_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return 0


def main() -> int:
    if len(sys.argv) >= 2 and sys.argv[1] == "get":
        return cmd_get()
    if len(sys.argv) >= 4 and sys.argv[1] == "set":
        return cmd_set(sys.argv[2], sys.argv[3])
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
