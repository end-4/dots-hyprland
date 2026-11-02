#!/usr/bin/env python3
"""Backend de estadisticas del dashboard del sidebar izquierdo de ii.

Imprime un objeto JSON por linea (~1 s). El modo se cambia escribiendo en stdin:
summary | cpu | mem | net | gpu
Solo la lista de procesos del modo activo se calcula; el resto es barato.
"""
import glob
import json
import os
import subprocess
import sys
import threading
import time

CLK = os.sysconf("SC_CLK_TCK")
PAGE_KB = os.sysconf("SC_PAGE_SIZE") / 1024
NCPU = os.cpu_count() or 1
TOP = 30
SKIP_IF = ("lo", "docker", "veth", "br-", "virbr", "vnet", "tun", "tap", "wg", "tailscale")
MODES = ("summary", "cpu", "mem", "net", "gpu")

mode = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] in MODES else "summary"


def rd(path):
    try:
        with open(path) as f:
            return f.read()
    except OSError:
        return ""


def stdin_loop():
    global mode
    for line in sys.stdin:
        m = line.strip()
        if m in MODES:
            mode = m
    os._exit(0)  # QML cerro stdin: salir


# ---------------------------------------------------------------- globales
def cpu_total():
    v = [int(x) for x in rd("/proc/stat").split("\n", 1)[0].split()[1:9]]
    return sum(v), v[3] + v[4]  # total, idle+iowait


def meminfo():
    d = {}
    for line in rd("/proc/meminfo").splitlines():
        k, _, rest = line.partition(":")
        try:
            d[k] = int(rest.split()[0])
        except (ValueError, IndexError):
            pass
    return d


def net_totals():
    rx = tx = 0
    for line in rd("/proc/net/dev").splitlines()[2:]:
        name, _, rest = line.partition(":")
        if name.strip().startswith(SKIP_IF):
            continue
        f = rest.split()
        if len(f) >= 9:
            rx += int(f[0])
            tx += int(f[8])
    return rx, tx


def find_temp():
    for h in glob.glob("/sys/class/hwmon/hwmon*"):
        if rd(h + "/name").strip() in ("coretemp", "k10temp", "zenpower"):
            return h + "/temp1_input"
    z = glob.glob("/sys/class/thermal/thermal_zone*/temp")
    return z[0] if z else None


def find_gpu_freq():
    for act, mx in (
        ("/sys/class/drm/card*/gt_act_freq_mhz", "/sys/class/drm/card*/gt_max_freq_mhz"),
        ("/sys/class/drm/card*/gt/gt0/rps_act_freq_mhz", "/sys/class/drm/card*/gt/gt0/rps_max_freq_mhz"),
    ):
        a, m = glob.glob(act), glob.glob(mx)
        if a:
            return a[0], (m[0] if m else None)
    return None, None


def to_int(s):
    try:
        return int(s.strip())
    except ValueError:
        return 0


# ---------------------------------------------------------------- procesos
def scan_procs():
    out = {}
    for pid in os.listdir("/proc"):
        if not pid.isdigit():
            continue
        s = rd("/proc/%s/stat" % pid)
        l, r = s.find("("), s.rfind(")")
        if l < 0 or r < 0:
            continue
        f = s[r + 2:].split()
        try:
            out[int(pid)] = (s[l + 1:r], int(f[11]) + int(f[12]), int(f[21]))
        except (ValueError, IndexError):
            continue
    return out


prev_scan = None
prev_scan_t = 0.0


def cpu_rows():
    global prev_scan, prev_scan_t
    cur, now = scan_procs(), time.time()
    if prev_scan is None:  # primera vez: linea base + medicion corta
        prev_scan, prev_scan_t = cur, now
        time.sleep(0.5)
        cur, now = scan_procs(), time.time()
    dt = max(now - prev_scan_t, 0.1)
    agg, cnt = {}, {}
    for pid, (comm, ticks, _rss) in cur.items():
        cnt[comm] = cnt.get(comm, 0) + 1
        p = prev_scan.get(pid)
        if p and p[0] == comm and ticks > p[1]:
            agg[comm] = agg.get(comm, 0.0) + (ticks - p[1]) / (CLK * dt) * 100.0 / NCPU
    prev_scan, prev_scan_t = cur, now
    rows = [{"n": k, "c": cnt[k], "v": round(v, 2)} for k, v in agg.items() if v >= 0.05]
    rows.sort(key=lambda r: r["v"], reverse=True)
    return rows[:TOP]


