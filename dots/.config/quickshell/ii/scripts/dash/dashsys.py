#!/usr/bin/env python3
"""Backend del widget de puertos y servicios.

Modos (por stdin): summary (solo contadores, cada 10 s) | ports | services (cada 3 s).
Puertos: `ss -H -tulpn`. Sin privilegios `ss` solo muestra el proceso de TUS sockets; para los del sistema
hay un comando `reveal` que ejecuta `pkexec ss` una vez y recuerda el resultado 3 minutos.
Servicios: `systemctl` (sistema y --user). Las acciones usan polkit via systemctl, sin pkexec.

Comandos por stdin (una linea JSON cada uno):
  {"cmd":"mode","mode":"ports"}
  {"cmd":"svc","scope":"system|user","action":"start|stop|restart|enable|disable|freeze|thaw","unit":"x.service","key":"..."}
  {"cmd":"kill","pid":123,"sig":"TERM|KILL","comm":"nombre","key":"..."}
  {"cmd":"reveal","key":"..."}
Salida: un JSON por linea: instantaneas y eventos {"event":"result",...}.
"""
import json
import os
import re
import signal
import subprocess
import sys
import threading
import time

UID = os.getuid()
MODES = ("summary", "ports", "services")
mode = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] in MODES else "summary"
wake = threading.Event()
print_lock = threading.Lock()
owners = {}              # (proto, puerto) -> (proceso, pid, instante) tras "reveal"
OWNERS_TTL = 180
RANK = {"local": 0, "lan": 1, "all": 2}
NAMES = {v: k for k, v in RANK.items()}
UNIT_RE = re.compile(r"^[A-Za-z0-9:_.@-]+\.service$")
PROC_RE = re.compile(r'\("([^"]*)",pid=(\d+)')
# Servicios cuya parada puede romper la sesion o la red: la interfaz pide confirmacion extra.
CRITICAL_RE = re.compile(r"^(systemd-.*|dbus(-broker)?|polkit|NetworkManager|wpa_supplicant|iwd|user@\d+|"
                         r"user-runtime-dir@\d+|getty@.*|sddm|gdm|lightdm|greetd|ly|seatd|elogind|display-manager)\.service$")
ACTIONS = {"start": ["start"], "stop": ["stop"], "restart": ["restart"],
           "enable": ["enable", "--now"], "disable": ["disable", "--now"],
           "freeze": ["freeze"], "thaw": ["thaw"]}


def emit(obj):
    with print_lock:
        print(json.dumps(obj), flush=True)


def run(cmd, timeout=8):
    try:
        r = subprocess.run(cmd, stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=timeout)
    except FileNotFoundError:
        return None, "", ""
    except subprocess.TimeoutExpired:
        return -1, "", "timed out"
    return r.returncode, r.stdout, r.stderr


def cause(err, out):
    """Ultima linea no vacia del error (la causa real)."""
    lines = [l.strip() for l in (err or out or "").splitlines() if l.strip()]
    msg = lines[-1] if lines else "command failed"
    return msg[len("error: "):] if msg.startswith("error: ") else msg


# ---------------------------------------------------------------- puertos
def exposure(addr):
    if addr in ("*", "0.0.0.0", "::", ""):
        return "all"
    if addr.startswith("127.") or addr == "::1":
        return "local"
    return "lan"


def parse_ss(out):
    rows = {}
    for line in out.splitlines():
        f = line.split(None, 6)
        if len(f) < 5 or f[0] not in ("tcp", "udp"):
            continue
        if f[0] == "tcp" and f[1] != "LISTEN":
            continue
        addr, _, port = f[4].rpartition(":")
        if not port.isdigit():
            continue
        addr = addr.strip("[]").split("%")[0] or "*"
        key = "%s:%s" % (f[0], port)
        r = rows.setdefault(key, {"key": key, "proto": f[0], "port": int(port), "addrs": [],
                                  "rank": 0, "proc": "", "pid": 0})
        if addr not in r["addrs"]:
            r["addrs"].append(addr)
        r["rank"] = max(r["rank"], RANK[exposure(addr)])
        pm = PROC_RE.search(f[6]) if len(f) > 6 else None
        if pm and not r["pid"]:
            r["proc"], r["pid"] = pm.group(1), int(pm.group(2))
    return rows


