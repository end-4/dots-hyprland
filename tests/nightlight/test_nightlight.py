#!/usr/bin/env python3
"""
Tests that BITE the night-light cycle logic. Each asserts one specific claim and
goes red when exactly that claim breaks. Run:  python3 test_nightlight.py
A `--mutate <name>` mode intentionally breaks one constant to PROVE the relevant
tests fail (the reversal-check: a test that can't fail is poison, not a test).

Covers: temperature mapping, twilight ramp shape, midnight wrap, glide
convergence / no-overshoot / bounded-step (== "how smoothly it moves"), and the
solar schedule (correctness + seasonality + polar), which is what makes it work
"for everyone" across the year.
"""
import sys
import math
import datetime
from zoneinfo import ZoneInfo

import nightlight_logic as L

KYIV = ZoneInfo("Europe/Kiev")
KYIV_LAT, KYIV_LON = 50.4501, 30.5234

_fails = []


def check(name, cond, detail=""):
    status = "PASS" if cond else "FAIL"
    if not cond:
        _fails.append(name)
    print(f"  [{status}] {name}" + (f"  — {detail}" if detail and not cond else ""))


# ---------------- temperature mapping ----------------
def test_temperature_mapping():
    print("temperature mapping")
    peak = 4729
    check("level 0 is identity (off), not a Kelvin value", L.temp_for_level(0, peak) == L.IDENTITY)
    check("level 1 is the peak warmth", L.temp_for_level(1, peak) == peak)
    check("level 0.6 matches lerp (5477 for peak 4729)", L.temp_for_level(0.6, peak) == 5477,
          f"got {L.temp_for_level(0.6, peak)}")
    near0 = L.temp_for_level(0.002, peak)
    check("just above 0 sits at neutral (hand-off to identity is seamless)", abs(near0 - 6600) <= 5, str(near0))
    seq = [L.temp_for_level(x / 10, peak) for x in range(1, 11)]
    check("warmer as level rises = temperature strictly decreases",
          all(b < a for a, b in zip(seq, seq[1:])), str(seq))


# ---------------- gamma composition ----------------
def test_gamma_composes_with_dim():
    print("gamma: user value x dim factor (dim never kills the Gamma slider)")
    check("dim off = user gamma passes through", L.gamma_for_level(1, 70, 50, False) == 70)
    check("dim on holds by day too (level 0): 100 x 50%", L.gamma_for_level(0, 100, 50, True) == 50)
    check("dim on, full night = user x night (100 x 50%)", L.gamma_for_level(1, 100, 50, True) == 50)
    at_night = [L.gamma_for_level(1, g, 80, True) for g in (100, 90, 70)]
    check("lowering user gamma still lowers output while dimmed", at_night[0] > at_night[1] > at_night[2], str(at_night))
    check("never below the floor", L.gamma_for_level(1, 25, 25, True) == L.GAMMA_LOWER)


# ---------------- twilight ramp shape ----------------
def test_ramp_shape():
    print("twilight ramp (compute_level)")
    frm, to, tr = 19 * 60 + 17, 6 * 60 + 32, 30  # 19:17 -> 06:32, 30-min fade both edges
    check("outside the window = 0 (noon)", L.compute_level(12 * 60, frm, to, tr, tr) == 0)
    check("exactly at the start edge = 0", L.compute_level(frm, frm, to, tr, tr) == 0)
    check("exactly at the end edge = 0", L.compute_level(to, frm, to, tr, tr) == 0)
    check("deep in the window = full 1 (midnight)", L.compute_level(0, frm, to, tr, tr) == 1.0)
    mid_ramp = L.compute_level(frm + 15, frm, to, tr, tr)  # 15 min into a 30-min fade
    check("15 min into a 30-min fade = ~0.5", abs(mid_ramp - 0.5) < 1e-9, f"got {mid_ramp}")
    check("ramp is partial, not binary, inside the fade", 0 < mid_ramp < 1)


