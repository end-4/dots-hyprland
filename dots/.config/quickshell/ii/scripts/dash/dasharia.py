#!/usr/bin/env python3
"""Backend del widget de descargas: cliente JSON-RPC de aria2.

Lee puerto y secreto de aria2.conf en tiempo de ejecucion (nada se guarda en el repo).
Orden de busqueda: $ARIA2_CONF, ~/.config/aria2/aria2.conf, ~/.aria2/aria2.conf, /etc/aria2/aria2.conf.
$ARIA2_RPC_SECRET y $ARIA2_RPC_PORT tienen prioridad sobre el archivo.

Imprime un objeto JSON por linea cada ~1 s (o al instante tras un comando).
Comandos por stdin: pause:<gid> | resume:<gid> | remove:<gid> | pauseAll | resumeAll | purge
"""
import json
import os
import sys
import threading
import urllib.error
import urllib.parse
import urllib.request

KEYS = ["gid", "status", "totalLength", "completedLength", "downloadSpeed",
        "uploadSpeed", "connections", "files", "bittorrent", "errorMessage"]
wake = threading.Event()
status_of = {}


def load_conf():
    paths = [os.environ.get("ARIA2_CONF", ""), "~/.config/aria2/aria2.conf",
             "~/.aria2/aria2.conf", "/etc/aria2/aria2.conf"]
    conf = {}
    for p in paths:
        p = os.path.expanduser(p) if p else ""
        if not p or not os.path.isfile(p):
            continue
        try:
            with open(p) as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#") and "=" in line:
                        k, _, v = line.partition("=")
                        conf.setdefault(k.strip(), v.strip())
        except OSError:
            continue
        break  # usa el primer archivo que exista
    return conf


class Rpc:
    def __init__(self):
        c = load_conf()
        self.port = int(os.environ.get("ARIA2_RPC_PORT") or c.get("rpc-listen-port", 6800))
        self.secret = os.environ.get("ARIA2_RPC_SECRET") or c.get("rpc-secret", "")
        self.url = "http://127.0.0.1:%d/jsonrpc" % self.port

    def call(self, method, *params):
        p = list(params)
        if self.secret:
            p.insert(0, "token:" + self.secret)
        body = json.dumps({"jsonrpc": "2.0", "id": "ii", "method": method, "params": p}).encode()
        req = urllib.request.Request(self.url, body, {"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=3) as r:
                d = json.loads(r.read())
        except urllib.error.HTTPError as e:   # aria2 responde 400 con el error en el cuerpo
            try:
                d = json.loads(e.read())
            except ValueError:
                raise RuntimeError("HTTP %d" % e.code)
        if "error" in d:
            raise RuntimeError(d["error"].get("message", "error de aria2"))
        return d["result"]


rpc = Rpc()


def to_int(s):
    try:
        return int(s)
    except (TypeError, ValueError):
        return 0


def norm(t):
    files = t.get("files") or []
    bt = t.get("bittorrent") or {}
    name = (bt.get("info") or {}).get("name", "")
    if not name and files and files[0].get("path"):
        name = os.path.basename(files[0]["path"])
    if not name and files and files[0].get("uris"):
        name = os.path.basename(urllib.parse.unquote(urllib.parse.urlparse(files[0]["uris"][0]["uri"]).path))
    return {"gid": t.get("gid", ""), "name": name or t.get("gid", "?"),
            "status": t.get("status", ""), "total": to_int(t.get("totalLength")),
            "done": to_int(t.get("completedLength")), "speed": to_int(t.get("downloadSpeed")),
            "up": to_int(t.get("uploadSpeed")), "conns": to_int(t.get("connections")),
            "err": t.get("errorMessage", "")}


def snapshot():
    try:
        g = rpc.call("aria2.getGlobalStat")
        act = [norm(t) for t in rpc.call("aria2.tellActive", KEYS)]
        wai = [norm(t) for t in rpc.call("aria2.tellWaiting", 0, 30, KEYS)]
        sto = [norm(t) for t in rpc.call("aria2.tellStopped", -1, 50, KEYS)]  # -1: las mas recientes primero
    except urllib.error.URLError:
        return {"ok": False, "err": "unreachable", "port": rpc.port}
    except (RuntimeError, ValueError, OSError) as e:
        return {"ok": False, "err": str(e)}
    status_of.clear()
    for t in act + wai + sto:
        status_of[t["gid"]] = t["status"]
    return {"ok": True,
            "stat": {"dl": to_int(g.get("downloadSpeed")), "ul": to_int(g.get("uploadSpeed")),
                     "active": to_int(g.get("numActive")), "waiting": to_int(g.get("numWaiting")),
                     "stopped": to_int(g.get("numStopped", g.get("numStoppedTotal")))},
            "active": act, "waiting": wai, "stopped": sto}


def run_command(c):
    cmd, _, gid = c.partition(":")
    try:
        if cmd == "pause":
            rpc.call("aria2.forcePause", gid)
        elif cmd == "resume":
            rpc.call("aria2.unpause", gid)
        elif cmd == "remove":
            if status_of.get(gid) in ("complete", "error", "removed"):
                rpc.call("aria2.removeDownloadResult", gid)
            else:
                rpc.call("aria2.forceRemove", gid)
        elif cmd == "pauseAll":
            rpc.call("aria2.forcePauseAll")
        elif cmd == "resumeAll":
            rpc.call("aria2.unpauseAll")
        elif cmd == "purge":
            rpc.call("aria2.purgeDownloadResult")
    except (RuntimeError, ValueError, OSError):
        pass
    wake.set()


def stdin_loop():
    for line in sys.stdin:
        c = line.strip()
        if c:
            threading.Thread(target=run_command, args=(c,), daemon=True).start()
    os._exit(0)


def main():
    threading.Thread(target=stdin_loop, daemon=True).start()
    while True:
        print(json.dumps(snapshot()), flush=True)
        wake.wait(1.0)
        wake.clear()


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, BrokenPipeError):
        pass
