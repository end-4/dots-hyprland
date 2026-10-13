pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string interfaceName: ""
    property real rxBytesPerSecond: 0
    property real txBytesPerSecond: 0
    property string downloadSpeedText: formatSpeed(rxBytesPerSecond)
    property string uploadSpeedText: formatSpeed(txBytesPerSecond)
    property string downloadSpeedCompactText: formatCompactSpeed(rxBytesPerSecond)
    property string uploadSpeedCompactText: formatCompactSpeed(txBytesPerSecond)
    readonly property bool available: interfaceName.length > 0

    property real previousRxBytes: -1
    property real previousTxBytes: -1
    property double previousTimestampMs: 0

    function formatSpeed(bytesPerSecond) {
        const units = ["B/s", "K/s", "M/s", "G/s"];
        let value = Math.max(0, bytesPerSecond);
        let unitIndex = 0;

        while (value >= 1024 && unitIndex < units.length - 1) {
            value /= 1024;
            unitIndex++;
        }

        const precision = value >= 100 ? 0 : value >= 10 ? 1 : 2;
        return `${value.toFixed(precision)}${units[unitIndex]}`;
    }

    function formatCompactSpeed(bytesPerSecond) {
        const units = ["B", "K", "M", "G"];
        let value = Math.max(0, bytesPerSecond);
        let unitIndex = 0;

        while (value >= 1024 && unitIndex < units.length - 1) {
            value /= 1024;
            unitIndex++;
        }

        let textValue = "0";
        if (value >= 100)
            textValue = `${Math.round(value)}`;
        else if (value >= 10)
            textValue = `${Math.round(value)}`;
        else
            textValue = `${value.toFixed(1)}`.replace(/\.0$/, "");

        return `${textValue}${units[unitIndex]}/s`;
    }

    function pickInterfaceName(routeText, devText) {
        const routeLines = routeText.trim().split("\n").slice(1);
        for (const line of routeLines) {
            const columns = line.trim().split(/\s+/);
            if (columns.length < 2)
                continue;

            const iface = columns[0];
            const destination = columns[1];
            if (destination === "00000000" && iface !== "lo")
                return iface;
        }

        const devLines = devText.trim().split("\n").slice(2);
        for (const line of devLines) {
            const iface = line.split(":")[0]?.trim() ?? "";
            if (iface.length > 0 && iface !== "lo")
                return iface;
        }

        return "";
    }

    function parseCounters(devText, ifaceName) {
        if (!ifaceName)
            return null;

        const escapedName = ifaceName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
        const lineMatch = devText.match(new RegExp(`^\\s*${escapedName}\\s*:\\s*(.+)$`, "m"));
        if (!lineMatch)
            return null;

        const fields = lineMatch[1].trim().split(/\s+/);
        if (fields.length < 9)
            return null;

        return {
            rx: Number(fields[0]),
            tx: Number(fields[8])
        };
    }

    function update() {
        routeFile.reload();
        devFile.reload();

        const routeText = routeFile.text();
        const devText = devFile.text();
        const detectedInterface = pickInterfaceName(routeText, devText);

        if (detectedInterface !== interfaceName) {
            interfaceName = detectedInterface;
            previousRxBytes = -1;
            previousTxBytes = -1;
            previousTimestampMs = 0;
        }

        if (!interfaceName) {
            rxBytesPerSecond = 0;
            txBytesPerSecond = 0;
            return;
        }

        const counters = parseCounters(devText, interfaceName);
        if (!counters) {
            rxBytesPerSecond = 0;
            txBytesPerSecond = 0;
            return;
        }

        const now = Date.now();

        if (previousRxBytes < 0 || previousTxBytes < 0 || previousTimestampMs <= 0) {
            previousRxBytes = counters.rx;
            previousTxBytes = counters.tx;
            previousTimestampMs = now;
            rxBytesPerSecond = 0;
            txBytesPerSecond = 0;
            return;
        }

        const elapsedMs = Math.max(1, now - previousTimestampMs);
        rxBytesPerSecond = Math.max(0, (counters.rx - previousRxBytes) * 1000 / elapsedMs);
        txBytesPerSecond = Math.max(0, (counters.tx - previousTxBytes) * 1000 / elapsedMs);

        previousRxBytes = counters.rx;
        previousTxBytes = counters.tx;
        previousTimestampMs = now;
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.update()
    }

    FileView { id: routeFile; path: "/proc/net/route" }
    FileView { id: devFile; path: "/proc/net/dev" }
}
