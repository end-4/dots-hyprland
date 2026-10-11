pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.functions as CF

/**
 * Service managing display configuration, multi-monitor topology,
 * interactive arrangement, hardware specs, and Hyprland Lua persistence.
 */
Singleton {
    id: root

    // ================= Hardware / Discovered Displays =================
    property var displays: []
    property var pendingDisplays: []
    property var appliedSnapshot: []
    property string selectedDisplayName: ""
    property bool loading: false
    property bool dirty: false

    // ================= Safety & Revert Timer =================
    property bool safetyDialogVisible: false
    property int safetyCountdown: 15

    // ================= Screen Identification =================
    property bool identifyVisible: false
    property bool identifyAnimActive: false

    readonly property string monitorsConfigPath: CF.FileUtils.trimFileProtocol(`${Directories.config}/hypr/monitors.lua`)

    // Helper to get selected display object from pendingDisplays
    readonly property var selectedDisplay: {
        for (let i = 0; i < pendingDisplays.length; i++) {
            if (pendingDisplays[i].name === selectedDisplayName) {
                return pendingDisplays[i];
            }
        }
        return pendingDisplays.length > 0 ? pendingDisplays[0] : null;
    }

    // Helper to get original specs for selected display from displays
    readonly property var selectedDisplaySpecs: {
        for (let i = 0; i < displays.length; i++) {
            if (displays[i].name === selectedDisplayName) {
                return displays[i];
            }
        }
        return displays.length > 0 ? displays[0] : null;
    }

    // Timer for safety auto-revert
    Timer {
        id: revertTimer
        interval: 1000
        repeat: true
        running: root.safetyDialogVisible
        onTriggered: {
            if (root.safetyCountdown > 1) {
                root.safetyCountdown--;
            } else {
                root.safetyCountdown = 0;
                root.revert();
            }
        }
    }

    // Timer to automatically hide identification overlay after 3.5s
    Timer {
        id: identifyTimer
        interval: 3500
        repeat: false
        onTriggered: {
            root.identifyAnimActive = false;
            identifyCloseTimer.restart();
        }
    }

    // Timer allowing exit animation to complete before removing overlay window
    Timer {
        id: identifyCloseTimer
        interval: 280
        repeat: false
        onTriggered: {
            root.identifyVisible = false;
        }
    }

    function dismissIdentify() {
        identifyTimer.stop();
        root.identifyAnimActive = false;
        identifyCloseTimer.restart();
    }

    function identifyDisplays() {
        identifyCloseTimer.stop();
        root.identifyVisible = true;
        root.identifyAnimActive = true;
        identifyTimer.restart();
    }

    // ================= Dynamic GPU & Graphics Telemetry =================
    property var gpuInfo: ({
        primaryRenderer: "",
        gpus: [],
        connectors: {},
        hasDgpu: false,
        dgpu: null,
        isHybrid: false,
        offloadCommand: "",
        offloadPrefix: ""
    })

    readonly property string gpuDetectScriptPath: CF.FileUtils.trimFileProtocol(`${Directories.config}/quickshell/ii/scripts/hyprland/gpu_detect.py`)

    Process {
        id: gpuDetectProc
        command: [root.gpuDetectScriptPath]
        stdout: StdioCollector {
            id: gpuDetectCollector
            onStreamFinished: {
                try {
                    let text = gpuDetectCollector.text.trim();
                    if (text.length > 0) {
                        let raw = JSON.parse(text);
                        root.gpuInfo = raw;
                    }
                } catch (e) {
                    console.warn("[DisplayService] Failed to parse gpu_detect output:", e);
                }
            }
        }
    }

    function refreshGpuStats() {
        if (!gpuDetectProc.running) {
            gpuDetectProc.running = true;
        }
    }

    // Refresh displays from hyprctl
    function refresh() {
        refreshGpuStats();
        if (!getMonitorsProc.running) {
            root.loading = true;
            getMonitorsProc.running = true;
        }
    }

    Process {
        id: getMonitorsProc
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            id: monitorsCollector
            onStreamFinished: {
                root.loading = false;
                try {
                    let text = monitorsCollector.text ? monitorsCollector.text.trim() : "";
                    if (!text) return;
                    let raw = JSON.parse(text);
                    if (!Array.isArray(raw)) return;
                    root.displays = raw;

                    // Initialize pendingDisplays if empty or when requested
                    let newPending = [];
                    for (let i = 0; i < raw.length; i++) {
                        let m = raw[i];
                        let modeStr = `${m.width}x${m.height}@${Number(m.refreshRate).toFixed(2)}`;
                        newPending.push({
                            name: m.name,
                            id: m.id,
                            description: m.description || "",
                            make: m.make || "",
                            model: m.model || "",
                            serial: m.serial || "",
                            width: m.width,
                            height: m.height,
                            physicalWidth: m.physicalWidth || 0,
                            physicalHeight: m.physicalHeight || 0,
                            refreshRate: m.refreshRate,
                            mode: modeStr,
                            x: m.x,
                            y: m.y,
                            scale: m.scale || 1.0,
                            transform: m.transform || 0,
                            vrr: (m.vrr === true || m.vrr === 1) ? 1 : (m.vrr === 2 ? 2 : 0),
                            disabled: m.disabled || false,
                            mirror: (m.mirrorOf && m.mirrorOf !== "none") ? m.mirrorOf : "",
                            availableModes: m.availableModes || [],
                            currentFormat: m.currentFormat || "XRGB8888",
                            dpmsStatus: m.dpmsStatus !== undefined ? m.dpmsStatus : true,
                            focused: m.focused || false
                        });
                    }
                    root.pendingDisplays = newPending;
                    root.appliedSnapshot = JSON.parse(JSON.stringify(newPending));
                    root.dirty = false;

                    if (!root.selectedDisplayName && newPending.length > 0) {
                        let focused = newPending.find(d => d.focused);
                        root.selectedDisplayName = focused ? focused.name : newPending[0].name;
                    }
                } catch (e) {
                    console.warn("[DisplayService] Failed to parse monitors JSON:", e);
                }
            }
        }
    }

    // Update single property of a display in pendingDisplays
    function updateDisplayProp(name, prop, value) {
        let copy = JSON.parse(JSON.stringify(root.pendingDisplays));
        for (let i = 0; i < copy.length; i++) {
            if (copy[i].name === name) {
                copy[i][prop] = value;
                break;
            }
        }
        root.pendingDisplays = copy;
        checkDirty();
    }

    // Set position coordinates directly
    function setPosition(name, newX, newY) {
        let copy = JSON.parse(JSON.stringify(root.pendingDisplays));
        for (let i = 0; i < copy.length; i++) {
            if (copy[i].name === name) {
                copy[i].x = Math.round(newX);
                copy[i].y = Math.round(newY);
                break;
            }
        }
        root.pendingDisplays = copy;
        checkDirty();
    }

    // Check if pendingDisplays differs from appliedSnapshot
    function checkDirty() {
        if (!root.appliedSnapshot || root.appliedSnapshot.length !== root.pendingDisplays.length) {
            root.dirty = true;
            return;
        }
        for (let i = 0; i < root.pendingDisplays.length; i++) {
            let p = root.pendingDisplays[i];
            let a = root.appliedSnapshot.find(d => d.name === p.name);
            if (!a) {
                root.dirty = true;
                return;
            }
            if (p.x !== a.x || p.y !== a.y || p.scale !== a.scale ||
                p.mode !== a.mode || p.transform !== a.transform ||
                p.vrr !== a.vrr || p.disabled !== a.disabled || p.mirror !== a.mirror) {
                root.dirty = true;
                return;
            }
        }
        root.dirty = false;
    }

    // Quick alignment presets
    function alignDisplays(type) {
        let copy = JSON.parse(JSON.stringify(root.pendingDisplays));
        let activeList = copy.filter(d => !d.disabled);
        if (activeList.length <= 1) return;

        if (type === "left-to-right") {
            // Sort by current X position
            activeList.sort((a, b) => a.x - b.x);
            let currentX = 0;
            for (let i = 0; i < activeList.length; i++) {
                activeList[i].x = currentX;
                activeList[i].y = 0;
                let effW = (activeList[i].transform === 1 || activeList[i].transform === 3) ? activeList[i].height : activeList[i].width;
                let logW = Math.round(effW / (activeList[i].scale || 1.0));
                currentX += logW;
            }
        } else if (type === "right-to-left") {
            activeList.sort((a, b) => b.x - a.x);
            let currentX = 0;
            for (let i = 0; i < activeList.length; i++) {
                activeList[i].x = currentX;
                activeList[i].y = 0;
                let effW = (activeList[i].transform === 1 || activeList[i].transform === 3) ? activeList[i].height : activeList[i].width;
                let logW = Math.round(effW / (activeList[i].scale || 1.0));
                currentX += logW;
            }
        } else if (type === "stacked") {
            // Vertical stacking: external top, laptop bottom
            let currentY = 0;
            for (let i = 0; i < activeList.length; i++) {
                activeList[i].x = 0;
                activeList[i].y = currentY;
                let effH = (activeList[i].transform === 1 || activeList[i].transform === 3) ? activeList[i].width : activeList[i].height;
                let logH = Math.round(effH / (activeList[i].scale || 1.0));
                currentY += logH;
            }
        }

        // Re-integrate into copy
        for (let i = 0; i < copy.length; i++) {
            let updated = activeList.find(d => d.name === copy[i].name);
            if (updated) {
                copy[i].x = updated.x;
                copy[i].y = updated.y;
            }
        }
        root.pendingDisplays = copy;
        checkDirty();
    }

    // Build Lua commands to execute via hyprctl eval
    function buildLuaString(displayList) {
        let commands = [];
        for (let i = 0; i < displayList.length; i++) {
            let d = displayList[i];
            let posX = Math.round(d.x || 0);
            let posY = Math.round(d.y || 0);
            let posStr = `"${posX}x${posY}"`;
            let modeVal = (d.mode && d.mode.length > 0) ? d.mode : "preferred";
            let modeStr = d.disabled ? "\"disable\"" : `"${modeVal}"`;
            let scaleVal = d.scale || 1.0;
            let transformVal = d.transform || 0;
            let vrrVal = d.vrr || 0;
            let disabledBool = d.disabled ? "true" : "false";

            let tbl = `output = "${d.name}", mode = ${modeStr}, position = ${posStr}, scale = ${scaleVal}, transform = ${transformVal}, vrr = ${vrrVal}, disabled = ${disabledBool}`;
            if (d.mirror && d.mirror !== "none" && !d.disabled) {
                tbl += `, mirror = "${d.mirror}"`;
            }
            commands.push(`hl.monitor({ ${tbl} })`);
        }
        return commands.join("; ");
    }

    // Apply pending settings live using hyprctl eval
    function applyLive(withSafety) {
        if (withSafety === undefined) withSafety = true;

        let lua = buildLuaString(root.pendingDisplays);
        let evalProcess = Quickshell.execDetached(["hyprctl", "eval", lua]);

        if (withSafety) {
            root.safetyCountdown = 15;
            root.safetyDialogVisible = true;
        } else {
            root.appliedSnapshot = JSON.parse(JSON.stringify(root.pendingDisplays));
            root.dirty = false;
        }
    }

    // User confirmed changes: commit permanently to ~/.config/hypr/monitors.lua
    function confirmChanges() {
        root.safetyDialogVisible = false;

        // 1. Immediately apply the configuration live via hyprctl eval
        let lua = buildLuaString(root.pendingDisplays);
        Quickshell.execDetached(["hyprctl", "eval", lua]);

        // 2. Commit to snapshot so dirty state resets
        root.appliedSnapshot = JSON.parse(JSON.stringify(root.pendingDisplays));
        root.dirty = false;

        // 3. Save permanently to ~/.config/hypr/monitors.lua
        savePermanent();

        // 4. Send desktop notification feedback
        Quickshell.execDetached([
            "hyprctl", "notify", "1", "3000", "0",
            Translation.tr("Display configuration applied and saved as default")
        ]);
    }

    // Revert to snapshot
    function revert() {
        root.safetyDialogVisible = false;
        if (root.appliedSnapshot && root.appliedSnapshot.length > 0) {
            root.pendingDisplays = JSON.parse(JSON.stringify(root.appliedSnapshot));
            root.dirty = false;
            let lua = buildLuaString(root.pendingDisplays);
            Quickshell.execDetached(["hyprctl", "eval", lua]);
        }
    }

    // Write Lua configuration to ~/.config/hypr/monitors.lua
    function savePermanent() {
        let lines = [];
        lines.push("-- Generated by Quickshell Display Settings");
        lines.push(`-- Last updated: ${new Date().toISOString()}`);
        lines.push("package.loaded[\"monitors\"] = nil");
        lines.push("");

        for (let i = 0; i < root.pendingDisplays.length; i++) {
            let d = root.pendingDisplays[i];
            let posX = Math.round(d.x || 0);
            let posY = Math.round(d.y || 0);
            let posStr = `"${posX}x${posY}"`;
            let modeVal = (d.mode && d.mode.length > 0) ? d.mode : "preferred";
            let modeStr = d.disabled ? "\"disable\"" : `"${modeVal}"`;
            let scaleVal = d.scale || 1.0;
            let transformVal = d.transform || 0;
            let vrrVal = d.vrr || 0;
            let disabledBool = d.disabled ? "true" : "false";

            lines.push("hl.monitor({");
            lines.push(`    output = "${d.name}",`);
            lines.push(`    mode = ${modeStr},`);
            lines.push(`    position = ${posStr},`);
            lines.push(`    scale = ${scaleVal},`);
            lines.push(`    transform = ${transformVal},`);
            lines.push(`    vrr = ${vrrVal},`);
            lines.push(`    disabled = ${disabledBool}${d.mirror && !d.disabled ? `,\n    mirror = "${d.mirror}"` : ""}`);
            lines.push("})");
            lines.push("");
        }

        let fullScript = lines.join("\n");
        // Write to ~/.config/hypr/monitors.lua
        Quickshell.execDetached([
            "bash", "-c",
            `mkdir -p "$(dirname "${root.monitorsConfigPath}")" && cat << '__MONITORS_EOF__' > "${root.monitorsConfigPath}"\n${fullScript}\n__MONITORS_EOF__`
        ]);
    }

    // Reset all displays to preferred / auto defaults
    function resetDefaults() {
        let copy = JSON.parse(JSON.stringify(root.pendingDisplays));
        for (let i = 0; i < copy.length; i++) {
            copy[i].x = 0;
            copy[i].y = 0;
            copy[i].scale = 1.0;
            copy[i].transform = 0;
            copy[i].vrr = 0;
            copy[i].disabled = false;
            copy[i].mirror = "";
        }
        root.pendingDisplays = copy;
        alignDisplays("left-to-right");
        checkDirty();
    }

    Component.onCompleted: {
        refresh();
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event && ["monitoradded", "monitorremoved", "monitorlayout"].includes(event.name)) {
                root.refresh();
            }
        }
    }
}
