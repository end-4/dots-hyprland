#!/usr/bin/env python3
"""
LIVE integration probe — runs on the Hyprland host. Drives the bias ("Adjust")
value the way the slider does, then samples the REAL `hyprctl hyprsunset
temperature` over time and asserts the deployed service actually:
  * eases (several distinct intermediate values, no instant snap),
  * lands on the lerp target for that level, within tolerance,
  * returns to neutral (6000) at bias 0.

It writes only config.light.night.bias and restores it to 0 at the end.
Exit non-zero on any failed assertion.
"""
import json
import os
import subprocess
import time
import glob

CFG = os.path.expanduser("~/.config/illogical-impulse/config.json")
DEFAULT_TEMP = 6000
TOL_K = 60          # endpoint tolerance (glide snap + rounding)
MIN_INTERMEDIATE = 3  # distinct values strictly between start and settle => it eased


def his():
    d = glob.glob("/run/user/%d/hypr/*" % os.getuid())
    return os.path.basename(sorted(d)[0]) if d else ""


ENV = dict(os.environ, HYPRLAND_INSTANCE_SIGNATURE=his())


def temp():
    out = subprocess.run(["hyprctl", "hyprsunset", "temperature"],
                         capture_output=True, text=True, env=ENV).stdout.strip()
    try:
        return int(out)
    except ValueError:
        return None


def set_bias(b):
    d = json.load(open(CFG))
    d["light"]["night"]["bias"] = float(b)
    json.dump(d, open(CFG, "w"), indent=2, ensure_ascii=False)


def peak():
    return json.load(open(CFG))["light"]["night"].get("colorTemperature", 5000)


def auto_level_now():
    # This probe runs by day for a clean baseline; if night has begun, skip strict endpoint checks.
    d = json.load(open(CFG))["light"]["night"]
    return d  # returned for logging only


def sample(n=14, dt=0.12):
    xs = []
    for _ in range(n):
        t = temp()
        if t is not None:
            xs.append(t)
        time.sleep(dt)
    return xs


def lerp_target(level, pk):
    return round(DEFAULT_TEMP + (pk - DEFAULT_TEMP) * level)


fails = []


def check(name, cond, detail=""):
    print(f"  [{'PASS' if cond else 'FAIL'}] {name}" + (f"  — {detail}" if (detail and not cond) else ""))
    if not cond:
        fails.append(name)


def run_case(bias, pk):
    # Expected level assumes daytime auto=0 (probe is meant to run by day).
    level = max(0.0, min(1.0, bias))
    target = lerp_target(level, pk)
    set_bias(bias)
    series = sample()
    settle = series[-1] if series else None
    inter = sorted(set(series[1:-1]))
    print(f"  bias={bias:+.2f} peak={pk} expect~{target}K  series={series}")
    check(f"bias {bias:+.2f}: settles near {target}K", settle is not None and abs(settle - target) <= TOL_K,
          f"settled {settle}")
    if abs(series[0] - target) > 200:  # only meaningful when there is distance to travel
        check(f"bias {bias:+.2f}: eased through >= {MIN_INTERMEDIATE} intermediate steps",
              len(inter) >= MIN_INTERMEDIATE, f"intermediates {inter}")
        biggest = max(abs(b - a) for a, b in zip(series, series[1:]))
        span = abs(target - series[0]) or 1
        check(f"bias {bias:+.2f}: no single sample jumped the whole way (<70% span)",
              biggest <= 0.70 * span, f"biggest jump {biggest}K of {span}K")


def main():
    print("=== live glide probe (writes only light.night.bias, restored to 0) ===")
    print(f"HYPRLAND_INSTANCE_SIGNATURE={ENV['HYPRLAND_INSTANCE_SIGNATURE'][:16]}…")
    pk = peak()
    set_bias(0.0); time.sleep(1.2)
    base = temp()
    print(f"baseline temp at bias 0: {base}K (expect 6000 by day)\n")
    for b in [0.6, 1.0, 0.3, 0.0]:
        run_case(b, pk)
        print()
    set_bias(0.0)
    print("restored bias -> 0 (pure auto)")
    if fails:
        print(f"\nRESULT: {len(fails)} FAILED -> {fails}")
        raise SystemExit(1)
    print("\nRESULT: all green (live)")


if __name__ == "__main__":
    main()
