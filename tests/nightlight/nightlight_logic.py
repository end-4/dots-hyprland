"""
Pure port of the Hyprsunset.qml cycle logic — the maths that decides screen
temperature and how smoothly it moves. Kept deliberately dependency-free so it
runs anywhere and can be exercised by tests that actually bite.

CONSTANTS AND FORMULAS MUST MIRROR services/Hyprsunset.qml. If you change the
glide factor, the neutral temperature, or the solar algorithm there, change it
here too — the tests below are the tripwire that says you forgot.
"""
import math
import datetime

# ---- constants (mirror Hyprsunset.qml) ----
NEUTRAL_TEMP = 6600        # glide endpoint: hyprsunset's Kelvin nearest identity
IDENTITY = "identity"      # level 0 output: no CTM tint at all (6000K still tints, #3328)
GLIDE_FACTOR = 0.28        # exponential ease per 60ms tick
GLIDE_SNAP = 0.004         # |target-applied| below this snaps and stops
GAMMA_LOWER = 25


ACTIVE_EPS = 0.001


def temp_for_level(level, peak):
    """appliedLevel -> hyprsunset output. level 0 = IDENTITY (off), else Kelvin lerp
    from NEUTRAL_TEMP (level->0) to peak warmth (level 1)."""
    if level <= ACTIVE_EPS:
        return IDENTITY
    return round(NEUTRAL_TEMP + (peak - NEUTRAL_TEMP) * level)


def gamma_for_level(level, user_gamma, night_gamma, dim_on):
    """Output gamma = the user's gamma times the dim factor — dim composes, it never
    replaces the user's value (else the Gamma slider dies while Dim is on)."""
    dim = 1 + (max(GAMMA_LOWER, night_gamma) / 100 - 1) * level if dim_on else 1
    return max(GAMMA_LOWER, round(user_gamma * dim))


def _in_between(t, frm, to):
    if frm < to:
        return frm <= t <= to
    return t >= frm or t <= to  # wrapped past midnight


def _since(t, start):
    d = t - start
    return d + 1440 if d < 0 else d


def _until(t, end):
    d = end - t
    return d + 1440 if d < 0 else d


SOFT_FACTOR = 1.75  # auto (sun-based) edges fade this much longer than a fixed time

def compute_level(t, frm, to, trans_in, trans_out):
    """Continuous 0..1 night level with independent twilight ramps at each edge."""
    if not _in_between(t, frm, to):
        return 0.0
    ramp_in = 1.0 if trans_in <= 0 else min(1.0, _since(t, frm) / trans_in)
    ramp_out = 1.0 if trans_out <= 0 else min(1.0, _until(t, to) / trans_out)
    return max(0.0, min(ramp_in, ramp_out))


def effective_level(auto_level, bias, automatic):
    base = auto_level if automatic else 0.0
    return max(0.0, min(1.0, base + bias))


def glide_series(start, target, factor=None, snap=None, max_ticks=1000):
    """Reproduce the glideTimer recurrence. Returns the list of applied levels,
    including the starting point, ending when it snaps to target.
    Reads the module globals at CALL time (not as default args) so a mutation
    test can swap GLIDE_FACTOR and actually exercise a different trajectory."""
    if factor is None:
        factor = GLIDE_FACTOR
    if snap is None:
        snap = GLIDE_SNAP
    applied = start
    out = [applied]
    for _ in range(max_ticks):
        d = target - applied
        if abs(d) < snap:
            applied = target
            out.append(applied)
            break
        applied = applied + d * factor
        out.append(applied)
    return out


# ---- SunCalc (MIT, V. Agafonkin), ported to match Hyprsunset.qml.sunTimes ----
def sun_times(date, lat, lng, tz):
    """date: aware datetime in tz. Returns (sunrise_min, sunset_min) local minutes-of-day,
    or ('polar', 'day'|'night')."""
    rad = math.pi / 180
    day_ms = 86400000
    J1970, J2000, J0 = 2440588, 2451545, 0.0009

    def to_julian(dt):
        return dt.timestamp() * 1000 / day_ms - 0.5 + J1970

    def from_julian(j):
        return datetime.datetime.fromtimestamp((j + 0.5 - J1970) * day_ms / 1000,
                                               tz=datetime.timezone.utc)

    def to_days(dt):
        return to_julian(dt) - J2000

    lw = rad * -lng
    phi = rad * lat
    d = to_days(date)
    n = round(d - J0 - lw / (2 * math.pi))
    ds = J0 + lw / (2 * math.pi) + n
    M = rad * (357.5291 + 0.98560028 * ds)
    C = rad * (1.9148 * math.sin(M) + 0.02 * math.sin(2 * M) + 0.0003 * math.sin(3 * M))
    L = M + C + rad * 102.9372 + math.pi
    dec = math.asin(math.sin(L) * math.sin(rad * 23.4397))
    Jnoon = J2000 + ds + 0.0053 * math.sin(M) - 0.0069 * math.sin(2 * L)

    h0 = rad * -0.833
    cos_w = (math.sin(h0) - math.sin(phi) * math.sin(dec)) / (math.cos(phi) * math.cos(dec))
    if cos_w > 1:
        return ('polar', 'day')
    if cos_w < -1:
        return ('polar', 'night')
    w0 = math.acos(cos_w)
    a = J0 + (w0 + lw) / (2 * math.pi) + n
    Jset = J2000 + a + 0.0053 * math.sin(M) - 0.0069 * math.sin(2 * L)
    Jrise = Jnoon - (Jset - Jnoon)
    rise = from_julian(Jrise).astimezone(tz)
    sset = from_julian(Jset).astimezone(tz)
    return (rise.hour * 60 + rise.minute, sset.hour * 60 + sset.minute)
