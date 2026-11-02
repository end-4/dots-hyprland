pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Maquinas virtuales de libvirt (qemu:///system). Corre solo mientras `active` sea true.
// Para otra conexion, exporta DASH_VIRSH_URI (p. ej. qemu:///session) en el entorno de Quickshell.
Singleton {
    id: root

    property bool active: false
    property bool ok: true
    property string error: ""
    property string detail: ""
    property var vms: []          // [{name, state, vcpus, cpu, mem, memMax, ip}]
    property var pending: ({})    // nombre -> accion en curso ("start", "shutdown"...)
    property var results: ({})    // nombre -> {cmd, ok, err}; se borra solo tras unos segundos
    property var settling: ({})   // nombres cuya accion termino y esperan al siguiente estado

    readonly property int runningCount: vms.filter(v => v.state === "running").length
    readonly property string errorText: error === "no_virsh"
        ? Translation.tr("virsh is not installed (sudo pacman -S libvirt)")
        : error === "connect_failed"
            ? Translation.tr("Could not connect to libvirt") + (detail ? ": " + detail : "") : error

    // Traduce los errores de virsh mas comunes a algo accionable; el resto se muestra tal cual.
    function describeError(err) {
        const net = /network '([^']+)' is not active/.exec(err);
        if (net)
            return Translation.tr("Network '%1' is not active (sudo virsh net-start %1)").arg(net[1]);
        if (/polkit|authentication|permission denied|access denied/i.test(err))
            return Translation.tr("Permission denied. Add your user to the libvirt group (sudo usermod -aG libvirt $USER) and log in again");
        return err;
    }

    function setKey(obj, name, value) {
        const o = Object.assign({}, obj);   // objeto nuevo: asi los bindings se enteran
        if (value === undefined) delete o[name]; else o[name] = value;
        return o;
    }

    function cmd(c) {
        const i = c.indexOf(":");
        const name = c.slice(i + 1);
        pending = setKey(pending, name, c.slice(0, i));
        results = setKey(results, name, undefined);
        pendingGuard.restart();
        if (proc.running) proc.write(c + "\n");
    }

    function handle(line) {
        let d;
        try { d = JSON.parse(line); } catch (e) { return; }

        if (d.event === "result") {
            results = setKey(results, d.name, { cmd: d.cmd, ok: d.ok, err: d.err, ts: Date.now() });
            settling = setKey(settling, d.name, true);   // el "en curso" se quita con el siguiente estado
            if (!active)   // el sidebar esta cerrado: avisar por notificacion
                Quickshell.execDetached(["notify-send", "-a", "ii", d.ok ? Translation.tr("Done") : Translation.tr("Action failed"),
                    d.name + ": " + (d.ok ? d.cmd : describeError(d.err))]);
            resultsPrune.restart();
            return;
        }

        ok = d.ok === true;
        if (!ok) {
            error = d.err || "connect_failed";
            detail = d.detail || "";
            pending = ({}); settling = ({});
            return;
        }
        error = "";
        vms = d.vms;
        for (const n in settling) pending = setKey(pending, n, undefined);
        settling = ({});
    }

    Timer {   // red de seguridad: si algo no responde, no dejar la VM "en curso" para siempre
        id: pendingGuard
        interval: 40000
        onTriggered: root.pending = ({})
    }
    Timer {   // los errores se muestran ~12 s
        id: resultsPrune
        interval: 12000
        onTriggered: {
            const o = {};
            for (const n in root.results)
                if (Date.now() - root.results[n].ts < 11500) o[n] = root.results[n];
            root.results = o;
            if (Object.keys(o).length > 0) restart();
        }
    }

    Process {
        id: proc
        // Sigue vivo mientras haya acciones pendientes: si el sidebar se cierra al salir el dialogo de polkit,
        // matar el backend cancelaria la autenticacion (el sujeto de polkit es este proceso).
        running: root.active || Object.keys(root.pending).length > 0
        command: ["python3", Quickshell.shellPath("scripts/dash/dashvms.py")]
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => root.handle(line)
        }
    }
}
