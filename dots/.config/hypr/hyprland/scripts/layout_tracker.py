#!/usr/bin/env python3
# Adapted from tak0-layout, the original project:
#   https://github.com/tak0dan/QoL-Script-For-Hyprland-By-Tak00/tree/main/layout-tracker
# Optional. Enable it from ~/.config/hypr/custom/execs.lua (see the example there).
"""
layout_tracker: per-window keyboard layouts for Hyprland that learn how you type.

  layout_tracker.py daemon        run the tracker (started from custom/execs.lua)
  layout_tracker.py toggle        switch to the next layout (bind this to your layout key)
  layout_tracker.py stats [APP]   show how much each layout is used, globally or per app
  layout_tracker.py status        show the current layout and where the data lives
  layout_tracker.py forget APP    drop the saved statistics of one app

What the daemon does
  * Every window remembers its own layout; focusing it restores that layout.
  * Time spent in each layout is counted per app (window class) and globally,
    along with how many times each layout was used. Counts decay with a
    half-life (14 days by default) so recent habits weigh more.
  * A newly opened window starts in the layout you most often use in that app.
    With too little data for the app it falls back to your global favourite.
  * Statistics of layouts that are no longer configured in Hyprland are kept.
    Add the layout back later and its history is still there.
  * Percentages are written to stats.json every few seconds while you work.

Only Python 3 and hyprctl are needed.
"""
import argparse
import fcntl
import json
import os
import select
import signal
import socket
import subprocess
import sys
import time
from pathlib import Path

HALF_LIFE_DAYS = float(os.environ.get("TAK0_LAYOUT_HALF_LIFE_DAYS", "14"))
MIN_APP_SECONDS = float(os.environ.get("TAK0_LAYOUT_MIN_SECONDS", "60"))
TICK = 5.0       # seconds between time-credit ticks
FLUSH = 30.0     # seconds between writes of stats.json (only when changed)
MAX_APPS = int(os.environ.get("TAK0_LAYOUT_MAX_APPS", "150"))   # per-app tables kept
STALE_DAYS = 7           # a small row is only dropped after this long untouched
NOISE_SECONDS = 60.0     # per-app rows below this much lifetime use are dropped once stale
KEEP_UNUSED_SECONDS = 600.0   # per-app rows of layouts no longer configured need this much to be kept
PENDING_TTL = 1.0

DATA_DIR = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "tak0-layout"
STATS_FILE = DATA_DIR / "stats.json"


