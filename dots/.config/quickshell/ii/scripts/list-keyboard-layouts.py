#!/usr/bin/env python3
"""Print the available XKB keyboard layouts as JSON: [{"displayName": "Turkish (tr)", "value": "tr"}, ...]."""

import json
import re

RULES = ("/usr/share/X11/xkb/rules/evdev.lst", "/usr/share/X11/xkb/rules/base.lst")


def main() -> int:
    layouts: list[dict] = []
    for path in RULES:
        try:
            lines = open(path, encoding="utf-8", errors="replace").read().splitlines()
        except OSError:
            continue
        in_section = False
        for line in lines:
            if line.startswith("!"):
                in_section = line.strip() == "! layout"
                continue
            if not in_section:
                continue
            m = re.match(r"^\s+(\S+)\s+(.+?)\s*$", line)
            if m and re.fullmatch(r"[a-z0-9_]+", m.group(1)):
                layouts.append({"displayName": f"{m.group(2)} — {m.group(1)}", "value": m.group(1)})
        if layouts:
            break
    layouts.sort(key=lambda x: x["displayName"].lower())
    print(json.dumps(layouts, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
