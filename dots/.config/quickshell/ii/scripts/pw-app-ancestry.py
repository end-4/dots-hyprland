#!/usr/bin/env python3
"""Resolve PipeWire stream PIDs -> ancestor PIDs + Electron/app hint from /proc/<pid>/cmdline."""

import json
import os
import sys


def hint_for(pid: int) -> str:
    try:
        with open(f"/proc/{pid}/cmdline", "rb") as f:
            args = [a for a in f.read().split(b"\0") if a]
        s = [a.decode("utf-8", "ignore") for a in args]
    except Exception:
        return ""

    if "--type=" in " ".join(s):
        return ""

    for a in s:
        if a.startswith("--class=") or a.startswith("--app-id="):
            return a.split("=", 1)[1]
        if "app.asar" in a or a.endswith(".asar"):
            parts = [
                p for p in os.path.dirname(a).split("/")
                if p and p not in ("usr", "lib", "opt", "share", "resources", "app")
            ]
            if parts:
                return parts[-1]

    if s:
        first = s[0].split(" --", 1)[0].strip()
        b = os.path.basename(first)
        if b and not b.startswith(("electron", "python", "node", "bash", "sh")):
            return b

    return ""


def main() -> int:
    res = {}
    for p in sys.argv[1:]:
        try:
            pid = int(p)
        except ValueError:
            continue
        chain = [pid]
        q = pid
        h = ""
        for _ in range(8):
            h = hint_for(q) or h
            try:
                with open(f"/proc/{q}/stat", "r", encoding="utf-8", errors="ignore") as f:
                    ppid = int(f.read().split(")")[1].split()[1])
            except Exception:
                break
            if ppid <= 1:
                break
            chain.append(ppid)
            q = ppid
        res[str(pid)] = {"pids": chain, "hint": h}

    print(json.dumps(res), flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
