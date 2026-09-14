#!/usr/bin/env python3
"""
Live test of the unified schedule engine on the host. Temporarily drives the
manual from/to window around 'now' to exercise deep-night (level 1) and mid-fade
(level 0.5), measuring real hyprctl temperature, then restores auto mode.
"""
import json, os, subprocess, time, glob, datetime

CFG = os.path.expanduser("~/.config/illogical-impulse/config.json")
DEFAULT_TEMP = 6000
ENV = dict(os.environ, HYPRLAND_INSTANCE_SIGNATURE=os.path.basename(
    sorted(glob.glob("/run/user/%d/hypr/*" % os.getuid()))[0]))

def temp():
    out = subprocess.run(["hyprctl", "hyprsunset", "temperature"], capture_output=True, text=True, env=ENV).stdout.strip()
    try: return int(out)
    except ValueError: return None

def load(): return json.load(open(CFG))
def save(d): json.dump(d, open(CFG, "w"), indent=2, ensure_ascii=False)

def set_night(**kw):
    d = load(); d["light"]["night"].update(kw); save(d)

def sample(n=9, dt=0.2):
    xs = []
    for _ in range(n):
        t = temp()
        if t is not None: xs.append(t)
        time.sleep(dt)
    return xs

def lerp(level, peak): return round(DEFAULT_TEMP + (peak - DEFAULT_TEMP) * level)

fails = []
def check(name, cond, detail=""):
    print(f"  [{'PASS' if cond else 'FAIL'}] {name}" + (f"  — {detail}" if detail and not cond else ""))
    if not cond: fails.append(name)

def main():
    orig = load()["light"]["night"].copy()
    peak = orig.get("colorTemperature", 5000)
    now = datetime.datetime.now()
    print(f"peak={peak}K now={now:%H:%M}")
    try:
        set_night(automatic=True, startMode="auto", endMode="auto", latitude=50.4501, longitude=30.5234)
        time.sleep(1.2)
        base = temp()
        print(f"baseline (auto, daytime): {base}K")
        check("daytime auto = neutral 6000", base == 6000, f"got {base}")

        # deep night: window opened 45 min ago (past the 30-min fade -> level 1)
        f45 = (now - datetime.timedelta(minutes=45)).strftime("%H:%M")
        t3 = (now + datetime.timedelta(hours=3)).strftime("%H:%M")
        set_night(startMode="time", endMode="time", **{"from": f45, "to": t3})
        s = sample(); print(f"deep-night [{f45}->{t3}] target~{lerp(1,peak)}K: {s}")
        check("deep night settles at peak", abs(s[-1] - lerp(1, peak)) <= 60, f"{s[-1]}")

        # mid fade: window opened 15 min ago (half of 30-min fade -> level 0.5)
        f15 = (now - datetime.timedelta(minutes=15)).strftime("%H:%M")
        set_night(**{"from": f15})
        s = sample(); exp = lerp(0.5, peak); print(f"mid-fade [{f15}] target~{exp}K: {s}")
        check("mid-fade sits near half strength", abs(s[-1] - exp) <= 120, f"{s[-1]} vs {exp}")
        lo, hi = sorted((6000, lerp(1, peak)))  # peak may be warmer (<6000) or cooler (>6000) than neutral
        check("mid-fade is strictly between neutral and peak", lo < s[-1] < hi, f"{s[-1]} not in ({lo},{hi})")
    finally:
        set_night(startMode=orig.get("startMode", "auto"), endMode=orig.get("endMode", "auto"),
                  **{"from": orig.get("from", "19:00"), "to": orig.get("to", "06:30")})
        time.sleep(1.0)
        print(f"restored -> auto; temp now {temp()}K")
    if fails:
        print(f"\nRESULT: {len(fails)} FAILED -> {fails}"); raise SystemExit(1)
    print("\nRESULT: all green (live schedule)")

if __name__ == "__main__":
    main()
