#!/usr/bin/env python3
"""Dynamically fetch live models & slash commands from `claude` or `codex` CLI."""

import json
import os
import pathlib
import re
import shutil
import subprocess
import sys


def fetch_claude() -> dict:
    bin_path = shutil.which("claude")
    if not bin_path:
        return {"installed": False, "models": [], "commands": []}

    # Check login status via `claude auth status` (returns JSON with {"loggedIn": bool})
    logged_in = True
    try:
        auth_res = subprocess.run([bin_path, "auth", "status"], capture_output=True, text=True, timeout=5, check=False)
        auth_data = json.loads(auth_res.stdout or "{}")
        if "loggedIn" in auth_data:
            logged_in = bool(auth_data["loggedIn"])
        elif auth_res.returncode != 0:
            logged_in = False
    except Exception:
        pass

    # Query claude init event (no LLM turn needed when passing /help or reading init)
    res = subprocess.run(
        [bin_path, "-p", "/help", "--output-format", "stream-json", "--verbose"],
        capture_output=True,
        text=True,
        timeout=12,
        check=False,
    )
    init_ev = {}
    for line in res.stdout.splitlines():
        line = line.strip()
        if not line.startswith("{"):
            continue
        try:
            ev = json.loads(line)
        except json.JSONDecodeError:
            continue
        if ev.get("type") == "system" and ev.get("subtype") == "init":
            init_ev = ev
            break

    default_model = init_ev.get("model", "")
    raw_cmds = init_ev.get("slash_commands", [])
    commands = []
    seen = set()
    for name in raw_cmds:
        if not name or name.startswith("__") or name in seen:
            continue
        seen.add(name)
        commands.append({
            "name": "/" + name,
            "description": "",
            "instant": name in ("model", "effort", "clear", "compact", "help", "usage", "credits", "doctor", "agents"),
        })
    for extra in (
        {"name": "/login", "description": "Sign in / authenticate Claude CLI", "instant": True},
        {"name": "/clear", "description": "Start a new conversation", "instant": True},
    ):
        if extra["name"] not in seen and extra["name"].lstrip("/") not in seen:
            commands.append(extra)

    # Resolve actual claude binary (follow shell wrappers like /usr/bin/claude -> /opt/claude-code/bin/claude)
    real_bin = pathlib.Path(bin_path).resolve()
    try:
        head = real_bin.read_bytes()[:512]
        if head.startswith(b"#!"):
            m_exec = re.search(rb'exec\s+([^\s"\']+)', head)
            if m_exec:
                cand = pathlib.Path(m_exec.group(1).decode("utf-8", "ignore"))
                if cand.exists():
                    real_bin = cand.resolve()
    except OSError:
        pass

    # Extract all (family, major, minor) models directly from installed binary, sorted newest first
    found = {}
    try:
        raw = real_bin.read_bytes()
        for fam_b, maj_b, min_b in re.findall(rb"claude-(fable|opus|sonnet|haiku)-(\d+)-(\d+)(?!\d)", raw):
            fam = fam_b.decode()
            ver = (int(maj_b), int(min_b))
            if len(str(ver[0])) > 2 or len(str(ver[1])) > 2:
                continue
            mid = f"claude-{fam}-{ver[0]}-{ver[1]}"
            found[mid] = (fam, ver)
    except OSError:
        pass

    fam_order = {"sonnet": 0, "opus": 1, "fable": 2, "haiku": 3}
    sorted_items = sorted(
        found.items(),
        key=lambda kv: (-kv[1][1][0], -kv[1][1][1], fam_order.get(kv[1][0], 9)),
    )
    models = []
    for mid, (fam, ver) in sorted_items:
        if ver[0] < 4:
            continue
        label = f"Claude {fam.capitalize()} {ver[0]}.{ver[1]}"
        models.append({"id": mid, "name": label, "efforts": [] if fam == "haiku" else ["low", "medium", "high", "max"]})

    if not models:
        for fam in ("opus", "sonnet", "fable", "haiku"):
            models.append({"id": fam, "name": f"Claude {fam.capitalize()}", "efforts": [] if fam == "haiku" else ["low", "medium", "high", "max"]})

    return {"installed": True, "loggedIn": logged_in, "defaultModel": default_model or models[0]["id"], "models": models, "commands": commands}


def fetch_codex() -> dict:
    bin_path = shutil.which("codex")
    if not bin_path:
        return {"installed": False, "models": [], "commands": []}

    # Check login status
    login_res = subprocess.run([bin_path, "login", "status"], capture_output=True, text=True, timeout=5, check=False)
    logged_in = login_res.returncode == 0 and "not logged in" not in (login_res.stdout + login_res.stderr).lower()

    # Read configured model from ~/.codex/config.toml if present
    cfg_path = pathlib.Path.home() / ".codex/config.toml"
    default_model = ""
    if cfg_path.exists():
        m = re.search(r'^model\s*=\s*"([^"]+)"', cfg_path.read_text(encoding="utf-8", errors="ignore"), re.M)
        if m:
            default_model = m.group(1)

    models = []
    if default_model:
        models.append({"id": default_model, "name": default_model, "efforts": ["low", "medium", "high"]})

    # Check codex cache/models if available
    models_cache = pathlib.Path.home() / ".codex/models_cache.json"
    if models_cache.exists():
        try:
            data = json.loads(models_cache.read_text(encoding="utf-8"))
            for item in data.get("models", []):
                slug = item.get("slug") or item.get("id")
                if slug and not any(m["id"] == slug for m in models):
                    models.append({"id": slug, "name": item.get("display_name") or slug, "efforts": ["low", "medium", "high"]})
        except Exception:
            pass

    # Fallback: extract model IDs directly from installed codex binary
    if not models:
        try:
            raw = pathlib.Path(bin_path).resolve().read_bytes()
            slugs = sorted(
                {m.decode() for m in re.findall(rb"gpt-5\.[0-9]+(?:-(?:codex(?:-(?:mini|max))?|luna|sol|terra))?(?![A-Za-z0-9_.-])", raw)},
                reverse=True,
            )
            for slug in slugs:
                if not any(m["id"] == slug for m in models):
                    models.append({"id": slug, "name": slug, "efforts": ["low", "medium", "high"]})
        except OSError:
            pass

    commands = [
        {"name": "/model", "description": "Select model & reasoning effort", "instant": True},
        {"name": "/effort", "description": "Set reasoning effort", "instant": True},
        {"name": "/login", "description": "Sign in / authenticate Codex CLI", "instant": True},
        {"name": "/clear", "description": "Start a new conversation", "instant": True},
    ]
    return {"installed": True, "loggedIn": logged_in, "defaultModel": default_model or (models[0]["id"] if models else ""), "models": models, "commands": commands}


def main() -> int:
    if len(sys.argv) < 2:
        return 2
    backend = sys.argv[1]
    if backend == "claude":
        print(json.dumps(fetch_claude(), ensure_ascii=False))
    elif backend == "codex":
        print(json.dumps(fetch_codex(), ensure_ascii=False))
    else:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