def mem_rows():
    agg, cnt = {}, {}
    for _pid, (comm, _t, rss) in scan_procs().items():
        agg[comm] = agg.get(comm, 0.0) + rss * PAGE_KB
        cnt[comm] = cnt.get(comm, 0) + 1
    rows = [{"n": k, "c": cnt[k], "v": round(v)} for k, v in agg.items() if v > 0]
    rows.sort(key=lambda r: r["v"], reverse=True)
    return rows[:TOP]


# ---------------------------------------------------------------- GPU (fdinfo DRM)
gpu_prev = {}
gpu_prev_t = 0.0


def gpu_scan():
    global gpu_prev, gpu_prev_t
    now = time.time()
    cur, comm = {}, {}
    for pid in os.listdir("/proc"):
        if not pid.isdigit():
            continue
        fddir = "/proc/%s/fd" % pid
        try:
            fds = os.listdir(fddir)
        except OSError:
            continue
        seen = set()
        for fd in fds:
            try:
                if not os.readlink("%s/%s" % (fddir, fd)).startswith("/dev/dri/"):
                    continue
            except OSError:
                continue
            cid, eng = None, {}
            for line in rd("/proc/%s/fdinfo/%s" % (pid, fd)).splitlines():
                key, _, val = line.partition(":")
                if key == "drm-client-id":
                    cid = val.strip()
                elif key.startswith("drm-engine-") and not key.startswith("drm-engine-capacity-"):
                    try:
                        eng[key[len("drm-engine-"):]] = int(val.split()[0])
                    except (ValueError, IndexError):
                        pass
            if cid is None or not eng or cid in seen:
                continue
            seen.add(cid)
            cur[(pid, cid)] = eng
        if seen:
            comm[pid] = rd("/proc/%s/comm" % pid).strip() or "?"
    util, rows = 0.0, []
    if gpu_prev_t:
        dt_ns = max((now - gpu_prev_t) * 1e9, 1.0)
        per_engine, per_name = {}, {}
        for key, eng in cur.items():
            old = gpu_prev.get(key)
            if not old:
                continue
            best = 0.0
            for e, ns in eng.items():
                d = ns - old.get(e, ns)
                if d <= 0:
                    continue
                per_engine[e] = per_engine.get(e, 0) + d
                best = max(best, d / dt_ns * 100.0)
            if best >= 0.05:
                name = comm.get(key[0], "?")
                per_name[name] = per_name.get(name, 0.0) + best
        util = min(100.0, max([v / dt_ns * 100.0 for v in per_engine.values()] or [0.0]))
        rows = [{"n": n, "c": 1, "v": round(min(v, 100.0), 2)} for n, v in per_name.items()]
        rows.sort(key=lambda r: r["v"], reverse=True)
    gpu_prev, gpu_prev_t = cur, now
    return {"util": util, "rows": rows[:TOP]}


# ---------------------------------------------------------------- red por proceso (nethogs)
nh = {"proc": None, "rows": [], "err": ""}


def default_iface():
    for line in rd("/proc/net/route").splitlines()[1:]:
        f = line.split()
        if len(f) > 2 and f[1] == "00000000":
            return f[0]
    return None


