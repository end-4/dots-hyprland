pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Puertos en escucha y servicios de systemd. Corre solo mientras `active` sea true.
//  mode "summary": solo contadores (cada 10 s) | "ports" / "services": listas completas (cada 3 s)
Singleton {
    id: root

    property bool active: false
    property string mode: "summary"
    property bool ok: true
    property string error: ""
    property int portCount: 0
    property int exposedCount: 0
    property int failedCount: 0
    property var ports: []
    property var services: []
    property var pending: ({})    // clave de fila -> accion en curso
    property var results: ({})    // clave de fila -> {kind, action, ok, err, ts}
    property var settling: ({})

    readonly property string errorText: error === "no_ss"
        ? Translation.tr("ss is not installed (sudo pacman -S iproute2)") : error

    function describeError(err) {
        if (/interactive authentication|authentication (is )?required|access denied|not authorized|authorization failed|dismissed|cancel/i.test(err))
            return Translation.tr("Authentication failed or unavailable. Make sure a polkit agent is running, then try again");
        return err;
    }

    function setKey(obj, k, v) {
        const o = Object.assign({}, obj);   // objeto nuevo para que los bindings se enteren
        if (v === undefined) delete o[k]; else o[k] = v;
        return o;
    }

    function send(obj) {
        if (proc.running) proc.write(JSON.stringify(obj) + "\n");
    }

    function setMode(m) {
        mode = m;
        if (m !== "ports") ports = [];
        if (m !== "services") services = [];
        send({ cmd: "mode", mode: m });
    }

    function act(key, obj, label) {
        pending = setKey(pending, key, label);
        results = setKey(results, key, undefined);
        guard.restart();
        send(obj);
    }

    function handle(line) {
        let d;
        try { d = JSON.parse(line); } catch (e) { return; }

        if (d.event === "result") {
            results = setKey(results, d.key, { kind: d.kind, action: d.action, ok: d.ok, err: d.err, ts: Date.now() });
            settling = setKey(settling, d.key, true);   // "en curso" se quita con la siguiente instantanea
            if (!active)   // el sidebar esta cerrado: avisar por notificacion
                Quickshell.execDetached(["notify-send", "-a", "ii", d.ok ? Translation.tr("Done") : Translation.tr("Action failed"),
                    d.key + ": " + (d.ok ? d.action : describeError(d.err))]);
            prune.restart();
            return;
        }

        ok = d.ok === true;
        if (!ok) {
            error = d.err || "";
            pending = ({}); settling = ({});
            return;
        }
        error = "";
        portCount = d.summary.ports;
        exposedCount = d.summary.exposed;
        failedCount = d.summary.failed;
        if (d.mode === mode) {
            ports = d.ports;
            services = d.services;
        }
        for (const k in settling) pending = setKey(pending, k, undefined);
        settling = ({});
    }

    Timer {   // red de seguridad: no dejar una fila "en curso" para siempre (pkexec espera a la contraseña)
        id: guard
        interval: 130000
        onTriggered: root.pending = ({})
    }
    Timer {   // los resultados (errores) se muestran ~12 s
        id: prune
        interval: 12000
        onTriggered: {
            const o = {};
            for (const k in root.results)
                if (Date.now() - root.results[k].ts < 11500) o[k] = root.results[k];
            root.results = o;
            if (Object.keys(o).length > 0) restart();
        }
    }

    Process {
        id: proc
        // Sigue vivo mientras haya acciones pendientes (ver Vms.qml): evita cancelar la autenticacion de polkit.
        running: root.active || Object.keys(root.pending).length > 0
        command: ["python3", Quickshell.shellPath("scripts/dash/dashsys.py"), root.mode]
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => root.handle(line)
        }
    }
}
