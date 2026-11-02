#!/usr/bin/env python3
"""Backend del widget de maquinas virtuales: libvirt via `virsh`.

Conexion: qemu:///system por defecto (cambiala con $DASH_VIRSH_URI).
Imprime un objeto JSON por linea cada ~2 s (o al instante tras un comando).
Comandos por stdin: start:<vm> | shutdown:<vm> | reboot:<vm> | destroy:<vm> | suspend:<vm> | resume:<vm>
"""
import json
import os
import re
import subprocess
import sys
import threading
import time

URI = os.environ.get("DASH_VIRSH_URI", "qemu:///system")
STATES = {0: "nostate", 1: "running", 2: "blocked", 3: "paused",
          4: "shutdown", 5: "shutoff", 6: "crashed", 7: "pmsuspended"}
ACTIONS = ("start", "shutdown", "reboot", "destroy", "suspend", "resume")
wake = threading.Event()
print_lock = threading.Lock()
prev_cpu = {}   # nombre -> (instante, cpu.time en ns)
ip_cache = {}   # nombre -> (instante, ip)


def virsh(*args, timeout=6):
    try:
        r = subprocess.run(["virsh", "-c", URI, *args], stdin=subprocess.DEVNULL,
                           capture_output=True, text=True, timeout=timeout)
    except FileNotFoundError:
        return None, "", ""
    except subprocess.TimeoutExpired:
        return -1, "", "timed out"
    return r.returncode, r.stdout, r.stderr


def emit(obj):
    with print_lock:
        print(json.dumps(obj), flush=True)


def cause(err, out):
    """Ultima linea no vacia del error de virsh (la causa real; la primera suele ser solo 'Failed to ...')."""
    lines = [l.strip() for l in (err or out or "").splitlines() if l.strip()]
    msg = lines[-1] if lines else "virsh failed"
    return msg[len("error: "):] if msg.startswith("error: ") else msg


def to_int(s):
    try:
        return int(s)
    except (TypeError, ValueError):
        return 0


def parse_domstats(out):
    vms, cur = [], None
    for line in out.splitlines():
        if line.startswith("Domain:"):
            m = re.search(r"'(.*)'", line)
            cur = {"name": m.group(1) if m else line.split(":", 1)[1].strip()}
            vms.append(cur)
        elif cur is not None and "=" in line:
            k, _, v = line.strip().partition("=")
            cur[k] = v
    return vms


def get_ip(name):
    t, ip = ip_cache.get(name, (0, ""))
    if time.time() - t < 15:
        return ip
    _rc, out, _err = virsh("domifaddr", name, timeout=4)
    m = re.search(r"ipv4\s+(\d+\.\d+\.\d+\.\d+)/", out or "")
    ip = m.group(1) if m else ""
    ip_cache[name] = (time.time(), ip)
    return ip


def snapshot():
    rc, out, err = virsh("domstats", "--state", "--cpu-total", "--balloon", "--vcpu")
    if rc is None:
        return {"ok": False, "err": "no_virsh"}
    if rc != 0:
        first = next((l for l in err.splitlines() if l.strip()), "")
        return {"ok": False, "err": "connect_failed", "detail": first}
    now, vms = time.time(), []
    for d in parse_domstats(out):
        name = d["name"]
        state = STATES.get(to_int(d.get("state.state")), "nostate")
        vcpus = to_int(d.get("vcpu.current")) or to_int(d.get("vcpu.maximum")) or 1
        cpu = 0.0
        if state == "running":
            ns, p = to_int(d.get("cpu.time")), prev_cpu.get(name)
            if p and ns >= p[1]:
                cpu = min(100.0, (ns - p[1]) / 1e9 / max(now - p[0], 0.1) / vcpus * 100.0)
            prev_cpu[name] = (now, ns)
        else:
            prev_cpu.pop(name, None)
        vms.append({"name": name, "state": state, "vcpus": vcpus, "cpu": round(cpu, 1),
                    "mem": to_int(d.get("balloon.current")), "memMax": to_int(d.get("balloon.maximum")),
                    "ip": get_ip(name) if state == "running" else ""})
    vms.sort(key=lambda v: (v["state"] != "running", v["name"]))
    return {"ok": True, "uri": URI, "vms": vms}


def run_command(c):
    cmd, _, name = c.partition(":")
    if cmd in ACTIONS and name and not name.startswith("-"):
        rc, out, err = virsh(cmd, name, timeout=120)
        ok = rc == 0
        emit({"event": "result", "cmd": cmd, "name": name, "ok": ok,
              "err": "" if ok else ("virsh not found" if rc is None else cause(err, out))})
        ip_cache.pop(name, None)
    wake.set()


def stdin_loop():
    for line in sys.stdin:
        if line.strip():
            threading.Thread(target=run_command, args=(line.strip(),), daemon=True).start()
    os._exit(0)


def main():
    threading.Thread(target=stdin_loop, daemon=True).start()
    while True:
        emit(snapshot())
        wake.wait(2.0)
        wake.clear()


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, BrokenPipeError):
        pass
