pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Tailscale exit-node state and control.
 *
 * Polls `tailscale status --json` and exposes the peers that offer to be an
 * exit node, plus which one (if any) is currently selected. Selecting a node
 * runs `tailscale set --exit-node=…`; on machines where the user is not the
 * Tailscale operator this fails, so it falls back to `pkexec` (a polkit
 * prompt). Run `sudo tailscale set --operator=$USER` once to skip the prompt.
 */
Singleton {
    id: root

    readonly property int fetchInterval: 5000 // 5 seconds

    property bool available: false // CLI present and responded
    property bool running: false // BackendState === "Running"
    property string currentExitNodeId: "" // peer ID of active exit node, "" if none
    property string lastError: ""
    // list of { id, name, ip, online, selected }
    property var exitNodes: []

    readonly property bool exitNodeActive: root.currentExitNodeId.length > 0
    readonly property string currentExitNodeName: {
        for (let i = 0; i < root.exitNodes.length; i++)
            if (root.exitNodes[i].selected)
                return root.exitNodes[i].name;
        return "";
    }

    function refresh() {
        fetcher.running = false;
        fetcher.running = true;
    }

    // Prefer the IPv4 address (cleaner for `--exit-node=`), fall back to first.
    function _ip4(ips) {
        if (!ips || ips.length === 0)
            return "";
        for (let i = 0; i < ips.length; i++) {
            const bare = ips[i].split("/")[0];
            if (bare.indexOf(":") === -1)
                return bare;
        }
        return ips[0].split("/")[0];
    }

    function refine(data) {
        root.running = (data.BackendState === "Running");
        const exitId = data.ExitNodeStatus?.ID ?? "";
        const nodes = [];
        const peers = data.Peer ?? {};
        for (const key in peers) {
            const p = peers[key];
            if (!p.ExitNodeOption)
                continue;
            nodes.push({
                id: p.ID ?? "",
                name: p.HostName ?? "?",
                ip: root._ip4(p.TailscaleIPs),
                online: p.Online ?? false,
                selected: (p.ExitNode === true) || (exitId.length > 0 && p.ID === exitId)
            });
        }
        // Online first, then alphabetical.
        nodes.sort((a, b) => {
            if (a.online !== b.online)
                return a.online ? -1 : 1;
            return a.name.localeCompare(b.name);
        });
        root.exitNodes = nodes;
        root.currentExitNodeId = exitId;
        root.available = true;
        root.lastError = "";
    }

    function _run(exitArg) {
        // Try as operator; fall back to polkit if access is denied.
        const base = `tailscale set --exit-node=${exitArg}`;
        setter.command = ["bash", "-c", `${base} 2>/dev/null || pkexec ${base}`];
        setter.running = false;
        setter.running = true;
    }

    function setExitNode(ip) {
        root._run(`${ip} --exit-node-allow-lan-access=true`);
    }

    function clearExitNode() {
        root._run("");
    }

    Process {
        id: fetcher
        command: ["tailscale", "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                if (t.length === 0) {
                    root.available = false;
                    root.lastError = "no response";
                    return;
                }
                try {
                    root.refine(JSON.parse(t));
                } catch (e) {
                    root.available = false;
                    root.lastError = e.message;
                    console.error(`[Tailscale] ${e.message}: ${t}`);
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    root.available = false;
                    root.lastError = text.trim();
                }
            }
        }
    }

    Process {
        id: setter
        // Re-read state as soon as a change lands.
        onExited: root.refresh()
    }

    Timer {
        running: true
        repeat: true
        interval: root.fetchInterval
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