# --------------------------------------------------------------------------
# statistics (no Hyprland needed, so it can be tested on its own)
# --------------------------------------------------------------------------
class Stats:
    def __init__(self, path=STATS_FILE, half_life_days=HALF_LIFE_DAYS):
        self.path = Path(path)
        self.half_life = half_life_days * 86400.0
        self.dirty = False
        self.data = {"version": 1, "apps": {}, "global": {}, "keymaps": {}}  # keymaps: display name -> layout code
        self.load()

    def load(self):
        try:
            loaded = json.loads(self.path.read_text())
            if isinstance(loaded, dict) and loaded.get("version") == 1:
                for k in ("apps", "global", "keymaps"):
                    if isinstance(loaded.get(k), dict):
                        self.data[k] = loaded[k]
                if any(isinstance(v, dict) for v in self.data["keymaps"].values()):
                    self.data["keymaps"] = {}   # old per-config layout, relearned once
        except (OSError, ValueError):
            pass

    def _decay(self, dt):
        return 0.5 ** (max(dt, 0.0) / self.half_life)

    def _touch(self, bucket, layout, now):
        e = bucket.setdefault(layout, {"seconds": 0.0, "uses": 0, "score": 0.0, "ts": now})
        e["score"] *= self._decay(now - e["ts"])
        e["ts"] = now
        return e

    def add_time(self, app, layout, dt, now):
        if dt <= 0 or not layout:
            return
        for bucket in (self.data["apps"].setdefault(app or "?", {}), self.data["global"]):
            e = self._touch(bucket, layout, now)
            e["seconds"] += dt
            e["score"] += dt
        self.dirty = True

    def add_use(self, app, layout, now):
        if not layout:
            return
        for bucket in (self.data["apps"].setdefault(app or "?", {}), self.data["global"]):
            self._touch(bucket, layout, now)["uses"] += 1
        self.dirty = True

    def scores(self, app, now, allowed=None):
        bucket = self.data["global"] if app is None else self.data["apps"].get(app, {})
        out = {}
        for layout, e in bucket.items():
            if allowed is None or layout in allowed:
                out[layout] = e["score"] * self._decay(now - e["ts"])
        return out

    def predict(self, app, now, allowed):
        """Layout a new window of this app should start in, or None if no data."""
        s = self.scores(app, now, allowed)
        if sum(s.values()) >= MIN_APP_SECONDS and s:
            return max(s, key=s.get)
        g = self.scores(None, now, allowed)
        if g and sum(g.values()) > 0:
            return max(g, key=g.get)
        return None

    @staticmethod
    def percent(values):
        total = sum(values.values())
        return {k: (round(100.0 * v / total, 1) if total else 0.0) for k, v in values.items()}

    def percents(self, bucket, now):
        """(recent-weighted %, all-time %) for one bucket, computed on demand."""
        recent = self.percent({k: e["score"] * self._decay(now - e["ts"]) for k, e in bucket.items()})
        total = self.percent({k: e["seconds"] for k, e in bucket.items()})
        return recent, total

    def compact(self, now, active=None):
        """Keep the file small however long it runs and however many layouts pile up.

        * The global table is never pruned, so the history of every layout you ever
          used survives, configured or not.
        * Per-app rows are only a prediction aid: rows with almost no use are dropped once
          they have gone stale (their time is still in the global table), rows of layouts that are no
          longer configured need a bit more history to stay, and only the busiest
          MAX_APPS apps keep a table.
        * Numbers are rounded and the file is written without whitespace.
        """
        for app in list(self.data["apps"]):
            bucket = self.data["apps"][app]
            for layout in list(bucket):
                e = bucket[layout]
                floor = NOISE_SECONDS
                if active and layout not in active:
                    floor = KEEP_UNUSED_SECONDS
                if e["seconds"] < floor and now - e["ts"] > STALE_DAYS * 86400:
                    del bucket[layout]
            if not bucket:
                del self.data["apps"][app]
        if len(self.data["apps"]) > MAX_APPS:
            def weight(item):
                return sum(e["score"] * self._decay(now - e["ts"]) for e in item[1].values())
            keep = sorted(self.data["apps"].items(), key=weight, reverse=True)[:MAX_APPS]
            self.data["apps"] = dict(keep)
        for bucket in [self.data["global"], *self.data["apps"].values()]:
            for e in bucket.values():
                e["seconds"] = round(e["seconds"], 1)
                e["score"] = round(e["score"], 1)
                e["ts"] = int(e["ts"])

    def snapshot(self, now):
        g_recent, g_total = self.percents(self.data["global"], now)
        out = dict(self.data, updated=int(now), half_life_days=self.half_life / 86400.0)
        # live percentages of the global split sit at the top for easy reading
        out["live_percent"] = {"recent": g_recent, "total": g_total}
        return out

    def save(self, now=None, active=None):
        now = now or time.time()
        self.compact(now, active)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        tmp = self.path.with_suffix(".tmp")
        tmp.write_text(json.dumps(self.snapshot(now), separators=(",", ":"), sort_keys=True))
        os.replace(tmp, self.path)
        self.dirty = False


# --------------------------------------------------------------------------
# Hyprland access
# --------------------------------------------------------------------------
def runtime_dir():
    return Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")) / "hypr"


def find_signature():
    """The running Hyprland instance. Works from a systemd user service,
    where HYPRLAND_INSTANCE_SIGNATURE is not set."""
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if sig and (runtime_dir() / sig / ".socket2.sock").exists():
        return sig
    socks = list(runtime_dir().glob("*/.socket2.sock"))
    if not socks:
        return None
    return max(socks, key=lambda p: p.stat().st_mtime).parent.name


class Hypr:
    def __init__(self, sig):
        self.sig = sig
        self.env = dict(os.environ, HYPRLAND_INSTANCE_SIGNATURE=sig)

    def run(self, *args):
        return subprocess.run(["hyprctl", *args], env=self.env, capture_output=True,
                              text=True, timeout=5).stdout

    def json(self, *args):
        try:
            return json.loads(self.run("-j", *args))
        except (ValueError, subprocess.SubprocessError, OSError):
            return None

    def keyboard(self):
        """(layout codes, active keymap name) of the main keyboard."""
        devs = (self.json("devices") or {}).get("keyboards", [])
        if not devs:
            return [], None
        kb = next((k for k in devs if k.get("main")), devs[0])
        codes = [c.strip() for c in kb.get("layout", "").split(",") if c.strip()]
        return codes, kb.get("active_keymap")

    def switch(self, index):
        self.run("switchxkblayout", "all", str(index))

    def event_socket(self):
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.connect(str(runtime_dir() / self.sig / ".socket2.sock"))
        return s