def test_soft_auto_edge():
    print("auto edges fade softer (longer) than a fixed time")
    frm, to = 19 * 60, 6 * 60
    hard = 30
    soft = round(hard * L.SOFT_FACTOR)  # 53
    # 30 min into the window: a hard edge is already full; a soft edge is still ramping.
    hard_lvl = L.compute_level(frm + 30, frm, to, hard, hard)
    soft_lvl = L.compute_level(frm + 30, frm, to, soft, soft)
    check("hard edge is full 30 min in", abs(hard_lvl - 1.0) < 1e-9, f"{hard_lvl}")
    check("soft edge is still below full 30 min in", soft_lvl < 1.0, f"{soft_lvl}")
    check("soft edge is gentler (lower level at the same offset)", soft_lvl < hard_lvl)


def test_midnight_wrap():
    print("midnight wrap")
    frm, to = 19 * 60 + 17, 6 * 60 + 32
    check("00:00 counts as night", L.compute_level(0, frm, to, 30, 30) == 1.0)
    check("12:00 counts as day", L.compute_level(12 * 60, frm, to, 30, 30) == 0.0)
    check("05:00 (pre-sunrise) still night-ish", L.compute_level(5 * 60, frm, to, 30, 30) > 0)


# ---------------- glide == smoothness ----------------
def test_glide_converges():
    print("glide converges")
    s = L.glide_series(0.0, 1.0)
    check("reaches the target", abs(s[-1] - 1.0) < 1e-9)
    check("converges in a sane number of ticks (<40)", len(s) < 40, f"{len(s)} ticks")


def test_glide_no_overshoot():
    print("glide is smooth — monotonic, no overshoot")
    s = L.glide_series(0.0, 1.0)
    check("never overshoots past target", all(x <= 1.0 + 1e-12 for x in s))
    diffs = [b - a for a, b in zip(s, s[1:])]
    check("moves in one direction only (no oscillation)", all(d >= -1e-12 for d in diffs))
    # The eased steps (all but the terminal snap) must shrink every tick — the
    # signature of exponential approach. The final tick is a snap-to-target whose
    # size is bounded separately (below), so it is excluded here.
    eased = diffs[:-1]
    check("eased steps shrink every tick (exponential, not linear/jerky)",
          all(b <= a + 1e-12 for a, b in zip(eased, eased[1:])))
    check("terminal snap is imperceptible (<= GLIDE_SNAP level, ~5K)", diffs[-1] <= L.GLIDE_SNAP + 1e-12,
          f"snap {diffs[-1]:.4f}")


SMOOTH_MAX_STEP = 0.35  # absolute: one 60ms tick must not cover >35% of the range, or it reads as a snap

def test_glide_bounded_step():
    print("glide step is bounded — no visible snap")
    s = L.glide_series(0.0, 1.0)
    biggest = max(b - a for a, b in zip(s, s[1:]))
    # ABSOLUTE bar, independent of GLIDE_FACTOR — otherwise the test is tautological
    # (a jerky factor would just drag the bar with it). An instant/large factor fails here.
    check(f"no single tick covers more than {int(SMOOTH_MAX_STEP*100)}% of the range",
          biggest <= SMOOTH_MAX_STEP + 1e-9, f"biggest step {biggest:.3f}")
    check("the eased approach takes several ticks (not 1-2)", len(s) >= 8, f"{len(s)} ticks")


def test_glide_downward():
    print("glide works downward too (sunrise / turning off)")
    s = L.glide_series(1.0, 0.0)
    check("reaches 0", abs(s[-1]) < 1e-9)
    check("never undershoots below 0", all(x >= -1e-12 for x in s))


# ---------------- effective level (auto + bias) ----------------
def test_effective_level():
    print("effective level = clamp(auto + bias)")
    check("bias 0 follows auto", L.effective_level(0.7, 0.0, True) == 0.7)
    check("bias +0.3 rides above auto", abs(L.effective_level(0.5, 0.3, True) - 0.8) < 1e-9)
    check("bias -0.3 rides below auto", abs(L.effective_level(0.5, -0.3, True) - 0.2) < 1e-9)
    check("clamps at 1", L.effective_level(0.9, 0.5, True) == 1.0)
    check("clamps at 0", L.effective_level(0.1, -0.5, True) == 0.0)
    check("automatic off = bias is the whole signal", L.effective_level(0.7, 0.4, False) == 0.4)


