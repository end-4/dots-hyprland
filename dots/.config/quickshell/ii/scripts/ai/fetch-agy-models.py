#!/usr/bin/env python3
"""Fetch available models from `agy models` and group effort variants for Quickshell Ai.qml."""

import json
import os
import re
import subprocess
import sys
import tempfile

EFFORT_ORDER = {"Low": 0, "Medium": 1, "High": 2, "XHigh": 3, "Max": 4}
ANSI_RE = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]|\r")
LINE_RE = re.compile(r"^([a-z0-9._-]+)\s+(.+?)\s*$")
EFFORT_RE = re.compile(r"^(.*?)\s+\((Low|Medium|High|XHigh|Max)\)$")


def main() -> int:
    agy_bin = os.path.expanduser("~/.local/bin/agy")
    if not os.path.exists(agy_bin):
        agy_bin = "agy"

    env = dict(os.environ)
    env["BROWSER"] = "true"
    try:
        with tempfile.TemporaryDirectory() as tmpbin:
            noop = os.path.join(tmpbin, "xdg-open")
            with open(noop, "w", encoding="utf-8") as f:
                f.write("#!/bin/sh\nexit 0\n")
            os.chmod(noop, 0o755)
            env["PATH"] = f"{tmpbin}:{env.get('PATH', '')}"
            res = subprocess.run(
                [agy_bin, "models"],
                capture_output=True,
                text=True,
                stdin=subprocess.DEVNULL,
                timeout=8,
                env=env,
                check=False,
            )
    except subprocess.TimeoutExpired:
        print(json.dumps({"loggedIn": False, "models": [], "families": []}))
        return 0
    cleaned = ANSI_RE.sub("\n", res.stdout)

    models = []
    families_map = {}

    for raw_line in cleaned.splitlines():
        line = raw_line.strip()
        m = LINE_RE.match(line)
        if not m:
            continue
        mid, display = m.group(1), m.group(2)
        em = EFFORT_RE.match(display)
        if em:
            family_name, effort = em.group(1), em.group(2)
        else:
            family_name, effort = display, ""

        models.append({
            "id": mid,
            "name": display,
            "family": family_name,
            "effort": effort,
        })
        if family_name not in families_map:
            families_map[family_name] = []
        families_map[family_name].append({
            "id": mid,
            "name": display,
            "effort": effort,
        })

    families = []
    for fname, variants in families_map.items():
        if len(variants) > 1 and all(v["effort"] for v in variants):
            variants.sort(key=lambda v: EFFORT_ORDER.get(v["effort"], 99))
            efforts = [{"label": v["effort"], "id": v["id"]} for v in variants]
            default_v = next((v for v in variants if v["effort"] == "Medium"), variants[0])
            families.append({
                "name": fname,
                "defaultId": default_v["id"],
                "efforts": efforts,
            })
        else:
            families.append({
                "name": variants[0]["name"],
                "defaultId": variants[0]["id"],
                "efforts": [],
            })

    print(json.dumps({"models": models, "families": families}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