def pid_info(pid):
    try:
        uid = os.stat("/proc/%d" % pid).st_uid
        cg = open("/proc/%d/cgroup" % pid).read()
        comm = open("/proc/%d/comm" % pid).read().strip()
    except OSError:
        return None
    path = next((l[3:] for l in cg.splitlines() if l.startswith("0::")), "")
    units = re.findall(r"/([^/]+\.service)(?=/|$)", path)
    return {"own": uid == UID, "comm": comm, "unit": units[-1] if units else "",
            "uscope": "user" if "/user@" in path else "system"}


def finalize_ports(rows):
    now, out = time.time(), []
    for key, r in rows.items():
        if not r["pid"]:
            o = owners.get((r["proto"], r["port"]))
            if o and now - o[2] < OWNERS_TTL:
                r["proc"], r["pid"] = o[0], o[1]
        info = pid_info(r["pid"]) if r["pid"] else None
        unit = info["unit"] if info else ""
        out.append({"key": key, "proto": r["proto"], "port": r["port"], "addrs": ", ".join(r["addrs"]),
                    "exposure": NAMES[r["rank"]], "proc": r["proc"], "pid": r["pid"],
                    "own": bool(info and info["own"]), "comm": info["comm"] if info else "",
                    "unit": unit, "uscope": info["uscope"] if info else "",
                    "critical": bool(unit and CRITICAL_RE.match(unit))})
    out.sort(key=lambda p: (-RANK[p["exposure"]], p["port"]))
    return out


# ---------------------------------------------------------------- servicios
def list_services(scope):
    base = ["systemctl"] + (["--user"] if scope == "user" else [])
    rc, out, _ = run(base + ["list-units", "--type=service", "--all", "--no-legend", "--no-pager", "--plain", "--full"], 15)
    if rc != 0:
        return []
    units = {}
    for line in out.splitlines():
        p = line.split(None, 4)
        if len(p) < 4:
            continue
        name, load, active, sub = p[:4]
        if load == "not-found" or "@." in name or not name.endswith(".service"):
            continue
        units[name] = {"key": "%s:%s" % (scope, name), "name": name[:-8], "unit": name, "scope": scope,
                       "desc": p[4].strip() if len(p) > 4 else "", "active": active, "sub": sub,
                       "enabled": "", "frozen": False, "mem": 0,
                       "critical": bool(CRITICAL_RE.match(name))}
    rc, out, _ = run(base + ["list-unit-files", "--type=service", "--no-legend", "--no-pager"], 15)
    states = {}
    for line in out.splitlines() if rc == 0 else []:
        p = line.split()
        if len(p) >= 2:
            states[p[0]] = p[1]
    for name, u in units.items():
        u["enabled"] = states.get(name) or states.get(re.sub(r"@.*\.service$", "@.service", name), "")
    running = [n for n, u in units.items() if u["active"] in ("active", "activating")]
    for i in range(0, len(running), 120):
        chunk = running[i:i + 120]
        rc, out, _ = run(base + ["show", "-p", "Id", "-p", "FreezerState", "-p", "MemoryCurrent"] + chunk, 15)
        for block in out.split("\n\n") if rc == 0 else []:
            kv = dict(l.split("=", 1) for l in block.splitlines() if "=" in l)
            u = units.get(kv.get("Id", ""))
            if not u:
                continue
            u["frozen"] = kv.get("FreezerState") == "frozen"
            mc = kv.get("MemoryCurrent", "")
            u["mem"] = int(mc) if mc.isdigit() and int(mc) < 2 ** 62 else 0
    return list(units.values())