# ---------------- solar schedule ----------------
def test_solar_correct():
    print("solar times — Kyiv 2026-09-14")
    date = datetime.datetime(2026, 9, 14, 12, 0, tzinfo=KYIV)
    rise, sset = L.sun_times(date, KYIV_LAT, KYIV_LON, KYIV)
    check("sunrise within 2 min of 06:32", abs(rise - (6 * 60 + 32)) <= 2, f"{rise//60:02d}:{rise%60:02d}")
    check("sunset within 2 min of 19:17", abs(sset - (19 * 60 + 17)) <= 2, f"{sset//60:02d}:{sset%60:02d}")


def test_solar_seasonality():
    print("solar adapts across seasons (this is the 'works for the whole year' claim)")
    def day_len(month):
        d = datetime.datetime(2026, month, 21, 12, 0, tzinfo=KYIV)
        rise, sset = L.sun_times(d, KYIV_LAT, KYIV_LON, KYIV)
        return (sset - rise) % 1440
    june, dec = day_len(6), day_len(12)
    check("June day is longer than December day", june > dec, f"jun {june}m vs dec {dec}m")
    check("the swing is large (>4h), i.e. genuinely seasonal", (june - dec) > 240,
          f"delta {june - dec}m")


def test_solar_polar():
    print("solar polar edge cases (Svalbard 78N)")
    svb = ZoneInfo("Arctic/Longyearbyen")
    jun = L.sun_times(datetime.datetime(2026, 6, 21, 12, tzinfo=svb), 78.22, 15.63, svb)
    dec = L.sun_times(datetime.datetime(2026, 12, 21, 12, tzinfo=svb), 78.22, 15.63, svb)
    check("midnight sun in June = polar 'night' sentinel (never engage)", jun == ('polar', 'night'), str(jun))
    check("polar night in December = polar 'day' sentinel (always engage)", dec == ('polar', 'day'), str(dec))


ALL = [
    test_temperature_mapping, test_gamma_composes_with_dim, test_ramp_shape, test_soft_auto_edge, test_midnight_wrap,
    test_glide_converges, test_glide_no_overshoot, test_glide_bounded_step, test_glide_downward,
    test_effective_level, test_solar_correct, test_solar_seasonality, test_solar_polar,
]


def main():
    # --mutate proves the tests bite: break one constant, expect reds.
    if len(sys.argv) > 1 and sys.argv[1] == "--mutate":
        which = sys.argv[2] if len(sys.argv) > 2 else "glide"
        if which == "glide":
            L.GLIDE_FACTOR = 1.0   # instant snap — must break the smoothness tests
            print("MUTATION: GLIDE_FACTOR = 1.0 (instant) — expect glide-smoothness reds\n")
        elif which == "neutral":
            L.NEUTRAL_TEMP = 4000  # wrong neutral — must break temperature mapping
            print("MUTATION: NEUTRAL_TEMP = 4000 — expect temperature-mapping reds\n")
        elif which == "gamma":
            L.gamma_for_level = lambda lv, ug, ng, on: round(100 + (max(L.GAMMA_LOWER, ng) - 100) * lv) if on else ug
            print("MUTATION: dim overwrites user gamma, scaled by night level (the old bugs) — expect gamma reds\n")
        elif which == "solar":
            _orig = L.sun_times
            L.sun_times = lambda *a, **k: (6 * 60, 18 * 60)  # ignore date/location
            print("MUTATION: sun_times ignores date/location — expect solar reds\n")

    print("=== night-light cycle: tests that bite ===\n")
    for t in ALL:
        t()
        print()
    if _fails:
        print(f"RESULT: {len(_fails)} FAILED -> {_fails}")
        sys.exit(1)
    print("RESULT: all green")


if __name__ == "__main__":
    main()
