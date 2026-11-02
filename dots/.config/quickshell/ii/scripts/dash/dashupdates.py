#!/usr/bin/env python3
"""Backend del widget de actualizaciones (Arch/CachyOS).

- Repos oficiales: `checkupdates` (pacman-contrib). Usa una copia temporal de la base de datos,
  asi que NO toca la de pacman.
- AUR: `paru -Qua` o `yay -Qua`, el que exista.
El resultado se cachea en ~/.cache/ii-dash/updates.json y se refresca cada 30 min
(o con el comando `refresh` por stdin). Imprime un objeto JSON por linea (~cada 60 s).
"""
import json
import os
import shutil
import signal
import subprocess
import sys
import threading
import time
from datetime import datetime

INTERVAL = 30 * 60
RETRY = 5 * 60
CACHE = os.path.join(os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache"),
                     "ii-dash", "updates.json")
PACMAN_LOG = os.environ.get("PACMAN_LOG", "/var/log/pacman.log")
HELPER = next((h for h in ("paru", "yay") if shutil.which(h)), "")
UPDATE_CMD = [HELPER, "-Syu"] if HELPER else ["sudo", "pacman", "-Syu"]

force = threading.Event()
child = None


def needs_reboot(name):
    if name in ("systemd", "glibc", "linux", "linux-lts", "linux-zen", "linux-hardened"):
        return True
    return name.startswith("linux-cachyos") and not any(
        s in name for s in ("headers", "nvidia", "zfs", "docs"))


def run(cmd, timeout=120):
    global child
    try:
        child = subprocess.Popen(cmd, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE, text=True)
    except FileNotFoundError:
        return None, "", ""
    try:
        out, err = child.communicate(timeout=timeout)
        return child.returncode, out, err
    except subprocess.TimeoutExpired:
        child.kill()
        child.communicate()
        return -1, "", "timed out"
    finally:
        child = None


def parse(out):
    res = []
    for line in out.splitlines():
        p = line.split()
        if len(p) >= 4 and p[2] == "->":
            res.append({"n": p[0], "old": p[1], "new": p[3], "reboot": needs_reboot(p[0])})
    res.sort(key=lambda x: x["n"])
    return res


def check():
    st = {"ok": True, "err": "", "repo": [], "aur": [], "ts": time.time()}
    rc, out, err = run(["checkupdates"])
    if rc is None:
        st.update(ok=False, err="no_checkupdates")
        return st
    if rc == 0:
        st["repo"] = parse(out)
    elif rc != 2:  # 2 = sin actualizaciones; cualquier otro codigo = fallo
        first = next((l for l in err.splitlines() if l.strip()), "")
        st.update(ok=False, err="query_failed", detail=first)
    if HELPER and st["ok"]:
        _rc, out, _err = run([HELPER, "-Qua"])   # rc=1 cuando no hay nada: se ignora
        st["aur"] = parse(out)
    return st


def load_cache():
    try:
        with open(CACHE) as f:
            d = json.load(f)
        if isinstance(d, dict) and "ts" in d:
            return d
    except (OSError, ValueError):
        pass
    return {"ok": True, "err": "", "repo": [], "aur": [], "ts": 0}


def save_cache(st):
    try:
        os.makedirs(os.path.dirname(CACHE), exist_ok=True)
        with open(CACHE, "w") as f:
            json.dump(st, f)
    except OSError:
        pass


_lu = {"mtime": None, "val": 0}


def last_upgrade():
    """Fecha de la ultima actualizacion completa segun pacman.log (0 si no se encuentra)."""
    try:
        mtime = os.stat(PACMAN_LOG).st_mtime
        if mtime == _lu["mtime"]:
            return _lu["val"]
        with open(PACMAN_LOG, "rb") as f:
            f.seek(0, 2)
            f.seek(max(0, f.tell() - 2_000_000))
            data = f.read().decode(errors="ignore")
    except OSError:
        return 0
    val = 0
    idx = data.rfind("starting full system upgrade")
    if idx >= 0:
        ls = data.rfind("\n", 0, idx) + 1
        try:
            val = datetime.strptime(data[ls + 1:data.find("]", ls)], "%Y-%m-%dT%H:%M:%S%z").timestamp()
        except ValueError:
            val = 0
    _lu["mtime"], _lu["val"] = mtime, val
    return val


def emit(st, busy):
    print(json.dumps({**st, "busy": busy, "helper": HELPER, "updateCmd": UPDATE_CMD,
                      "lastUpgrade": last_upgrade()}), flush=True)


def stdin_loop():
    for line in sys.stdin:
        if line.strip() == "refresh":
            force.set()
    os._exit(0)


def on_term(*_):
    if child:
        child.terminate()
    os._exit(0)


def main():
    signal.signal(signal.SIGTERM, on_term)
    threading.Thread(target=stdin_loop, daemon=True).start()
    st = load_cache()
    while True:
        if time.time() - st.get("ts", 0) >= INTERVAL or force.is_set():
            force.clear()
            emit(st, True)
            st = check()
            if st["ok"] or not st["repo"]:
                save_cache(st)
        emit(st, False)
        due = (INTERVAL if st["ok"] else RETRY) - (time.time() - st["ts"])
        force.wait(min(60, max(5, due)))


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, BrokenPipeError):
        pass
