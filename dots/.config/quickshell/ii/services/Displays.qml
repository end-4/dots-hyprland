pragma Singleton
pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.modules.common
import qs.services

// Live outputs come from `hyprctl monitors all`, which includes disabled connectors.
// Hyprland.monitors only lists outputs that are currently on.
//
// Hyprland 0.55+ applies monitor rules from Lua. Each change is one `hyprctl eval`.
// A rule that omits `disabled` does not clear a previous `disabled = true`.
// Enabled rules always send `disabled = false` and the scale last read from hyprctl.

Singleton {
    id: root

    property var monitors: []
    property var positions: ({})
    property var extendPositions: ({})
    property bool mirrorHealUsed: false
    property var workspaceHold: null
    property bool workspaceHoldUsed: false
    property string lastError: ""
    property string pendingExpr: ""
    property string pendingPhase: ""
    property string queuedExpr: ""
    property string queuedPhase: ""
    property string activePhase: ""
    property bool evalFailed: false
    property bool arrangeOpen: false
    property string cycleName: ""
    property var cycleList: null
    property var cycleHomes: null
    property var cycleFocus: null
    property var cyclePendingFocus: null
    property bool cycleHolding: false
    property int cycleToken: 0
    property int cycleArmed: -1
    property bool applying: false
    property bool refreshQueued: false
    property bool syncing: false
    property bool evalTimedOut: false
    property string evalStderrText: ""
    property var rollback: null
    property bool confirmOpen: false
    property int confirmSeconds: 15
    property bool persistOnSuccess: false
    property bool writeAfterRefresh: false
    property var persistSnapshot: null
    property var savedMonitors: ({})
    property var seenNames: ({})
    property bool layoutReady: false
    property bool booted: false
    property string layoutText: ""
    property var queuedRecords: null
    property bool layoutUnreadable: false
    readonly property string layoutPath: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/hypr/monitors.lua"
    readonly property bool featureOn: Config.options?.sidebar?.displays?.enable ?? false
    readonly property int enabledCount: (monitors || []).filter(m => !m.disabled).length
    readonly property bool duplicating: (monitors || []).some(m => !m.disabled && !!m.mirror)
    readonly property string mirrorSource: {
        const mirrored = (monitors || []).find(m => !m.disabled && m.mirror);
        return mirrored ? mirrored.mirror : "";
    }

    signal dialogRequested()

    function requestDialog() {
        if (!root.featureOn) return;
        dialogRequested();
    }

    function setFeatureEnabled(on) {
        if (root.syncing) return;
        root.syncing = true;
        const next = !!on;
        const changed = Config.options.sidebar.displays.enable !== next;
        if (changed)
            Config.options.sidebar.displays.enable = next;
        const list = Config.options.sidebar.quickToggles.android.toggles;
        const idx = root.displaysToggleIndex(list);
        if (next && idx < 0)
            list.push({ type: "displays", size: 1 });
        else if (!next && idx >= 0)
            list.splice(idx, 1);
        root.syncing = false;
        if (next && !changed)
            root.refresh();
    }

    function displaysToggleIndex(list) {
        const items = list || [];
        for (let i = 0; i < items.length; i++) {
            if (items[i] && items[i].type === "displays")
                return i;
        }
        return -1;
    }

    function refresh() {
        if (!root.featureOn) return;
        if (root.applying || getMonitors.running) {
            root.refreshQueued = true;
            return;
        }
        root.refreshQueued = false;
        getMonitors.running = true;
    }

    function setEnabled(name, enabled) {
        if (!root.featureOn) return;
        root.cancelOutputCycle();
        if (root.confirmOpen) {
            confirmTicker.stop();
            root.confirmOpen = false;
            root.rollback = null;
            root.confirmSeconds = 15;
            if (!root.applying)
                root.flushLayout(root.monitors);
            else
                root.persistOnSuccess = true;
        }
        const list = snapshot();
        const target = list.find(m => m.name === name);
        if (!target) return;
        if (!enabled) {
            if (target.disabled || root.enabledCount <= 1) return;
            const focusedName = Hyprland.focusedMonitor?.name || "";
            const move = focusedName === name ? nearestOther(list, name) : null;
            if (Number.isFinite(target.x) && Number.isFinite(target.y))
                rememberPosition(name, target.x, target.y);
            target.disabled = true;
            target.mirror = "";
            target.pendingPosition = "";
            normalizeMirrors(list);
            root.separateAnchors(list);
            root.persistSnapshot = null;
            root.persistOnSuccess = true;
            applyNow(list, move);
            return;
        }
        if (!target.disabled) return;
        const homes = root.workspaceHomes();
        target.disabled = false;
        const saved = root.savedMonitors[name] || root.positions[name];
        const hasSaved = !!(saved && Number.isFinite(saved.x) && Number.isFinite(saved.y));
        if (hasSaved) {
            target.x = saved.x;
            target.y = saved.y;
            if (root.savedMonitors[name]) {
                target.mode = root.savedMonitors[name].mode || target.mode;
                target.scale = root.savedMonitors[name].scale || target.scale;
                target.transform = root.savedMonitors[name].transform | 0;
                target.mirror = root.savedMonitors[name].mirror || "";
                target.vrr = !!root.savedMonitors[name].vrr;
            }
        }
        target.pendingPosition = "";
        normalizeMirrors(list);
        if (!hasSaved)
            root.parkBeside(list, name);
        root.separateFrom(list, name);
        root.rememberExtendPositions(list);
        root.persistSnapshot = null;
        root.persistOnSuccess = true;
        applyNow(list, null, homes);
    }

    function openArrange() {
        if (!root.featureOn) return;
        root.arrangeOpen = false;
        arrangeOpenDelay.restart();
    }

    function applyPositions(list) {
        if (!root.featureOn) return;
        commit(list);
    }

    function setExtended() {
        if (!root.featureOn || !root.duplicating) return;
        const list = snapshot();
        for (let i = 0; i < list.length; i++)
            list[i].mirror = "";
        root.restoreExtendPositions(list);
        root.separateAnchors(list);
        root.rememberExtendPositions(list);
        commit(list);
    }

    function setDuplicated(sourceName) {
        if (!root.featureOn) return;
        const list = snapshot();
        const enabled = list.filter(m => !m.disabled);
        if (enabled.length < 2) return;
        const source = enabled.find(m => m.name === sourceName) || enabled[0];
        if (!source) return;
        if (root.duplicating && root.mirrorSource === source.name) return;
        if (!root.duplicating)
            root.rememberExtendPositions(list);
        for (let i = 0; i < list.length; i++)
            list[i].mirror = "";
        root.restoreExtendPositions(list);
        root.separateAnchors(list);
        root.rememberExtendPositions(list);
        for (let i = 0; i < list.length; i++) {
            if (list[i].disabled) continue;
            list[i].mirror = list[i].name === source.name ? "" : source.name;
            list[i].pendingPosition = "";
        }
        commit(list);
    }

    function setTransform(name, transform) {
        if (!root.featureOn) return;
        const next = transform | 0;
        const list = snapshot();
        const target = list.find(m => m.name === name);
        if (!target || target.disabled) return;
        if ((target.transform | 0) === next) return;
        // hyprctl width/height stay the mode size. The layout box swaps on 90 and 270.
        // Neighbors keep their old x/y, so a gap opens and the cursor cannot cross.
        root.reflowForTransform(list, target, next);
        target.transform = next;
        // The wallpaper sizes itself when the output is created. A transform
        // keeps the old layer, so the same output is recreated afterwards.
        root.cycleName = target.name;
        commit(list, "transform");
    }

    function beginOutputCycle(name) {
        const list = root.snapshot();
        const target = list.find(m => m.name === name);
        if (!target || target.disabled) {
            root.cancelOutputCycle();
            if (root.featureOn)
                root.refresh();
            return;
        }
        const size = root.layoutSize(target);
        root.cycleArmed = root.cycleToken;
        root.cycleHolding = true;
        root.cycleList = list.map(m => root.copyMonitor(m));
        root.cycleHomes = root.workspaceHomes();
        root.cycleFocus = {
            name: target.name,
            x: Math.round((Number(target.x) || 0) + size.width / 2),
            y: Math.round((Number(target.y) || 0) + size.height / 2),
        };
        const off = list.map(m => root.copyMonitor(m));
        const victim = off.find(m => m.name === name);
        victim.disabled = true;
        victim.mirror = "";
        victim.pendingPosition = "";
        root.applyNow(off, null, null, true, "cycle-off", name);
    }

    function finishOutputCycle() {
        if (root.cycleToken !== root.cycleArmed || !root.cycleList)
            return;
        const list = root.cycleList;
        const homes = root.cycleHomes;
        const focus = root.cycleFocus;
        root.cycleList = null;
        root.cycleHomes = null;
        root.cycleFocus = null;
        root.cycleHolding = false;
        root.cycleName = "";
        outputCycleTimer.stop();
        if (!root.featureOn)
            return;
        root.cyclePendingFocus = focus;
        const ownHomes = (homes || []).filter(h => h && h.monitor === (focus && focus.name));
        root.applyNow(list, null, ownHomes, true, "cycle-on", focus && focus.name);
    }

    function cancelOutputCycle() {
        root.cycleToken = root.cycleToken + 1;
        outputCycleTimer.stop();
        root.cycleName = "";
        root.cycleList = null;
        root.cycleHomes = null;
        root.cycleFocus = null;
        root.cyclePendingFocus = null;
        root.cycleHolding = false;
        root.cycleArmed = -1;
    }

    function focusScript(focus) {
        if (!focus || !focus.name)
            return "";
        return "(function() "
            + `hl.dispatch(hl.dsp.focus({ monitor = ${luaQuote(focus.name)} })) `
            + `hl.dispatch(hl.dsp.cursor.move({ x = ${focus.x | 0}, y = ${focus.y | 0} })) `
            + "end)()";
    }

    function setMode(name, mode) {
        if (!mode) return;
        patchMonitor(name, { mode: String(mode) });
    }

    function setVrr(name, enabled) {
        if (!root.featureOn) return;
        const list = snapshot();
        const target = list.find(m => m.name === name);
        if (!target || target.disabled) return;
        const next = !!enabled;
        if (!!target.vrr === next) return;
        target.vrr = next;
        if (root.confirmOpen && root.rollback) {
            const saved = root.rollback.map(copyMonitor);
            const previous = saved.find(m => m.name === name);
            if (previous && !previous.disabled)
                previous.vrr = next;
            root.rollback = saved;
        }
        root.persistSnapshot = (root.confirmOpen && root.rollback)
            ? root.rollback.map(m => root.copyMonitor(m))
            : list.map(m => root.copyMonitor(m));
        root.persistOnSuccess = true;
        applyNow(list, null);
    }

    function patchMonitor(name, patch) {
        if (!root.featureOn) return;
        const list = snapshot();
        const target = list.find(m => m.name === name);
        if (!target || target.disabled) return;
        const keys = Object.keys(patch);
        let same = true;
        for (let i = 0; i < keys.length; i++) {
            if (target[keys[i]] !== patch[keys[i]])
                same = false;
            target[keys[i]] = patch[keys[i]];
        }
        if (same) return;
        commit(list);
    }

    function commit(list, phase) {
        if (!root.confirmOpen)
            root.rollback = snapshot();
        root.confirmOpen = true;
        root.confirmSeconds = 15;
        confirmTicker.restart();
        applyNow(list, null, null, false, phase || "");
    }

    function keepChanges() {
        if (root.confirmOpen) {
            confirmTicker.stop();
            root.confirmOpen = false;
            root.rollback = null;
            root.confirmSeconds = 15;
            if (!root.applying)
                root.flushLayout(root.monitors);
            else
                root.persistOnSuccess = true;
        }
        if (!root.featureOn) return;
        root.persistSnapshot = null;
        if (root.applying) {
            root.persistOnSuccess = true;
            return;
        }
        root.flushLayout(root.monitors);
    }

    function revertChanges() {
        root.cancelOutputCycle();
        root.persistOnSuccess = false;
        root.persistSnapshot = null;
        root.writeAfterRefresh = false;
        confirmTicker.stop();
        const prev = root.rollback;
        root.confirmOpen = false;
        root.rollback = null;
        root.confirmSeconds = 15;
        if (!prev) return;
        applyNow(prev, null);
    }

    function applyNow(list, focusMove, homes, once, phase, onlyName) {
        const next = (list || []).map(copyMonitor);
        const scriptList = onlyName ? next.filter(m => m && m.name === onlyName) : next;
        const script = layoutScript(scriptList, focusMove, homes || null);
        rememberApplied(next);
        for (let i = 0; i < next.length; i++)
            next[i].pendingPosition = "";
        root.monitors = next;
        root.applying = true;
        root.pendingExpr = script;
        root.pendingPhase = phase || "";
        if (!once && homes && homes.length) {
            root.workspaceHold = homes;
            root.workspaceHoldUsed = false;
            workspaceHoldTimer.restart();
        }
        applyDelay.restart();
    }

    function stopFeature() {
        const restore = root.cycleList;
        refreshTimer.stop();
        arrangeOpenDelay.stop();
        root.cancelOutputCycle();
        root.refreshQueued = false;
        root.arrangeOpen = false;
        root.persistOnSuccess = false;
        root.persistSnapshot = null;
        root.writeAfterRefresh = false;
        root.queuedRecords = null;
        root.seenNames = {};
        root.workspaceHold = null;
        root.workspaceHoldUsed = false;
        root.mirrorHealUsed = false;
        workspaceHoldTimer.stop();
        if (root.confirmOpen) {
            revertChanges();
            return;
        }
        if (restore)
            root.applyNow(restore, null, null, true);
        confirmTicker.stop();
        root.rollback = null;
        root.confirmSeconds = 15;
    }

    function normalizeMirrors(list) {
        const enabled = list.filter(m => !m.disabled);
        const duplicating = enabled.some(m => !!m.mirror);
        if (!duplicating || enabled.length < 2) {
            for (let i = 0; i < list.length; i++)
                list[i].mirror = "";
            return;
        }
        let source = null;
        for (let i = 0; i < enabled.length; i++) {
            if (!enabled[i].mirror) continue;
            source = enabled.find(m => m.name === enabled[i].mirror);
            if (source) break;
        }
        if (!source)
            source = enabled.find(m => !m.mirror) || enabled[0];
        for (let i = 0; i < enabled.length; i++)
            enabled[i].mirror = enabled[i].name === source.name ? "" : source.name;
    }

    function nearestOther(list, name) {
        const target = list.find(m => m.name === name);
        if (!target) return null;
        const tx = Number(target.x || 0) + Number(target.width || 1) / 2;
        const ty = Number(target.y || 0) + Number(target.height || 1) / 2;
        let bestName = "";
        let bestX = 0;
        let bestY = 0;
        let bestD = Infinity;
        for (let i = 0; i < list.length; i++) {
            const other = list[i];
            if (!other || other.disabled || other.name === name) continue;
            const cx = Number(other.x || 0) + Number(other.width || 1) / 2;
            const cy = Number(other.y || 0) + Number(other.height || 1) / 2;
            const dx = cx - tx;
            const dy = cy - ty;
            const distance = dx * dx + dy * dy;
            if (distance >= bestD) continue;
            bestD = distance;
            bestName = other.name;
            bestX = Math.round(cx);
            bestY = Math.round(cy);
        }
        if (!bestName) return null;
        return { name: bestName, x: bestX, y: bestY };
    }

    function rememberPosition(name, x, y) {
        const next = Object.assign({}, root.positions);
        next[name] = { x: x, y: y };
        root.positions = next;
    }

    function rememberApplied(list) {
        const next = Object.assign({}, root.positions);
        let changed = false;
        const items = list || [];
        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            if (!item || item.disabled || item.pendingPosition) continue;
            if (!Number.isFinite(item.x) || !Number.isFinite(item.y)) continue;
            next[item.name] = { x: item.x, y: item.y };
            changed = true;
        }
        if (changed)
            root.positions = next;
    }

    function axisSwapped(transform) {
        return ((transform | 0) & 1) === 1;
    }

    function modePixels(monitor) {
        const width = Number(monitor && monitor.width);
        const height = Number(monitor && monitor.height);
        if (width > 0 && height > 0)
            return { width: width, height: height };
        const modes = [monitor && monitor.mode].concat((monitor && monitor.availableModes) || []);
        for (let i = 0; i < modes.length; i++) {
            const match = String(modes[i] || "").match(/(\d+)x(\d+)/);
            if (!match) continue;
            const parsedW = Number(match[1]);
            const parsedH = Number(match[2]);
            if (parsedW > 0 && parsedH > 0)
                return { width: parsedW, height: parsedH };
        }
        return { width: 1, height: 1 };
    }

    // Logical box the cursor actually travels, in the same units as hyprctl x/y.
    function layoutSize(monitor) {
        const scale = Number(monitor && monitor.scale);
        const safeScale = Number.isFinite(scale) && scale > 0 ? scale : 1;
        const pixels = root.modePixels(monitor);
        const swap = root.axisSwapped(monitor && monitor.transform);
        return {
            width: Math.max(1, Math.round((swap ? pixels.height : pixels.width) / safeScale)),
            height: Math.max(1, Math.round((swap ? pixels.width : pixels.height) / safeScale)),
        };
    }

    // Mode pixels after rotation. Scale is not applied.
    function resolutionSize(monitor) {
        const pixels = root.modePixels(monitor);
        const swap = root.axisSwapped(monitor && monitor.transform);
        return {
            width: swap ? pixels.height : pixels.width,
            height: swap ? pixels.width : pixels.height,
        };
    }

    function logicalBox(monitor) {
        const size = root.layoutSize(monitor);
        const x = Math.round(Number(monitor && monitor.x));
        const y = Math.round(Number(monitor && monitor.y));
        return {
            x: Number.isFinite(x) ? x : 0,
            y: Number.isFinite(y) ? y : 0,
            w: size.width,
            h: size.height,
        };
    }

    function rectsOverlap(a, b) {
        return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;
    }

    function layoutOverlaps(list) {
        const enabled = (list || []).filter(m => m && !m.disabled && m.name);
        for (let i = 0; i < enabled.length; i++) {
            const box = root.logicalBox(enabled[i]);
            for (let j = i + 1; j < enabled.length; j++) {
                if (root.rectsOverlap(box, root.logicalBox(enabled[j])))
                    return true;
            }
        }
        return false;
    }

    function enabledSolo(list) {
        return (list || []).filter(m => m && m.name && !m.disabled && !m.mirror);
    }

    function rememberExtendPositions(list) {
        const next = Object.assign({}, root.extendPositions || {});
        const items = list || [];
        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            if (!item || item.disabled || !item.name) continue;
            if (!Number.isFinite(item.x) || !Number.isFinite(item.y)) continue;
            next[item.name] = { x: Math.round(item.x), y: Math.round(item.y) };
        }
        root.extendPositions = next;
    }

    function restoreExtendPositions(list) {
        const saved = root.extendPositions || {};
        const items = list || [];
        for (let i = 0; i < items.length; i++) {
            const spot = saved[items[i] && items[i].name];
            if (!spot || !Number.isFinite(spot.x) || !Number.isFinite(spot.y)) continue;
            items[i].x = spot.x;
            items[i].y = spot.y;
            items[i].pendingPosition = "";
        }
    }

    function parkBeside(list, name) {
        const solos = root.enabledSolo(list);
        const target = solos.find(m => m.name === name);
        if (!target) return;
        const others = solos.filter(m => m.name !== name);
        let right = 0;
        let top = 0;
        if (others.length) {
            right = -Infinity;
            top = Infinity;
            for (let i = 0; i < others.length; i++) {
                const box = root.logicalBox(others[i]);
                right = Math.max(right, box.x + box.w);
                top = Math.min(top, box.y);
            }
        }
        target.x = right;
        target.y = top;
        target.pendingPosition = "";
    }

    // Push target off anchors. Anchors stay. A shared origin goes to the right.
    function shoveAside(anchors, target) {
        if (!target) return;
        let guard = anchors.length + 3;
        while (guard-- > 0) {
            const box = root.logicalBox(target);
            let hit = null;
            for (let i = 0; i < anchors.length; i++) {
                if (!root.rectsOverlap(root.logicalBox(anchors[i]), box)) continue;
                hit = anchors[i];
                break;
            }
            if (!hit) return;
            const anchor = root.logicalBox(hit);
            const sameOrigin = anchor.x === box.x && anchor.y === box.y;
            const overlapX = Math.min(anchor.x + anchor.w, box.x + box.w) - Math.max(anchor.x, box.x);
            const overlapY = Math.min(anchor.y + anchor.h, box.y + box.h) - Math.max(anchor.y, box.y);
            if (sameOrigin || overlapX <= overlapY)
                target.x = (sameOrigin || (box.x + box.w / 2) >= (anchor.x + anchor.w / 2)) ? anchor.x + anchor.w : anchor.x - box.w;
            else
                target.y = (box.y + box.h / 2) >= (anchor.y + anchor.h / 2) ? anchor.y + anchor.h : anchor.y - box.h;
            target.x = Math.round(target.x);
            target.y = Math.round(target.y);
            target.pendingPosition = "";
        }
        let still = false;
        let right = -Infinity;
        let top = Infinity;
        for (let i = 0; i < anchors.length; i++) {
            const box = root.logicalBox(anchors[i]);
            right = Math.max(right, box.x + box.w);
            top = Math.min(top, box.y);
            if (root.rectsOverlap(box, root.logicalBox(target)))
                still = true;
        }
        if (!still) return;
        target.x = Number.isFinite(right) ? right : 0;
        target.y = Number.isFinite(top) ? top : 0;
        target.pendingPosition = "";
    }

    function separateFrom(list, name) {
        const enabled = (list || []).filter(m => m && m.name && !m.disabled);
        const target = enabled.find(m => m.name === name);
        if (!target) return;
        root.shoveAside(enabled.filter(m => m.name !== name && !m.mirror), target);
    }

    function separateAnchors(list) {
        const solos = root.enabledSolo(list).slice().sort((a, b) => (a.x - b.x) || (a.y - b.y) || String(a.name).localeCompare(String(b.name)));
        for (let i = 1; i < solos.length; i++)
            root.shoveAside(solos.slice(0, i), solos[i]);
    }

    function workspaceHomes() {
        const values = Hyprland.workspaces && Hyprland.workspaces.values;
        if (!values || !values.length) return [];
        const homes = [];
        for (let i = 0; i < values.length; i++) {
            const ws = values[i];
            if (!ws || !(ws.id > 0) || !ws.monitor || !ws.monitor.name) continue;
            if (String(ws.name || "").indexOf("special:") === 0) continue;
            homes.push({ id: ws.id | 0, monitor: String(ws.monitor.name) });
        }
        return homes;
    }

    function workspacesDrifted(homes) {
        const values = Hyprland.workspaces && Hyprland.workspaces.values;
        if (!values || !homes) return false;
        for (let i = 0; i < homes.length; i++) {
            const home = homes[i];
            let found = null;
            for (let j = 0; j < values.length; j++) {
                if ((values[j].id | 0) === (home.id | 0)) {
                    found = values[j];
                    break;
                }
            }
            if (!found || !found.monitor || !found.monitor.name) continue;
            if (String(found.monitor.name) !== home.monitor)
                return true;
        }
        return false;
    }

    // One scale for every output: mode pixels after rotation. 768×1366 is the
    // exact inverse of 1366×768, and a 1920-wide panel stays 1920/768 times wider.
    function previewLayout(monitors) {
        const enabled = (monitors || []).filter(m => m && !m.disabled && m.name);
        const nodes = enabled.map(m => {
            const logical = root.layoutSize(m);
            const pixels = root.resolutionSize(m);
            return {
                name: m.name,
                model: m.model || m.description || "",
                boxW: pixels.width,
                boxH: pixels.height,
                textW: pixels.width,
                textH: pixels.height,
                posX: 0,
                posY: 0,
                lx: Number.isFinite(m.x) ? m.x : 0,
                ly: Number.isFinite(m.y) ? m.y : 0,
                lw: logical.width,
                lh: logical.height,
                ready: false,
            };
        });
        root.placePreview(nodes);
        return nodes.map(n => ({
            name: n.name,
            model: n.model,
            boxW: n.boxW,
            boxH: n.boxH,
            textW: n.textW,
            textH: n.textH,
            posX: n.posX,
            posY: n.posY,
            lx: n.lx,
            ly: n.ly,
            lw: n.lw,
            lh: n.lh,
        }));
    }

    function placePreview(nodes) {
        if (!nodes.length) return;
        const order = nodes.slice().sort((a, b) => a.lx - b.lx || a.ly - b.ly || String(a.name).localeCompare(String(b.name)));
        order[0].posX = 0;
        order[0].posY = 0;
        order[0].ready = true;
        let guard = nodes.length * nodes.length;
        while (order.some(n => !n.ready) && guard-- > 0) {
            let progressed = false;
            for (let i = 0; i < order.length; i++) {
                const node = order[i];
                if (node.ready) continue;
                let anchor = null;
                for (let j = 0; j < order.length; j++) {
                    if (!order[j].ready || !root.previewTouches(order[j], node)) continue;
                    anchor = order[j];
                    break;
                }
                if (!anchor) continue;
                root.stickPreview(anchor, node);
                node.ready = true;
                progressed = true;
            }
            if (progressed) continue;
            const node = order.find(n => !n.ready);
            let anchor = null;
            let best = Infinity;
            for (let j = 0; j < order.length; j++) {
                if (!order[j].ready) continue;
                const dx = node.lx - order[j].lx;
                const dy = node.ly - order[j].ly;
                const dist = dx * dx + dy * dy;
                if (dist < best) {
                    best = dist;
                    anchor = order[j];
                }
            }
            if (!anchor) {
                node.ready = true;
                continue;
            }
            root.shiftPreview(anchor, node);
            node.ready = true;
        }
    }

    function previewOverlap(a0, a1, b0, b1) {
        return Math.min(a1, b1) - Math.max(a0, b0);
    }

    function previewTouches(a, b) {
        const xOverlap = root.previewOverlap(a.lx, a.lx + a.lw, b.lx, b.lx + b.lw);
        const yOverlap = root.previewOverlap(a.ly, a.ly + a.lh, b.ly, b.ly + b.lh);
        const xTouch = Math.abs((a.lx + a.lw) - b.lx) <= 1 || Math.abs((b.lx + b.lw) - a.lx) <= 1;
        const yTouch = Math.abs((a.ly + a.lh) - b.ly) <= 1 || Math.abs((b.ly + b.lh) - a.ly) <= 1;
        return (xTouch && yOverlap > 1) || (yTouch && xOverlap > 1);
    }

    function stickPreview(a, b) {
        const aRight = a.lx + a.lw;
        const bRight = b.lx + b.lw;
        const aBottom = a.ly + a.lh;
        const bBottom = b.ly + b.lh;
        const yOverlap = root.previewOverlap(a.ly, aBottom, b.ly, bBottom);
        const xOverlap = root.previewOverlap(a.lx, aRight, b.lx, bRight);
        if (Math.abs(aRight - b.lx) <= 1 && yOverlap > 1) {
            b.posX = a.posX + a.boxW;
            b.posY = a.posY + (b.ly - a.ly) * (a.boxH / a.lh);
            return;
        }
        if (Math.abs(bRight - a.lx) <= 1 && yOverlap > 1) {
            b.posX = a.posX - b.boxW;
            b.posY = a.posY + (b.ly - a.ly) * (a.boxH / a.lh);
            return;
        }
        if (Math.abs(aBottom - b.ly) <= 1 && xOverlap > 1) {
            b.posY = a.posY + a.boxH;
            b.posX = a.posX + (b.lx - a.lx) * (a.boxW / a.lw);
            return;
        }
        if (Math.abs(bBottom - a.ly) <= 1 && xOverlap > 1) {
            b.posY = a.posY - b.boxH;
            b.posX = a.posX + (b.lx - a.lx) * (a.boxW / a.lw);
            return;
        }
        root.shiftPreview(a, b);
    }

    function shiftPreview(a, b) {
        b.posX = a.posX + (b.lx - a.lx) * (a.boxW / a.lw);
        b.posY = a.posY + (b.ly - a.ly) * (a.boxH / a.lh);
    }

    function reflowForTransform(list, target, nextTransform) {
        const oldSize = root.layoutSize(target);
        const preview = root.copyMonitor(target);
        preview.transform = nextTransform | 0;
        const newSize = root.layoutSize(preview);
        const dx = newSize.width - oldSize.width;
        const dy = newSize.height - oldSize.height;
        if (dx === 0 && dy === 0) return;
        const right = target.x + oldSize.width;
        const bottom = target.y + oldSize.height;
        for (let i = 0; i < list.length; i++) {
            const other = list[i];
            if (!other || other.disabled || other.name === target.name) continue;
            if (dx !== 0 && other.x >= right - 1)
                other.x = Math.round(other.x + dx);
            if (dy !== 0 && other.y >= bottom - 1)
                other.y = Math.round(other.y + dy);
            other.pendingPosition = "";
        }
    }

    function snapshot() {
        return (root.monitors || []).map(copyMonitor);
    }

    function copyMonitor(m) {
        return {
            name: m.name,
            description: m.description || "",
            make: m.make || "",
            model: m.model || "",
            width: m.width || 0,
            height: m.height || 0,
            refreshRate: m.refreshRate || 0,
            x: m.x || 0,
            y: m.y || 0,
            scale: m.scale || 1,
            transform: m.transform || 0,
            disabled: !!m.disabled,
            focused: !!m.focused,
            mirror: m.mirror || "",
            mode: m.mode || "preferred",
            vrr: !!m.vrr,
            pendingPosition: m.pendingPosition || "",
            availableModes: (m.availableModes || []).slice(),
        };
    }

    function resolveMirror(raw, list) {
        if (raw == null || raw === "" || raw === "none" || raw === "None") return "";
        if (typeof raw === "number" || /^\d+$/.test(String(raw))) {
            const id = Number(raw);
            const hit = (list || []).find(m => m.id === id);
            return hit ? hit.name : "";
        }
        return String(raw);
    }

    function matchMode(monitor) {
        const modes = monitor.availableModes || [];
        const refresh = Number(monitor.refreshRate || 0);
        const prefix = (monitor.width || 0) + "x" + (monitor.height || 0) + "@";
        const exact = modes.find(mode => mode.indexOf(prefix + refresh.toFixed(2)) === 0);
        if (exact) return exact;
        const loose = modes.find(mode => mode.indexOf(prefix) === 0);
        return loose || "preferred";
    }

    function luaQuote(value) {
        return "\"" + String(value).replace(/\\/g, "\\\\").replace(/"/g, "\\\"") + "\"";
    }

    function scaleLiteral(monitor) {
        const n = Number(monitor.scale);
        if (!Number.isFinite(n) || n <= 0) return "1";
        return String(Math.round(n * 1000) / 1000);
    }

    function positionLiteral(monitor) {
        if (monitor.pendingPosition)
            return luaQuote(monitor.pendingPosition);
        return luaQuote(Math.round(monitor.x) + "x" + Math.round(monitor.y));
    }

    function monitorLine(monitor) {
        const output = luaQuote(monitor.name);
        if (monitor.disabled)
            return `hl.monitor({ output = ${output}, disabled = true })`;
        const transform = monitor.transform | 0;
        const vrr = monitor.vrr ? "true" : "false";
        return `hl.monitor({ output = ${output}, disabled = false, mode = ${luaQuote(monitor.mode || "preferred")}, position = ${positionLiteral(monitor)}, scale = ${scaleLiteral(monitor)}, transform = ${transform}, mirror = ${luaQuote(monitor.mirror || "")}, vrr = ${vrr} })`;
    }

    function layoutScript(list, focusMove, homes) {
        const lines = [];
        const items = list || [];
        const enabled = {};
        const ordered = items.filter(m => m && m.name && m.name !== "FALLBACK" && (m.disabled || !m.mirror))
            .concat(items.filter(m => m && m.name && m.name !== "FALLBACK" && !m.disabled && m.mirror));
        for (let i = 0; i < ordered.length; i++) {
            lines.push(monitorLine(ordered[i]));
            if (!ordered[i].disabled)
                enabled[ordered[i].name] = true;
        }
        const keep = homes || [];
        for (let h = 0; h < keep.length; h++) {
            const home = keep[h];
            if (!home || !(home.id > 0) || !home.monitor || !enabled[home.monitor]) continue;
            lines.push(`hl.dispatch(hl.dsp.workspace.move({ workspace = ${home.id | 0}, monitor = ${luaQuote(home.monitor)} }))`);
        }
        if (focusMove && focusMove.name) {
            lines.push(`hl.dispatch(hl.dsp.focus({ monitor = ${luaQuote(focusMove.name)} }))`);
            lines.push(`hl.dispatch(hl.dsp.cursor.move({ x = ${focusMove.x | 0}, y = ${focusMove.y | 0} }))`);
        }
        return "(function() " + lines.join(" ") + " end)()";
    }

    function startEval(expr, phase) {
        if (!expr) return;
        if (evalProc.running) {
            root.queuedExpr = expr;
            root.queuedPhase = phase || "";
            return;
        }
        root.activePhase = phase || "";
        root.evalFailed = false;
        root.evalTimedOut = false;
        root.evalStderrText = "";
        evalProc.exec(["hyprctl", "eval", expr]);
        evalTimeout.restart();
    }

    function finishEval() {
        evalTimeout.stop();
        root.applying = false;
        const phase = root.activePhase;
        const failed = root.evalFailed || root.evalTimedOut;
        root.activePhase = "";
        root.evalFailed = false;
        const next = root.queuedExpr;
        const nextPhase = root.queuedPhase;
        root.queuedExpr = "";
        root.queuedPhase = "";
        if (next) {
            root.pendingExpr = next;
            root.pendingPhase = nextPhase;
            root.applying = true;
            applyDelay.restart();
            return;
        }
        if (phase === "transform" && !failed && root.cycleName) {
            root.beginOutputCycle(root.cycleName);
            return;
        }
        if (phase === "transform")
            root.cycleName = "";
        if (phase === "cycle-off" && root.cycleList && root.cycleToken === root.cycleArmed) {
            outputCycleTimer.restart();
            root.persistOnSuccess = false;
            root.writeAfterRefresh = false;
            if (root.featureOn)
                root.refresh();
            return;
        }
        if (phase === "cycle-on") {
            const focus = !failed ? root.cyclePendingFocus : null;
            root.cyclePendingFocus = null;
            if (focus && focus.name) {
                root.pendingExpr = root.focusScript(focus);
                root.pendingPhase = "cycle-focus";
                root.applying = true;
                applyDelay.restart();
                return;
            }
        }
        if (root.persistOnSuccess)
            root.writeAfterRefresh = true;
        if (root.featureOn)
            root.refresh();
    }

    function ingestMonitors(text) {
        if (!root.layoutReady) {
            root.refreshQueued = true;
            return;
        }
        if (root.applying) {
            root.refreshQueued = true;
            return;
        }
        try {
            const parsed = JSON.parse(text);
            if (Array.isArray(parsed)) {
                const raw = parsed.filter(m => m && m.name && m.name !== "FALLBACK");
                const seen = {};
                const prevSeen = root.seenNames || {};
                const nextPositions = Object.assign({}, root.positions);
                let positionsChanged = false;
                const built = raw.map(m => {
                    seen[m.name] = true;
                    const modes = m.availableModes || [];
                    const copy = root.copyMonitor({
                        name: m.name || "",
                        description: m.description || "",
                        make: m.make || "",
                        model: m.model || "",
                        width: m.width || 0,
                        height: m.height || 0,
                        refreshRate: m.refreshRate || 0,
                        x: m.x || 0,
                        y: m.y || 0,
                        scale: m.scale || 1,
                        transform: m.transform || 0,
                        disabled: !!m.disabled,
                        focused: !!m.focused,
                        vrr: !!m.vrr,
                        availableModes: modes,
                    });
                    copy.mirror = root.resolveMirror(m.mirrorOf, raw);
                    copy.mode = root.matchMode(copy);
                    if (copy.mirror) {
                        const spot = (root.extendPositions || {})[copy.name];
                        if (spot && Number.isFinite(spot.x) && Number.isFinite(spot.y)) {
                            copy.x = spot.x;
                            copy.y = spot.y;
                        }
                    } else if (!copy.disabled && Number.isFinite(m.x) && Number.isFinite(m.y)) {
                        nextPositions[copy.name] = { x: m.x, y: m.y };
                        positionsChanged = true;
                    }
                    return copy;
                });
                if (positionsChanged)
                    root.positions = nextPositions;
                root.monitors = built;
                root.seenNames = seen;
                if (!root.cycleHolding && root.writeAfterRefresh) {
                    const source = root.persistSnapshot || built;
                    root.writeAfterRefresh = false;
                    root.persistOnSuccess = false;
                    root.persistSnapshot = null;
                    const keep = source.filter(m => {
                        if (!m || !m.name) return false;
                        const saved = root.savedMonitors[m.name];
                        return !(saved && !prevSeen[m.name] && !root.ruleMatches(saved, m));
                    });
                    root.flushLayout(keep);
                }
                const homes = root.workspaceHold;
                const drifted = !!(homes && !root.cycleHolding && !root.workspaceHoldUsed && !root.confirmOpen && root.workspacesDrifted(homes));
                if (!root.cycleHolding && !root.confirmOpen) {
                    const back = [];
                    for (let i = 0; i < built.length; i++) {
                        const live = built[i];
                        if (prevSeen[live.name]) continue;
                        const saved = root.savedMonitors[live.name];
                        if (!saved || root.ruleMatches(saved, live)) continue;
                        back.push(saved);
                    }
                    if (back.length) {
                        if (drifted)
                            root.workspaceHoldUsed = true;
                        const merged = built.map(live => {
                            const saved = back.find(s => s.name === live.name);
                            return saved ? root.applySaved(live, saved) : live;
                        });
                        root.applyNow(merged, null, drifted ? homes : null, true);
                    } else if (drifted) {
                        root.workspaceHoldUsed = true;
                        root.applyNow(built, null, homes, true);
                    }
                }
                if (!root.cycleHolding && !root.confirmOpen && !root.applying && !root.mirrorHealUsed && root.layoutOverlaps(built)) {
                    root.mirrorHealUsed = true;
                    const healed = built.map(m => root.copyMonitor(m));
                    const mirrors = healed.map(m => m.mirror || "");
                    for (let i = 0; i < healed.length; i++)
                        healed[i].mirror = "";
                    root.separateAnchors(healed);
                    root.rememberExtendPositions(healed);
                    for (let i = 0; i < healed.length; i++)
                        healed[i].mirror = mirrors[i] || "";
                    root.applyNow(healed, null, null, true);
                }
            }
        } catch (e) {
            if (!root.lastError)
                root.lastError = Translation.tr("Could not read connected displays");
        }
        if (root.refreshQueued && !root.applying) {
            root.refreshQueued = false;
            refreshTimer.restart();
        }
    }

    onFeatureOnChanged: {
        if (root.featureOn) {
            root.loadLayout();
            return;
        }
        root.stopFeature();
    }

    Component.onCompleted: {
        if (root.featureOn)
            root.loadLayout();
    }

    Connections {
        target: Hyprland
        enabled: root.featureOn

        function onRawEvent(event) {
            const name = event?.name ?? "";
            if (root.workspaceHold && !root.workspaceHoldUsed && !root.applying && !root.confirmOpen && name.indexOf("workspace") !== -1 && root.workspacesDrifted(root.workspaceHold)) {
                root.workspaceHoldUsed = true;
                root.applyNow(root.monitors, null, root.workspaceHold, true);
            }
            if (name.indexOf("monitor") === -1) return;
            if (root.applying) {
                root.refreshQueued = true;
                return;
            }
            refreshTimer.restart();
        }
    }

    Timer {
        id: outputCycleTimer
        interval: 300
        repeat: false
        onTriggered: root.finishOutputCycle()
    }

    Timer {
        id: arrangeOpenDelay
        interval: 1
        repeat: false
        onTriggered: {
            if (root.featureOn)
                root.arrangeOpen = true;
        }
    }

    Timer {
        id: workspaceHoldTimer
        interval: 400
        repeat: false
        onTriggered: {
            root.workspaceHold = null;
            root.workspaceHoldUsed = false;
        }
    }

    Timer {
        id: confirmTicker
        interval: 1000
        repeat: true
        onTriggered: {
            root.confirmSeconds -= 1;
            if (root.confirmSeconds > 0) return;
            root.revertChanges();
        }
    }

    Timer {
        id: applyDelay
        interval: 40
        repeat: false
        onTriggered: {
            const expr = root.pendingExpr;
            const phase = root.pendingPhase;
            if (!expr) return;
            root.pendingExpr = "";
            root.pendingPhase = "";
            root.startEval(expr, phase);
        }
    }

    Timer {
        id: evalTimeout
        interval: 2000
        repeat: false
        onTriggered: {
            if (!evalProc.running) return;
            root.evalTimedOut = true;
            root.lastError = Translation.tr("Display command timed out");
            if (!root.queuedExpr) {
                root.persistOnSuccess = false;
                root.persistSnapshot = null;
                root.writeAfterRefresh = false;
            }
            if (root.activePhase === "transform")
                root.cycleName = "";
            evalProc.running = false;
            root.finishEval();
        }
    }

    Timer {
        id: refreshTimer
        interval: 350
        repeat: false
        onTriggered: root.refresh()
    }

    Process {
        id: getMonitors
        command: ["hyprctl", "monitors", "all", "-j"]
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: root.ingestMonitors(text)
        }
    }

    Process {
        id: evalProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stderr: StdioCollector {
            onStreamFinished: {
                root.evalStderrText = text;
                const err = (text || "").trim();
                if (!evalProc.running && err !== "" && !root.evalTimedOut)
                    root.lastError = err;
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (root.evalTimedOut) {
                root.evalTimedOut = false;
                return;
            }
            const err = (root.evalStderrText || "").trim();
            if (err !== "")
                root.lastError = err;
            else if (exitCode !== 0)
                root.lastError = Translation.tr("Could not read connected displays");
            else
                root.lastError = "";
            if (err !== "" || exitCode !== 0) {
                if (!root.queuedExpr) {
                    root.persistOnSuccess = false;
                    root.persistSnapshot = null;
                    root.writeAfterRefresh = false;
                }
                root.evalFailed = exitCode !== 0;
            }
            root.finishEval();
        }
    }

    readonly property string layoutBegin: "-- <<display-manager>>"
    readonly property string layoutEnd: "-- <<display-manager/>>"

    function loadLayout() {
        root.layoutReady = false;
        root.seenNames = {};
        layoutFile.reload();
    }

    function luaUnquote(value) {
        return String(value).replace(/\\"/g, "\"").replace(/\\\\/g, "\\");
    }

    function durableRecord(monitor) {
        const scale = Number(monitor.scale);
        return {
            name: monitor.name,
            disabled: !!monitor.disabled,
            mode: monitor.mode || "preferred",
            x: Math.round(Number(monitor.x) || 0),
            y: Math.round(Number(monitor.y) || 0),
            scale: Number.isFinite(scale) && scale > 0 ? scale : 1,
            transform: monitor.transform | 0,
            mirror: monitor.disabled ? "" : (monitor.mirror || ""),
            vrr: !!monitor.vrr,
        };
    }

    function recordLine(monitor) {
        const row = root.durableRecord(monitor);
        return "hl.monitor({ output = " + root.luaQuote(row.name)
            + ", disabled = " + (row.disabled ? "true" : "false")
            + ", mode = " + root.luaQuote(row.mode)
            + ", position = " + root.luaQuote(row.x + "x" + row.y)
            + ", scale = " + root.scaleLiteral(row)
            + ", transform = " + row.transform
            + ", mirror = " + root.luaQuote(row.mirror)
            + ", vrr = " + (row.vrr ? "true" : "false")
            + " })";
    }

    function ownedBlock() {
        const names = Object.keys(root.savedMonitors || {}).sort();
        const lines = [root.layoutBegin];
        for (let i = 0; i < names.length; i++) {
            const row = root.savedMonitors[names[i]];
            if (!row || !row.name || row.name === "FALLBACK" || /[\r\n]/.test(row.name)) continue;
            lines.push(root.recordLine(row));
        }
        lines.push(root.layoutEnd);
        return lines.join("\n") + "\n";
    }

    function spliceOwned(text, block) {
        const src = String(text || "");
        const start = src.indexOf(root.layoutBegin);
        const stop = src.indexOf(root.layoutEnd);
        if (start >= 0 && stop > start)
            return src.slice(0, start) + block + src.slice(stop + root.layoutEnd.length);
        const trimmed = src.replace(/\s*$/, "");
        if (!trimmed) return block;
        return trimmed + "\n\n" + block;
    }

    function parseOwned(text) {
        const src = String(text || "");
        const start = src.indexOf(root.layoutBegin);
        const stop = src.indexOf(root.layoutEnd);
        const next = {};
        if (start < 0 || stop < start) return next;
        const body = src.slice(start + root.layoutBegin.length, stop);
        const re = /hl\.monitor\(\{\s*output\s*=\s*"((?:\\.|[^"\\])*)"\s*,\s*disabled\s*=\s*(true|false)\s*,\s*mode\s*=\s*"((?:\\.|[^"\\])*)"\s*,\s*position\s*=\s*"(-?\d+)x(-?\d+)"\s*,\s*scale\s*=\s*([0-9]*\.?[0-9]+)\s*,\s*transform\s*=\s*(-?\d+)\s*,\s*mirror\s*=\s*"((?:\\.|[^"\\])*)"\s*,\s*vrr\s*=\s*(true|false)\s*\}\)/g;
        let match = re.exec(body);
        while (match) {
            const name = root.luaUnquote(match[1]);
            if (name && name !== "FALLBACK") {
                next[name] = {
                    name: name,
                    disabled: match[2] === "true",
                    mode: root.luaUnquote(match[3]),
                    x: Number(match[4]),
                    y: Number(match[5]),
                    scale: Number(match[6]) || 1,
                    transform: Number(match[7]) | 0,
                    mirror: root.luaUnquote(match[8]),
                    vrr: match[9] === "true",
                };
            }
            match = re.exec(body);
        }
        return next;
    }

    function seedPositions(records) {
        const next = Object.assign({}, root.positions);
        const names = Object.keys(records || {});
        for (let i = 0; i < names.length; i++) {
            const row = records[names[i]];
            if (!row || !Number.isFinite(row.x) || !Number.isFinite(row.y)) continue;
            next[row.name] = { x: row.x, y: row.y };
        }
        root.positions = next;
    }

    function upsertSaved(list) {
        const next = Object.assign({}, root.savedMonitors);
        const items = list || [];
        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            if (!item || !item.name || item.name === "FALLBACK" || /[\r\n]/.test(item.name)) continue;
            const row = root.durableRecord(item);
            next[row.name] = row;
            if (Number.isFinite(row.x) && Number.isFinite(row.y))
                root.rememberPosition(row.name, row.x, row.y);
        }
        root.savedMonitors = next;
    }

    function ruleMatches(saved, live) {
        if (!saved || !live) return false;
        if (!!saved.disabled !== !!live.disabled) return false;
        if ((saved.transform | 0) !== (live.transform | 0)) return false;
        if (!!saved.vrr !== !!live.vrr) return false;
        if ((saved.mirror || "") !== (live.mirror || "")) return false;
        if (Math.round(Number(saved.x) || 0) !== Math.round(Number(live.x) || 0)) return false;
        if (Math.round(Number(saved.y) || 0) !== Math.round(Number(live.y) || 0)) return false;
        if (Math.abs((Number(saved.scale) || 1) - (Number(live.scale) || 1)) > 0.001) return false;
        return (saved.mode || "preferred") === (live.mode || "preferred");
    }

    function applySaved(live, saved) {
        const copy = root.copyMonitor(live);
        copy.disabled = !!saved.disabled;
        copy.mode = saved.mode || copy.mode;
        copy.x = saved.x;
        copy.y = saved.y;
        copy.scale = saved.scale || copy.scale;
        copy.transform = saved.transform | 0;
        copy.mirror = saved.disabled ? "" : (saved.mirror || "");
        copy.vrr = !!saved.vrr;
        copy.pendingPosition = "";
        return copy;
    }

    function flushLayout(list) {
        if (!root.featureOn) return;
        if (root.layoutUnreadable) {
            root.lastError = Translation.tr("Could not save the display layout");
            return;
        }
        if (!root.layoutReady) {
            root.queuedRecords = (list || []).map(m => root.copyMonitor(m));
            return;
        }
        root.upsertSaved(list);
        const next = root.spliceOwned(root.layoutText, root.ownedBlock());
        root.layoutText = next;
        layoutFile.setText(next);
    }

    function acceptLayoutText(text) {
        root.layoutText = text || "";
        root.layoutReady = true;
        const parsed = root.parseOwned(root.layoutText);
        root.savedMonitors = parsed;
        root.seedPositions(parsed);
        if (root.featureOn && root.queuedRecords) {
            const queued = root.queuedRecords;
            root.queuedRecords = null;
            root.flushLayout(queued);
        }
        if (!root.booted) {
            root.booted = true;
            if (root.featureOn)
                root.refresh();
        }
    }

    FileView {
        id: layoutFile
        path: root.layoutPath
        watchChanges: false
        onLoaded: root.acceptLayoutText(layoutFile.text() || "")
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound) {
                root.layoutUnreadable = false;
                root.acceptLayoutText("");
                return;
            }
            root.layoutUnreadable = true;
            root.layoutReady = true;
            root.lastError = Translation.tr("Could not read the saved display layout");
            if (!root.booted) {
                root.booted = true;
                if (root.featureOn)
                    root.refresh();
            }
        }
    }
}