# --------------------------------------------------------------------------
# the daemon
# --------------------------------------------------------------------------
class Daemon:
    def __init__(self, hypr, stats):
        self.h, self.stats = hypr, stats
        self.layouts = []        # configured layout codes, in Hyprland's order
        self.names = {}          # keymap display name -> layout code
        self.cur = None          # current layout code
        self.focus = None        # focused window address
        self.win_class = {}
        self.win_layout = {}
        self.pending = {}        # layout code -> time until which its events are ours
        self.last_tick = time.time()
        self.last_flush = time.time()

    # -- setup ------------------------------------------------------------
    def refresh_layouts(self):
        codes, active = self.h.keyboard()
        if not codes:
            return
        if codes != self.layouts:
            self.layouts = codes
        known = self.stats.data["keymaps"]
        if not all(c in known.values() for c in codes):
            known.update(self.calibrate(codes, active))
            self.stats.dirty = True
        self.names = dict(known)
        _, active = self.h.keyboard()
        self.cur = self.names.get(active, self.cur or codes[0])

    def calibrate(self, codes, active):
        """Learn which keymap name belongs to which layout by stepping through them once."""
        names, back = {}, None
        for i, code in enumerate(codes):
            self.h.switch(i)
            time.sleep(0.05)
            _, name = self.h.keyboard()
            if name:
                names[name] = code
            if name == active:
                back = i
        if back is None:
            back = 0
        self.h.switch(back)
        return names

    def seed_windows(self):
        for c in self.h.json("clients") or []:
            self.win_class[c["address"]] = c.get("class", "")
        act = self.h.json("activewindow") or {}
        if act.get("address"):
            self.focus = act["address"]
            self.win_layout.setdefault(self.focus, self.cur)

    # -- helpers ----------------------------------------------------------
    def app(self):
        return self.win_class.get(self.focus) if self.focus else None

    def tick(self, now=None):
        now = now or time.time()
        dt = min(now - self.last_tick, TICK * 2)
        self.last_tick = now
        if self.focus and self.cur:
            self.stats.add_time(self.app(), self.cur, dt, now)

    def default_for(self, app):
        return self.stats.predict(app, time.time(), set(self.layouts)) or (self.layouts[0] if self.layouts else None)

    def apply(self, code):
        if not code or code == self.cur or code not in self.layouts:
            return
        self.pending[code] = time.time() + PENDING_TTL
        self.cur = code
        self.h.switch(self.layouts.index(code))

    # -- events -----------------------------------------------------------
    def on_event(self, name, data):
        now = time.time()
        if name == "openwindow":
            addr, _ws, cls, *_ = (data.split(",", 3) + ["", "", ""])[:4]
            addr = "0x" + addr
            self.win_class[addr] = cls
            self.win_layout[addr] = self.default_for(cls)
        elif name == "closewindow":
            addr = "0x" + data.strip()
            self.win_class.pop(addr, None)
            self.win_layout.pop(addr, None)
            if addr == self.focus:
                self.tick(now)
                self.focus = None
        elif name == "activewindowv2":
            self.tick(now)
            addr = data.strip()
            self.focus = ("0x" + addr) if addr and addr != "," else None
            if self.focus:
                if self.focus not in self.win_class:
                    self.seed_windows()
                want = self.win_layout.get(self.focus) or self.default_for(self.app())
                self.win_layout[self.focus] = want
                self.apply(want)
                self.stats.add_use(self.app(), self.cur, now)
        elif name == "activelayout":
            _kb, _, keymap = data.partition(",")
            code = self.names.get(keymap.strip())
            if not code:
                self.refresh_layouts()
                code = self.names.get(keymap.strip())
            expiry = self.pending.get(code, 0)
            if not code or code == self.cur or expiry > now:
                return
            self.tick(now)
            self.cur = code
            if self.focus:
                self.win_layout[self.focus] = code
                self.stats.add_use(self.app(), code, now)
        elif name == "configreloaded":
            self.refresh_layouts()

    def maybe_flush(self, now=None, force=False):
        now = now or time.time()
        if force or (self.stats.dirty and now - self.last_flush >= FLUSH):
            self.stats.save(now, set(self.layouts))
            self.last_flush = now

    # -- loop -------------------------------------------------------------
    def serve(self):
        self.refresh_layouts()
        if not self.layouts:
            raise RuntimeError("no keyboard layouts reported by Hyprland")
        self.seed_windows()
        self.last_tick = time.time()
        sock = self.h.event_socket()
        buf = b""
        try:
            while True:
                ready, _, _ = select.select([sock], [], [], TICK)
                if ready:
                    chunk = sock.recv(65536)
                    if not chunk:
                        return
                    buf += chunk
                    while b"\n" in buf:
                        line, buf = buf.split(b"\n", 1)
                        name, _, data = line.decode("utf-8", "replace").partition(">>")
                        self.on_event(name, data)
                else:
                    self.tick()
                self.maybe_flush()
        finally:
            self.tick()
            self.maybe_flush(force=True)
            sock.close()