def count_failed():
    n = 0
    for scope in ("system", "user"):
        base = ["systemctl"] + (["--user"] if scope == "user" else [])
        rc, out, _ = run(base + ["list-units", "--type=service", "--failed", "--no-legend", "--no-pager", "--plain"])
        if rc == 0:
            n += len([l for l in out.splitlines() if l.strip()])
    return n


def snapshot(m):
    rc, out, _ = run(["ss", "-H", "-tulpn"])
    if rc is None:
        return {"mode": m, "ok": False, "err": "no_ss"}
    ports = finalize_ports(parse_ss(out))
    services = []
    if m == "services":
        services = sorted(list_services("system") + list_services("user"),
                          key=lambda s: (s["active"] != "failed", s["name"].lower(), s["scope"]))
        failed = sum(1 for s in services if s["active"] == "failed")
    else:
        failed = count_failed()
    return {"mode": m, "ok": True, "err": "",
            "summary": {"ports": len(ports), "exposed": sum(1 for p in ports if p["exposure"] == "all"),
                        "failed": failed},
            "ports": ports if m == "ports" else [], "services": services}


# ---------------------------------------------------------------- comandos
def result(kind, key, action, ok, err=""):
    emit({"event": "result", "kind": kind, "key": key, "action": action, "ok": ok, "err": err})


def cmd_svc(c):
    key, action, unit, scope = c.get("key", ""), c.get("action"), c.get("unit") or "", c.get("scope")
    if scope not in ("system", "user") or action not in ACTIONS or not UNIT_RE.match(unit):
        return result("svc", key, action, False, "invalid request")
    cmd = ["systemctl"] + (["--user"] if scope == "user" else []) + ACTIONS[action] + [unit]
    rc, out, err = run(cmd, 120)   # margen para escribir la contrasena en el dialogo de polkit
    result("svc", key, action, rc == 0, "" if rc == 0 else ("systemctl not found" if rc is None else cause(err, out)))
    wake.set()


def cmd_kill(c):
    key = c.get("key", "")
    ok, err = False, ""
    try:
        pid = int(c.get("pid", 0))
        sig = {"TERM": signal.SIGTERM, "KILL": signal.SIGKILL}.get(c.get("sig"))
        if pid <= 1 or sig is None:
            raise ValueError("invalid request")
        if os.stat("/proc/%d" % pid).st_uid != UID:
            raise PermissionError("not your process")
        if open("/proc/%d/comm" % pid).read().strip() != c.get("comm", ""):
            raise ValueError("the process changed")   # evita matar otro proceso que reutilizo el PID
        os.kill(pid, sig)
        ok = True
    except (OSError, ValueError) as e:
        err = str(e)
    result("kill", key, c.get("sig"), ok, err)
    wake.set()


def cmd_reveal(c):
    key = c.get("key", "")
    rc, out, err = run(["pkexec", "ss", "-H", "-tulpn"], 120)
    if rc == 0:
        now = time.time()
        for r in parse_ss(out).values():
            if r["pid"]:
                owners[(r["proto"], r["port"])] = (r["proc"], r["pid"], now)
    result("reveal", key, "reveal", rc == 0,
           "" if rc == 0 else ("pkexec not found" if rc is None else cause(err, out)))
    wake.set()


def handle_line(line):
    global mode
    try:
        c = json.loads(line)
    except ValueError:
        return
    k = c.get("cmd")
    if k == "mode" and c.get("mode") in MODES:
        mode = c["mode"]
        wake.set()
    elif k == "svc":
        threading.Thread(target=cmd_svc, args=(c,), daemon=True).start()
    elif k == "kill":
        threading.Thread(target=cmd_kill, args=(c,), daemon=True).start()
    elif k == "reveal":
        threading.Thread(target=cmd_reveal, args=(c,), daemon=True).start()


def stdin_loop():
    for line in sys.stdin:
        handle_line(line)
    os._exit(0)


def main():
    threading.Thread(target=stdin_loop, daemon=True).start()
    while True:
        m = mode
        emit(snapshot(m))
        wake.wait(10.0 if m == "summary" else 3.0)
        wake.clear()


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, BrokenPipeError):
        pass
