#!/usr/bin/env bash

if ! command -v openrgb >/dev/null 2>&1; then
    printf '{"ok":false,"error":"openrgb not installed"}\n'
    exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
    printf '{"ok":false,"error":"python3 not installed"}\n'
    exit 0
fi

list_output=$(openrgb --list-devices 2>/dev/null || true)

if [[ -z "$list_output" ]]; then
    printf '{"ok":false,"error":"OpenRGB returned no devices"}\n'
    exit 0
fi

json_output=$(printf '%s\n' "$list_output" | python3 -c '
import json
import re
import sys

devices = []
for line in sys.stdin:
    match = re.match(r"^(\d+):\s*(.+)$", line.strip())
    if match:
        devices.append({
            "id": int(match.group(1)),
            "name": match.group(2),
        })

print(json.dumps({"ok": True, "devices": devices}))
')

printf '%s\n' "$json_output"