def nh_reader(p):
    block = []
    for line in p.stdout:
        line = line.rstrip("\n")
        if line.startswith("Refreshing:"):
            agg = {}
            for name, sent, recv in block:
                a = agg.setdefault(name, [0.0, 0.0, 0])
                a[0] += recv
                a[1] += sent
                a[2] += 1
            rows = [{"n": k, "c": a[2], "v": round(a[0], 2), "v2": round(a[1], 2)}
                    for k, a in agg.items() if a[0] + a[1] > 0]
            rows.sort(key=lambda r: r["v"] + r["v2"], reverse=True)
            nh["rows"] = rows[:TOP]
            block = []
            continue
        parts = line.split("\t")
        if len(parts) < 3:
            continue
        try:
            sent, recv = float(parts[-2]), float(parts[-1])
        except ValueError:
            continue
        prog = parts[0].rsplit("/", 2)[0]
        block.append((os.path.basename(prog) or prog or "?", sent, recv))


def nh_err_reader(p):
    for line in p.stderr:
        if line.strip():
            nh["err"] = line.strip()


def nh_start():
    nh["rows"], nh["err"] = [], ""
    cmd = ["nethogs", "-t", "-d", "1"]
    iface = default_iface()
    if iface:
        cmd.append(iface)
    try:
        p = subprocess.Popen(cmd, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE, text=True, bufsize=1)
    except FileNotFoundError:
        nh["err"] = "no_nethogs"
        return
    nh["proc"] = p
    threading.Thread(target=nh_reader, args=(p,), daemon=True).start()
    threading.Thread(target=nh_err_reader, args=(p,), daemon=True).start()


def nh_stop():
    p = nh["proc"]
    if p:
        p.terminate()
    nh["proc"] = None


def nh_error():
    p = nh["proc"]
    if p and p.poll() is not None and not nh["rows"] and not nh["err"]:
        return "nethogs_exited"
    return nh["err"]


# ---------------------------------------------------------------- bucle principal
def main():
    global prev_scan
    threading.Thread(target=stdin_loop, daemon=True).start()
    temp_path = find_temp()
    freq_act, freq_max = find_gpu_freq()
    pc, (prx, ptx), pt = cpu_total(), net_totals(), time.time()
    last_mode, gpu_state, gpu_t = None, {"util": 0.0, "rows": []}, 0.0
    while True:
        time.sleep(1.0)
        now = time.time()
        dt = max(now - pt, 0.001)
        pt = now
        m = mode
        if m != last_mode:
            prev_scan = None
            if last_mode == "net":
                nh_stop()
            if m == "net":
                nh_start()
            last_mode = m

        tot, idle = cpu_total()
        dtot, didle = tot - pc[0], idle - pc[1]
        pc = (tot, idle)
        cpu = 100.0 * (dtot - didle) / dtot if dtot > 0 else 0.0
        temp = to_int(rd(temp_path)) / 1000.0 if temp_path else 0.0

        mi = meminfo()
        rx, tx = net_totals()
        rxs, txs = max(rx - prx, 0) / dt, max(tx - ptx, 0) / dt
        prx, ptx = rx, tx

        if now - gpu_t >= (0.9 if m == "gpu" else 1.9):
            gpu_state, gpu_t = gpu_scan(), now

        err, rows = "", []
        if m == "cpu":
            rows = cpu_rows()
        elif m == "mem":
            rows = mem_rows()
        elif m == "gpu":
            rows = gpu_state["rows"]
        elif m == "net":
            rows, err = nh["rows"], nh_error()

        print(json.dumps({
            "mode": m,
            "cpu": round(cpu, 1),
            "temp": round(temp, 1),
            "mem_used": mi.get("MemTotal", 0) - mi.get("MemAvailable", 0),
            "mem_total": mi.get("MemTotal", 1),
            "swap_used": mi.get("SwapTotal", 0) - mi.get("SwapFree", 0),
            "swap_total": mi.get("SwapTotal", 0),
            "rx": round(rxs), "tx": round(txs),
            "gpu": round(gpu_state["util"], 1),
            "gpu_freq": to_int(rd(freq_act)) if freq_act else 0,
            "gpu_max": to_int(rd(freq_max)) if freq_max else 0,
            "rows": rows, "err": err,
        }), flush=True)


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, BrokenPipeError):
        pass