def run_daemon():
    # One daemon per session, so it can be started from a keybind or exec-once
    # as well as from systemd without ever running twice.
    lock_path = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "tak0-layout.lock"
    lock = open(lock_path, "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        return
    stats = Stats()
    stop = []

    def bye(*_):
        stop.append(1)
        raise SystemExit(0)

    signal.signal(signal.SIGTERM, bye)
    signal.signal(signal.SIGINT, bye)
    print("layout_tracker: waiting for Hyprland", flush=True)
    while not stop:
        sig = find_signature()
        if not sig:
            time.sleep(3)
            continue
        print(f"layout_tracker: attached to Hyprland instance {sig}", flush=True)
        try:
            Daemon(Hypr(sig), stats).serve()
        except SystemExit:
            stats.save()
            raise
        except Exception as exc:  # Hyprland went away or hiccuped; try again
            print(f"layout_tracker: {exc!r}, retrying", file=sys.stderr, flush=True)
        stats.save()
        time.sleep(2)


# --------------------------------------------------------------------------
# small CLI commands
# --------------------------------------------------------------------------
def bar(pct, width=20):
    n = round(width * pct / 100.0)
    return "█" * n + "·" * (width - n)


def fmt_time(sec):
    sec = int(sec)
    return f"{sec // 3600}h{(sec % 3600) // 60:02d}m" if sec >= 3600 else f"{sec // 60}m{sec % 60:02d}s"


def cmd_stats(app):
    stats = Stats()
    if not stats.data["global"]:
        print("No statistics yet. Enable the daemon first, see custom/execs.lua")
        return 1
    sig = find_signature()
    active = set(Hypr(sig).keyboard()[0]) if sig else set()
    now = time.time()
    if app:
        buckets = [(f"app: {app}", stats.data["apps"].get(app, {}))]
    else:
        top = sorted(stats.data["apps"].items(), key=lambda kv: -sum(e["seconds"] for e in kv[1].values()))[:8]
        buckets = [("all apps", stats.data["global"])] + [(f"app: {a}", b) for a, b in top]
    for title, bucket in buckets:
        if not bucket:
            print(f"{title}: no data")
            continue
        recent, total = stats.percents(bucket, now)
        print(f"\n{title}   (recent weighting | all time)")
        for layout, e in sorted(bucket.items(), key=lambda kv: -recent[kv[0]]):
            tag = "" if not active or layout in active else "  (not configured, data kept)"
            print(f"  {layout:<8} {bar(recent[layout])} {recent[layout]:5.1f}% | {total[layout]:5.1f}%"
                  f"  {fmt_time(e['seconds']):>8}  {e['uses']} uses{tag}")
    return 0


def cmd_toggle():
    sig = find_signature()
    if not sig:
        print("Hyprland is not running", file=sys.stderr)
        return 1
    h = Hypr(sig)
    h.run("switchxkblayout", "all", "next")
    _, name = h.keyboard()
    subprocess.run(["notify-send", "-u", "low", "-t", "800", f"Layout: {name}"], check=False)
    return 0


def cmd_status():
    sig = find_signature()
    codes, name = Hypr(sig).keyboard() if sig else ([], None)
    print(f"hyprland : {sig or 'not running'}")
    print(f"layouts  : {', '.join(codes) or '-'}")
    print(f"current  : {name or '-'}")
    print(f"data     : {STATS_FILE}")
    return 0


def cmd_forget(app):
    stats = Stats()
    stats.data["apps"].pop(app, None)
    stats.dirty = True
    stats.save()
    print(f"forgot {app}. Restart the daemon so it reloads the file (log out and in, or kill it and run it again)")
    return 0


def main():
    p = argparse.ArgumentParser(prog="layout_tracker.py", description=__doc__.split("\n")[1])
    sub = p.add_subparsers(dest="cmd")
    sub.add_parser("daemon")
    sub.add_parser("toggle")
    sub.add_parser("status")
    s = sub.add_parser("stats")
    s.add_argument("app", nargs="?")
    f = sub.add_parser("forget")
    f.add_argument("app")
    a = p.parse_args()
    if a.cmd in (None, "daemon"):
        run_daemon()
        return 0
    return {"toggle": cmd_toggle, "status": cmd_status,
            "stats": lambda: cmd_stats(a.app), "forget": lambda: cmd_forget(a.app)}[a.cmd]()


if __name__ == "__main__":
    sys.exit(main())
