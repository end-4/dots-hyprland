pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.models.hyprland
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property var cards: []
    property var cardRows: []
    property var tileByIndex: ({})
    property real panelLayW: 400
    property real panelLayH: 280
    property int selectedIndex: 0
    property string lastAltTabAddress: ""
    // Rep addresses from last commit; mouse focus does not reshuffle this (Windows-like stable strip).
    property var stableOrder: []
    property int tabHoldDirection: 1
    // Until the cursor actually moves in screen space, ignore hover. (Flickable scroll changes
    // local mouse coords under a stationary cursor and was falsely arming selection.)
    property bool altTabMouseSelectionArmed: false
    property point altTabPointerGlobalAnchor: Qt.point(-1, -1)
    readonly property real altTabMouseMoveThreshold: 6

    readonly property var activeToplevel: ToplevelManager.activeToplevel
    readonly property string focusedClientAddress: root.activeToplevel?.HyprlandToplevel?.address !== undefined ? `0x${root.activeToplevel.HyprlandToplevel.address}` : ""

    readonly property var focusedScreen: Quickshell.screens.find(s => Hyprland.monitorFor(s)?.id === Hyprland.focusedMonitor?.id) ?? Quickshell.primaryScreen ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

    HyprlandConfigOption {
        id: gameModeAnim
        key: "animations:enabled"
    }

    readonly property bool gameModeActive: gameModeAnim.value === 0 || gameModeAnim.value === false
    readonly property bool effectiveShowPreviews: (Config.options.altTab?.showPreviews !== false) && !root.gameModeActive
    readonly property int effectiveGap: Config.options.altTab?.gap ?? 16
    readonly property int perRowSetting: Math.max(2, Math.min(12, Config.options.altTab?.maxItemsPerRow ?? 5))
    readonly property int estCellWidth: (Config.options.altTab?.maxThumbnailWidth ?? 680) + root.effectiveGap + 48
    readonly property int flowWidthByCount: perRowSetting * estCellWidth
    readonly property int innerMaxWidth: Math.min(Math.min(2400, flowWidthByCount), Math.max(400, panelWindow.width - 96))
    readonly property int titleBarH: Config.options.altTab?.titleBarHeight ?? 44
    // Space to leave for overlaid close control (button ≈ titleBarH−10, chrome inset); avoid over-reserving → premature "…"
    readonly property int altTabCloseTitleReserve: Math.max(root.titleBarH - 8, 24)
    readonly property int tabHoldRepeatMs: Math.max(80, Config.options.altTab?.tabHoldRepeatMs ?? 240)
    readonly property int tabHoldDelayMs: Math.max(200, Config.options.altTab?.tabHoldDelayMs ?? 520)
    readonly property int iconOnlyTileW: Math.max(96, Config.options.altTab?.iconOnlyTileWidth ?? 132)
    readonly property int iconOnlyAreaH: Math.max(64, Config.options.altTab?.iconOnlyAreaHeight ?? 92)
    // Fixed chrome so selection/highlight never changes tile bounds (no layout jump or scroll nudge).
    readonly property int tileFramePad: 13
    readonly property int tileCellOuterPad: 14

    readonly property real maxPanelW: panelWindow.width * 0.92
    readonly property real maxPanelH: panelWindow.height * 0.88

    function focusHistoryId(win) {
        const v = win.focusHistoryID !== undefined ? win.focusHistoryID : win.focusHistoryId;
        return v !== undefined ? v : 9999;
    }

    function altTabMonitorFilter(windows) {
        if (Config.options.altTab?.perMonitor !== true)
            return windows;
        const mid = Hyprland.focusedMonitor?.id;
        if (mid === undefined || mid === null)
            return windows;
        return windows.filter(w => w.monitor == mid);
    }

    function sortWindows(windows) {
        let filtered = windows.filter(w => w.workspace && w.workspace.id !== undefined && w.workspace.id !== -1);
        filtered = root.altTabMonitorFilter(filtered);
        filtered.sort((a, b) => {
            const fa = root.focusHistoryId(a);
            const fb = root.focusHistoryId(b);
            if (fa !== fb)
                return fa - fb;
            return String(a.address).localeCompare(String(b.address));
        });
        return filtered;
    }

    function memberFromWin(win) {
        return {
            address: win.address,
            sw: win.size?.[0] ?? 520,
            sh: win.size?.[1] ?? 380,
            at0: win.at?.[0] ?? 0,
            at1: win.at?.[1] ?? 0
        };
    }

    function makeCardFromWin(win, groupCount) {
        const sw = win.size?.[0] ?? 520;
        const sh = win.size?.[1] ?? 380;
        return {
            address: win.address,
            title: win.title ?? "",
            className: win.class ?? "",
            workspaceId: win.workspace.id,
            floating: !!win.floating,
            groupCount: groupCount ?? 1,
            sw: sw,
            sh: sh,
            repFocusHist: root.focusHistoryId(win),
            groupMembers: [root.memberFromWin(win)]
        };
    }

    function groupLayoutKind(members) {
        const n = members?.length ?? 0;
        if (n <= 1)
            return "single";
        let minX = 1e12;
        let maxX = -1e12;
        let minY = 1e12;
        let maxY = -1e12;
        for (let i = 0; i < n; i++) {
            const m = members[i];
            const w = Math.max(m.sw ?? 400, 48);
            const h = Math.max(m.sh ?? 300, 48);
            const cx = (m.at0 ?? 0) + w * 0.5;
            const cy = (m.at1 ?? 0) + h * 0.5;
            minX = Math.min(minX, cx);
            maxX = Math.max(maxX, cx);
            minY = Math.min(minY, cy);
            maxY = Math.max(maxY, cy);
        }
        const spreadX = maxX - minX;
        const spreadY = maxY - minY;
        return spreadX >= spreadY ? "row" : "column";
    }

    function distributeIntegerWeights(total, weights) {
        const n = weights.length;
        if (n === 0)
            return [];
        const sum = weights.reduce((a, b) => a + Math.max(b, 1e-9), 0);
        const raw = weights.map(w => total * Math.max(w, 1e-9) / sum);
        const floors = raw.map(x => Math.floor(x));
        let rem = total - floors.reduce((a, b) => a + b, 0);
        const fracs = raw.map((x, i) => ({
                i,
                f: x - Math.floor(x)
            }));
        fracs.sort((a, b) => b.f - a.f);
        let ri = 0;
        while (rem > 0) {
            floors[fracs[ri % n].i]++;
            rem--;
            ri++;
        }
        return floors;
    }

    function sortMembersByLayout(members, kind) {
        const copy = members.slice();
        if (kind === "column") {
            copy.sort((a, b) => {
                const acy = (a.at1 ?? 0) + Math.max(a.sh ?? 300, 48) * 0.5;
                const bcy = (b.at1 ?? 0) + Math.max(b.sh ?? 300, 48) * 0.5;
                return acy - bcy;
            });
        } else {
            copy.sort((a, b) => {
                const acx = (a.at0 ?? 0) + Math.max(a.sw ?? 400, 48) * 0.5;
                const bcx = (b.at0 ?? 0) + Math.max(b.sw ?? 400, 48) * 0.5;
                return acx - bcx;
            });
        }
        return copy;
    }

    function groupPreviewSlotDims(card) {
        const mx = Config.options.altTab?.maxThumbnailWidth ?? 680;
        const my = Config.options.altTab?.maxThumbnailHeight ?? 520;
        const g = root.effectiveGap;
        const members = card.groupMembers;
        const n = members?.length ?? 0;
        if (!members || n <= 1) {
            const th = root.thumbDimsFit(card.sw, card.sh);
            return {
                w: th.w,
                h: th.h,
                layout: "single",
                members: members && n === 1 ? members : [{
                        address: card.address,
                        sw: card.sw,
                        sh: card.sh,
                        at0: 0,
                        at1: 0
                    }],
                cellW: th.w,
                cellH: th.h,
                gap: 0
            };
        }
        const kind = root.groupLayoutKind(members);
        const ordered = root.sortMembersByLayout(members, kind);
        if (kind === "row") {
            const availW = mx - (n - 1) * g;
            const sws = ordered.map(m => Math.max(m.sw ?? 400, 48));
            const totalSw = sws.reduce((a, b) => a + b, 0);
            const cellWidths = root.distributeIntegerWeights(availW, sws);
            const shRef = Math.max(...ordered.map(m => Math.max(m.sh ?? 300, 48)));
            let cellH = Math.round((availW * shRef) / totalSw);
            cellH = Math.min(Math.max(cellH, 48), my);
            const rowXOffsets = [];
            let acc = 0;
            for (let i = 0; i < n; i++) {
                rowXOffsets.push(acc);
                acc += cellWidths[i];
                if (i < n - 1)
                    acc += g;
            }
            return {
                w: acc,
                h: cellH,
                layout: "row",
                members: ordered,
                gap: g,
                cellWidths: cellWidths,
                rowXOffsets: rowXOffsets,
                cellH: cellH,
                cellW: cellWidths[0] ?? 48
            };
        }
        const availH = my - (n - 1) * g;
        const shs = ordered.map(m => Math.max(m.sh ?? 300, 48));
        const totalSh = shs.reduce((a, b) => a + b, 0);
        const cellHeights = root.distributeIntegerWeights(availH, shs);
        const swRef = Math.max(...ordered.map(m => Math.max(m.sw ?? 400, 48)));
        let cellW = Math.round((availH * swRef) / totalSh);
        cellW = Math.min(Math.max(cellW, 48), mx);
        const columnYOffsets = [];
        let yAcc = 0;
        for (let i = 0; i < n; i++) {
            columnYOffsets.push(yAcc);
            yAcc += cellHeights[i];
            if (i < n - 1)
                yAcc += g;
        }
        return {
            w: cellW,
            h: yAcc,
            layout: "column",
            members: ordered,
            gap: g,
            cellHeights: cellHeights,
            columnYOffsets: columnYOffsets,
            cellW: cellW,
            cellH: cellHeights[0] ?? 48
        };
    }

    function buildContextCards(sorted) {
        const out = [];
        for (let i = 0; i < sorted.length; i++) {
            const win = sorted[i];
            const cls = win.class ?? "";
            const wsId = win.workspace.id;
            if (win.floating) {
                out.push(root.makeCardFromWin(win, 1));
            } else {
                const j = out.findIndex(row => !row.floating && row.workspaceId === wsId && row.className === cls);
                if (j >= 0) {
                    out[j].groupCount++;
                    out[j].groupMembers.push(root.memberFromWin(win));
                    const wHist = root.focusHistoryId(win);
                    if (wHist < out[j].repFocusHist) {
                        out[j].address = win.address;
                        out[j].title = win.title ?? "";
                        out[j].sw = win.size?.[0] ?? 520;
                        out[j].sh = win.size?.[1] ?? 380;
                        out[j].repFocusHist = wHist;
                    }
                } else {
                    out.push(root.makeCardFromWin(win, 1));
                }
            }
        }
        return out;
    }

    function buildFlatCards(sorted) {
        return sorted.map(w => root.makeCardFromWin(w, 1));
    }

    // Scale each window into the max thumbnail box; same aspect ratio, no letterboxing inside pvSlot.
    function thumbDimsFit(sw, sh) {
        const mx = Config.options.altTab?.maxThumbnailWidth ?? 680;
        const my = Config.options.altTab?.maxThumbnailHeight ?? 520;
        const ssw = Math.max(Number(sw) || 520, 48);
        const ssh = Math.max(Number(sh) || 380, 48);
        const scale = Math.min(mx / ssw, my / ssh);
        const w = Math.round(ssw * scale);
        const h = Math.round(ssh * scale);
        return {
            w: Math.max(96, w),
            h: Math.max(96, h)
        };
    }

    function tileContentWidth(card) {
        if (!root.effectiveShowPreviews) {
            const iconCol = root.iconOnlyTileW;
            const titleNeeds = 26 + 10 + root.altTabCloseTitleReserve + 64;
            return Math.max(iconCol, titleNeeds);
        }
        const pv = root.groupPreviewSlotDims(card);
        return Math.max(pv.w + 8, 104);
    }

    function tileContentHeight(card) {
        if (!root.effectiveShowPreviews)
            return root.titleBarH + 8 + root.iconOnlyAreaH + 24;
        const pv = root.groupPreviewSlotDims(card);
        return root.titleBarH + 8 + pv.h + 12;
    }

    function tileOuterWidth(card) {
        return root.tileContentWidth(card) + 2 * root.tileFramePad + 2 * root.tileCellOuterPad;
    }

    function tileOuterHeight(card) {
        return root.tileContentHeight(card) + 2 * root.tileFramePad + 2 * root.tileCellOuterPad;
    }

    function toplevelForAddressStr(addr) {
        const vals = ToplevelManager.toplevels.values;
        const want = String(addr ?? "").toLowerCase();
        for (let i = 0; i < vals.length; i++) {
            const client = HyprlandData.clientForToplevel(vals[i]);
            if (client && root.addrsMatch(client.address, want))
                return vals[i];
        }
        return null;
    }

    function addrsMatch(a, b) {
        return String(a ?? "").toLowerCase() === String(b ?? "").toLowerCase();
    }

    function initialSelectionMode() {
        let m = Config.options.altTab?.initialSelection;
        if (m === undefined || m === null)
            m = "lastAltTab";
        m = String(m).trim().toLowerCase().replace(/-/g, "");
        if (m === "previousfocus" || m === "classic" || m === "secondmru")
            return "previousFocus";
        return "lastAltTab";
    }

    function updateCardRowsAndPanelMetrics() {
        const list = root.cards;
        const n = list.length;
        const M = root.perRowSetting;
        const g = root.effectiveGap;
        const rows = [];
        let i = 0;
        while (i < n) {
            const take = Math.min(M, n - i);
            const rowIdx = [];
            for (let j = 0; j < take; j++)
                rowIdx.push(i + j);
            rows.push(rowIdx);
            i += take;
        }
        root.cardRows = rows;

        let totalH = 0;
        let maxRowW = 0;
        for (let r = 0; r < rows.length; r++) {
            const rowIdx = rows[r];
            let rowW = 0;
            let rowH = 0;
            for (let k = 0; k < rowIdx.length; k++) {
                const card = list[rowIdx[k]];
                const tw = root.tileOuterWidth(card);
                const th = root.tileOuterHeight(card);
                rowH = Math.max(rowH, th);
                rowW += tw + (k > 0 ? g : 0);
            }
            totalH += rowH + (r > 0 ? g : 0);
            maxRowW = Math.max(maxRowW, rowW);
        }
        root.panelLayW = maxRowW;
        root.panelLayH = totalH;
    }

    function focusedAddressForOrdering() {
        let f = String(root.focusedClientAddress ?? "").toLowerCase();
        if (f)
            return f;
        let wins = HyprlandData.windowList.filter(w => w.workspace && w.workspace.id !== undefined && w.workspace.id !== -1);
        wins = root.altTabMonitorFilter(wins);
        if (wins.length === 0)
            return "";
        let best = wins[0];
        let bestId = root.focusHistoryId(best);
        for (let i = 1; i < wins.length; i++) {
            const id = root.focusHistoryId(wins[i]);
            if (id < bestId) {
                bestId = id;
                best = wins[i];
            }
        }
        return String(best.address ?? "").toLowerCase();
    }

    function orderCardsStable(pool) {
        const byKey = {};
        for (let i = 0; i < pool.length; i++) {
            const c = pool[i];
            byKey[String(c.address).toLowerCase()] = c;
        }
        const ordered = [];
        const used = new Set();
        const f = root.focusedAddressForOrdering();
        if (f && byKey[f]) {
            ordered.push(byKey[f]);
            used.add(f);
        }
        const stable = root.stableOrder;
        for (let s = 0; s < stable.length; s++) {
            const low = String(stable[s] ?? "").toLowerCase();
            if (used.has(low) || !byKey[low])
                continue;
            ordered.push(byKey[low]);
            used.add(low);
        }
        const rest = [];
        for (let i = 0; i < pool.length; i++) {
            const low = String(pool[i].address).toLowerCase();
            if (!used.has(low))
                rest.push(pool[i]);
        }
        rest.sort((a, b) => String(a.address).localeCompare(String(b.address)));
        return ordered.concat(rest);
    }

    function rebuildCards() {
        const sorted = root.sortWindows(HyprlandData.windowList);
        const useCtx = Config.options.altTab?.contextGrouping !== false;
        const pool = useCtx ? root.buildContextCards(sorted) : root.buildFlatCards(sorted);
        if (root.stableOrder.length === 0 && pool.length > 0)
            root.stableOrder = pool.map(c => c.address);
        root.cards = root.orderCardsStable(pool);
        root.updateCardRowsAndPanelMetrics();
    }

    function rebuildCardsReselecting(prevAddr) {
        root.rebuildCards();
        if (root.cards.length === 0) {
            GlobalStates.altTabStickyMode = false;
            GlobalStates.altTabOpen = false;
            return;
        }
        if (prevAddr) {
            const ni = root.cards.findIndex(c => root.addrsMatch(c.address, prevAddr));
            if (ni >= 0)
                root.selectedIndex = ni;
            else
                root.selectedIndex = Math.max(0, Math.min(root.selectedIndex, root.cards.length - 1));
        } else {
            root.selectedIndex = Math.max(0, Math.min(root.selectedIndex, root.cards.length - 1));
        }
        root.scheduleScrollToSelected();
    }

    function registerTile(idx, item) {
        root.tileByIndex[idx] = item;
    }

    function unregisterTile(idx) {
        delete root.tileByIndex[idx];
    }

    function initialIndexForOpen(n) {
        const mode = root.initialSelectionMode();
        if (mode === "previousFocus")
            return n > 1 ? 1 : 0;
        if (!root.lastAltTabAddress)
            return n > 1 ? 1 : 0;
        const idx = root.cards.findIndex(c => root.addrsMatch(c.address, root.lastAltTabAddress));
        if (idx < 0)
            return n > 1 ? 1 : 0;
        return (idx + 1) % n;
    }

    function performStep(delta, openSticky) {
        root.rebuildCards();
        const n = root.cards.length;
        if (n === 0)
            return;
        if (!GlobalStates.altTabOpen) {
            GlobalStates.overviewOpen = false;
            GlobalStates.altTabStickyMode = (openSticky === true);
            GlobalStates.altTabOpen = true;
            root.selectedIndex = root.initialIndexForOpen(n);
        } else {
            root.selectedIndex = (root.selectedIndex + delta + n) % n;
            // Keyboard (or global) step: scroll moves tiles under cursor; armed hover would steal selection on onEntered.
            root.disarmAltTabMouseHover();
        }
        root.scheduleScrollToSelected();
    }

    function focusSelectedAndClose() {
        if (!GlobalStates.altTabOpen)
            return;
        if (root.cards.length === 0) {
            GlobalStates.altTabStickyMode = false;
            GlobalStates.altTabOpen = false;
            return;
        }
        const addr = root.cards[root.selectedIndex]?.address;
        GlobalStates.altTabStickyMode = false;
        GlobalStates.altTabOpen = false;
        if (addr) {
            root.lastAltTabAddress = addr;
            root.stableOrder = root.cards.map(c => c.address);
            Hyprland.dispatch(`focuswindow address:${addr}`);
        }
    }

    function cancelWithoutFocus() {
        GlobalStates.altTabStickyMode = false;
        GlobalStates.altTabOpen = false;
    }

    function closeWindowForAddress(addr) {
        if (!addr || !GlobalStates.altTabOpen)
            return;
        Hyprland.dispatch(`closewindow address:${addr}`);
    }

    function disarmAltTabMouseHover() {
        root.altTabMouseSelectionArmed = false;
        root.altTabPointerGlobalAnchor = Qt.point(-1, -1);
    }

    function scheduleScrollToSelected() {
        scrollToSelectedTimer.restart();
    }

    function scrollToSelected() {
        if (!GlobalStates.altTabOpen)
            return;
        const it = root.tileByIndex[root.selectedIndex];
        if (!it || flick.width < 8 || flick.height < 8)
            return;
        const pos = it.mapToItem(flick.contentItem, 0, 0);
        const margin = 28;
        const vw = flick.width;
        const vh = flick.height;
        const x1 = pos.x;
        const y1 = pos.y;
        const x2 = pos.x + it.width;
        const y2 = pos.y + it.height;
        let nx = flick.contentX;
        let ny = flick.contentY;
        if (x1 < nx + margin)
            nx = x1 - margin;
        else if (x2 > nx + vw - margin)
            nx = x2 - vw + margin;
        if (y1 < ny + margin)
            ny = y1 - margin;
        else if (y2 > ny + vh - margin)
            ny = y2 - vh + margin;
        const maxX = Math.max(0, flick.contentWidth - vw);
        const maxY = Math.max(0, flick.contentHeight - vh);
        flick.contentX = Math.max(0, Math.min(nx, maxX));
        flick.contentY = Math.max(0, Math.min(ny, maxY));
    }

    function tabHoldStop() {
        tabHoldInitial.stop();
        tabHoldRepeat.stop();
    }

    function globalAltTabStep(delta) {
        HyprlandData.updateWindowList();
        if (GlobalStates.altTabOpen)
            GlobalStates.altTabStickyMode = false;
        if (GlobalStates.altTabOpen) {
            afterListRefreshTimer.stop();
            root.performStep(delta);
        } else {
            afterListRefreshTimer.direction = delta;
            afterListRefreshTimer.openSticky = false;
            afterListRefreshTimer.restart();
        }
    }

    function globalAltTabStickyStep(delta) {
        HyprlandData.updateWindowList();
        if (GlobalStates.altTabOpen)
            GlobalStates.altTabStickyMode = true;
        if (GlobalStates.altTabOpen) {
            afterListRefreshTimer.stop();
            root.performStep(delta);
        } else {
            afterListRefreshTimer.direction = delta;
            afterListRefreshTimer.openSticky = true;
            afterListRefreshTimer.restart();
        }
    }

    function selectedRowCol() {
        const idx = root.selectedIndex;
        const rows = root.cardRows;
        for (let r = 0; r < rows.length; r++) {
            const c = rows[r].indexOf(idx);
            if (c >= 0)
                return {
                    row: r,
                    col: c
                };
        }
        return {
            row: 0,
            col: 0
        };
    }

    function moveSelectionRowDelta(drow) {
        const rows = root.cardRows;
        const n = root.cards.length;
        if (n === 0)
            return;
        const p = root.selectedRowCol();
        let nr = p.row + drow;
        if (nr < 0)
            nr = 0;
        if (nr >= rows.length)
            nr = rows.length - 1;
        const row = rows[nr];
        const nc = Math.min(p.col, row.length - 1);
        const ni = row[nc];
        if (ni >= 0 && ni < n)
            root.selectedIndex = ni;
        root.disarmAltTabMouseHover();
        root.scheduleScrollToSelected();
    }

    Timer {
        id: afterListRefreshTimer
        interval: 12
        repeat: false
        property int direction: 1
        property bool openSticky: false
        onTriggered: root.performStep(direction, openSticky)
    }

    Timer {
        id: scrollToSelectedTimer
        interval: 16
        repeat: false
        onTriggered: root.scrollToSelected()
    }

    Timer {
        id: tabHoldInitial
        interval: root.tabHoldDelayMs
        repeat: false
        onTriggered: tabHoldRepeat.restart()
    }

    Timer {
        id: tabHoldRepeat
        interval: root.tabHoldRepeatMs
        repeat: true
        onTriggered: {
            if (GlobalStates.altTabOpen)
                root.performStep(root.tabHoldDirection);
        }
    }

    PanelWindow {
        id: panelWindow
        screen: root.focusedScreen
        visible: GlobalStates.altTabOpen
        color: "transparent"

        WlrLayershell.namespace: "quickshell:altTab"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.altTabOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        mask: Region {
            item: GlobalStates.altTabOpen ? dismissMouseCatcher : null
        }

        Rectangle {
            id: dismissMouseCatcher
            anchors.fill: parent
            color: ColorUtils.transparentize(Appearance.colors.colScrim, 0.45)
            opacity: GlobalStates.altTabOpen ? 1 : 0
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: root.cancelWithoutFocus()
        }

        Connections {
            target: GlobalStates
            function onAltTabOpenChanged() {
                if (GlobalStates.altTabOpen) {
                    root.altTabMouseSelectionArmed = false;
                    root.altTabPointerGlobalAnchor = Qt.point(-1, -1);
                    root.rebuildCards();
                    if (root.cards.length === 0) {
                        GlobalStates.altTabStickyMode = false;
                        GlobalStates.altTabOpen = false;
                        return;
                    }
                    Qt.callLater(() => {
                        root.altTabMouseSelectionArmed = false;
                    });
                    flickFocusTimer.restart();
                    root.scheduleScrollToSelected();
                } else {
                    root.tabHoldStop();
                    GlobalStates.altTabStickyMode = false;
                    root.altTabPointerGlobalAnchor = Qt.point(-1, -1);
                    root.tileByIndex = ({});
                }
            }
        }

        Timer {
            id: flickFocusTimer
            interval: 1
            repeat: false
            onTriggered: flick.forceActiveFocus()
        }

        Item {
            id: altTabChrome
            anchors.centerIn: parent
            width: altTabPanelBg.width
            height: altTabPanelBg.height

            StyledRectangularShadow {
                target: altTabPanelBg
            }

            Rectangle {
                id: altTabPanelBg
                width: Math.min(root.maxPanelW, Math.max(280, root.panelLayW + 48))
                height: Math.min(root.maxPanelH, Math.max(200, root.panelLayH + 48))
                radius: Appearance.rounding.large
                color: Appearance.colors.colBackgroundSurfaceContainer

                Flickable {
                    id: flick
                    anchors.fill: parent
                    anchors.margins: 22
                    focus: GlobalStates.altTabOpen
                    clip: contentHeight > height || contentWidth > width
                    flickableDirection: Flickable.HorizontalAndVerticalFlick
                    boundsBehavior: Flickable.StopAtBounds

                    contentWidth: flickContentWrap.width
                    contentHeight: flickContentWrap.height

                    Keys.onPressed: event => {
                        const navNeedsAlt = !GlobalStates.altTabStickyMode;
                        if (event.key === Qt.Key_Escape) {
                            root.cancelWithoutFocus();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.focusSelectedAndClose();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Delete) {
                            if (navNeedsAlt && !(event.modifiers & Qt.AltModifier))
                                return;
                            const a = root.cards[root.selectedIndex]?.address;
                            if (a)
                                root.closeWindowForAddress(a);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                            const back = event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier);
                            root.tabHoldDirection = back ? -1 : 1;
                            if (GlobalStates.altTabStickyMode) {
                                root.performStep(root.tabHoldDirection);
                                event.accepted = true;
                                return;
                            }
                            const altHeld = !!(event.modifiers & Qt.AltModifier);
                            if (altHeld) {
                                event.accepted = true;
                                return;
                            }
                            if (event.isAutoRepeat) {
                                event.accepted = true;
                                return;
                            }
                            root.performStep(root.tabHoldDirection);
                            tabHoldInitial.restart();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Left) {
                            if (navNeedsAlt && !(event.modifiers & Qt.AltModifier))
                                return;
                            root.performStep(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Right) {
                            if (navNeedsAlt && !(event.modifiers & Qt.AltModifier))
                                return;
                            root.performStep(1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            if (navNeedsAlt && !(event.modifiers & Qt.AltModifier))
                                return;
                            root.moveSelectionRowDelta(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            if (navNeedsAlt && !(event.modifiers & Qt.AltModifier))
                                return;
                            root.moveSelectionRowDelta(1);
                            event.accepted = true;
                        }
                    }

                    Keys.onReleased: event => {
                        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)
                            root.tabHoldStop();
                    }

                    Item {
                        id: flickContentWrap
                        width: Math.max(rowColumn.width, root.panelLayW)
                        height: Math.max(rowColumn.implicitHeight, flick.height > 2 ? flick.height : rowColumn.implicitHeight)

                        Column {
                            id: rowColumn
                            width: Math.min(root.innerMaxWidth, Math.max(1, flick.width))
                            spacing: root.effectiveGap
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter

                            Repeater {
                                id: rowRepeater
                                model: root.cardRows

                                delegate: Item {
                                    id: rowWrap
                                    required property int index
                                    required property var modelData
                                    width: rowColumn.width
                                    implicitHeight: rowItem.implicitHeight

                                    Row {
                                        id: rowItem
                                        spacing: root.effectiveGap
                                        anchors.horizontalCenter: parent.horizontalCenter

                                        Repeater {
                                            model: modelData

                                            delegate: Item {
                                                id: cardRoot
                                            required property int modelData
                                            readonly property int tileIndex: modelData

                                            width: cardChrome.width + 2 * root.tileCellOuterPad
                                            height: cardChrome.height + 2 * root.tileCellOuterPad

                                            transform: [
                                                Scale {
                                                    id: cardFocusScale
                                                    origin.x: cardRoot.width * 0.5
                                                    origin.y: cardRoot.height * 0.5
                                                    xScale: cardRoot.isSelected ? 1.03 : 1
                                                    yScale: cardRoot.isSelected ? 1.03 : 1
                                                    Behavior on xScale {
                                                        enabled: !root.gameModeActive
                                                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(cardFocusScale)
                                                    }
                                                    Behavior on yScale {
                                                        enabled: !root.gameModeActive
                                                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(cardFocusScale)
                                                    }
                                                }
                                            ]

                                            readonly property var card: root.cards[tileIndex]
                                            readonly property bool isSelected: GlobalStates.altTabOpen && root.selectedIndex === tileIndex
                                            readonly property var toplevel: root.toplevelForAddressStr(card.address)
                                            readonly property string iconPath: Quickshell.iconPath(AppSearch.guessIcon(card.className), "image-missing")
                                            readonly property var pvDims: root.groupPreviewSlotDims(card)
                                            readonly property bool showPv: root.effectiveShowPreviews
                                            readonly property real previewW: showPv ? pvDims.w : root.iconOnlyTileW
                                            readonly property real previewH: showPv ? pvDims.h : root.iconOnlyAreaH
                                            readonly property bool pvIsColumn: showPv && pvDims.layout === "column"
                                            readonly property real cardRadius: Appearance.rounding.small

                                            Component.onCompleted: root.registerTile(tileIndex, cardRoot)
                                            Component.onDestruction: root.unregisterTile(tileIndex)

                                            Rectangle {
                                                id: cardChrome
                                                anchors.centerIn: parent
                                                width: col.implicitWidth + 2 * root.tileFramePad
                                                height: col.implicitHeight + 2 * root.tileFramePad
                                                radius: cardRoot.cardRadius + 4
                                                color: Appearance.colors.colBackgroundSurfaceContainer
                                                border.width: 2
                                                border.color: cardRoot.isSelected ? ColorUtils.transparentize(Appearance.colors.colSecondary, 0.35) : ColorUtils.transparentize(Appearance.m3colors.m3outline, 0.88)
                                                Behavior on border.color {
                                                    enabled: !root.gameModeActive
                                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(cardChrome)
                                                }

                                                Column {
                                                    id: col
                                                    anchors.centerIn: parent
                                                    spacing: 8
                                                    width: root.tileContentWidth(card)

                                                    RowLayout {
                                                        id: titleRow
                                                        width: parent.width
                                                        spacing: 10
                                                        height: root.titleBarH

                                                        Image {
                                                            Layout.preferredWidth: 26
                                                            Layout.preferredHeight: 26
                                                            Layout.alignment: Qt.AlignVCenter
                                                            source: cardRoot.iconPath
                                                            sourceSize: Qt.size(26, 26)
                                                        }
                                                        Text {
                                                            Layout.fillWidth: true
                                                            Layout.preferredWidth: 0
                                                            Layout.minimumWidth: 0
                                                            Layout.alignment: Qt.AlignVCenter
                                                            text: card.title || card.className || ""
                                                            elide: Text.ElideRight
                                                            maximumLineCount: 1
                                                            wrapMode: Text.NoWrap
                                                            font.pixelSize: Appearance.font.pixelSize.normal
                                                            font.weight: Font.Medium
                                                            color: Appearance.colors.colOnLayer1
                                                        }

                                                        // Reserve width for overlaid close only (see altTabCloseTitleReserve)
                                                        Item {
                                                            Layout.preferredWidth: root.altTabCloseTitleReserve
                                                            Layout.preferredHeight: 1
                                                        }
                                                    }

                                                    Item {
                                                        id: pvSlot
                                                        width: cardRoot.previewW
                                                        height: cardRoot.previewH
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        clip: true

                                                        Rectangle {
                                                            anchors.fill: parent
                                                            visible: cardRoot.showPv
                                                            radius: cardRoot.cardRadius
                                                            color: Appearance.colors.colLayer1
                                                        }

                                                        Repeater {
                                                            model: cardRoot.showPv ? cardRoot.pvDims.members : []

                                                            delegate: Item {
                                                                required property int index
                                                                required property var modelData

                                                                readonly property bool useRowVarWidth: !!cardRoot.pvDims.cellWidths && cardRoot.pvDims.cellWidths.length > 0
                                                                readonly property bool useColVarHeight: !!cardRoot.pvDims.cellHeights && cardRoot.pvDims.cellHeights.length > 0
                                                                readonly property real thisCellW: useRowVarWidth ? cardRoot.pvDims.cellWidths[index] : cardRoot.pvDims.cellW
                                                                readonly property real thisCellH: useColVarHeight ? cardRoot.pvDims.cellHeights[index] : cardRoot.pvDims.cellH
                                                                readonly property real cx: cardRoot.pvIsColumn ? (parent.width - cardRoot.pvDims.cellW) / 2 : (useRowVarWidth ? (parent.width - cardRoot.pvDims.w) / 2 + cardRoot.pvDims.rowXOffsets[index] : index * (cardRoot.pvDims.cellW + cardRoot.pvDims.gap) + (parent.width - cardRoot.pvDims.w) / 2)
                                                                readonly property real cy: cardRoot.pvIsColumn ? (useColVarHeight ? (parent.height - cardRoot.pvDims.h) / 2 + cardRoot.pvDims.columnYOffsets[index] : index * (cardRoot.pvDims.cellH + cardRoot.pvDims.gap) + (parent.height - cardRoot.pvDims.h) / 2) : (parent.height - cardRoot.pvDims.cellH) / 2

                                                                x: cx
                                                                y: cy
                                                                width: thisCellW
                                                                height: thisCellH
                                                                clip: true
                                                                visible: cardRoot.showPv

                                                                ScreencopyView {
                                                                    anchors.fill: parent
                                                                    visible: cardRoot.showPv
                                                                    captureSource: GlobalStates.altTabOpen ? (root.toplevelForAddressStr(modelData.address) ?? null) : null
                                                                    live: true
                                                                    paintCursor: false
                                                                    constraintSize: Qt.size(thisCellW, thisCellH)
                                                                }
                                                            }
                                                        }

                                                        Rectangle {
                                                            id: previewTint
                                                            z: 1
                                                            anchors.fill: parent
                                                            visible: cardRoot.showPv
                                                            radius: cardRoot.cardRadius
                                                            color: ColorUtils.transparentize(Appearance.colors.colLayer2, cardRoot.isSelected ? 0.94 : 0.98)
                                                            Behavior on color {
                                                                enabled: !root.gameModeActive && cardRoot.showPv
                                                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(previewTint)
                                                            }
                                                        }

                                                        Item {
                                                            anchors.fill: parent
                                                            visible: !cardRoot.showPv
                                                            Rectangle {
                                                                anchors.fill: parent
                                                                radius: cardRoot.cardRadius
                                                                color: Appearance.colors.colSurfaceContainerLow
                                                                border.color: ColorUtils.transparentize(Appearance.m3colors.m3outline, 0.85)
                                                                border.width: 1
                                                            }
                                                            Image {
                                                                anchors.centerIn: parent
                                                                width: 56
                                                                height: 56
                                                                source: cardRoot.iconPath
                                                                sourceSize: Qt.size(56, 56)
                                                            }
                                                        }

                                                        Rectangle {
                                                            visible: card.groupCount > 1
                                                            anchors.top: parent.top
                                                            anchors.right: parent.right
                                                            anchors.margins: 6
                                                            height: 22
                                                            width: countLbl.width + 12
                                                            radius: 11
                                                            color: Appearance.colors.colSecondaryContainer
                                                            z: 2

                                                            Text {
                                                                id: countLbl
                                                                anchors.centerIn: parent
                                                                text: card.groupCount
                                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                                font.weight: Font.DemiBold
                                                                color: Appearance.colors.colOnSecondaryContainer
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            MouseArea {
                                                z: 1
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                acceptedButtons: Qt.LeftButton
                                                onEntered: {
                                                    if (root.altTabMouseSelectionArmed)
                                                        root.selectedIndex = tileIndex;
                                                }
                                                onPositionChanged: {
                                                    const g = parent.mapToGlobal(Qt.point(mouseX, mouseY));
                                                    if (root.altTabPointerGlobalAnchor.x < 0) {
                                                        root.altTabPointerGlobalAnchor = g;
                                                        return;
                                                    }
                                                    const dx = g.x - root.altTabPointerGlobalAnchor.x;
                                                    const dy = g.y - root.altTabPointerGlobalAnchor.y;
                                                    if (dx * dx + dy * dy < root.altTabMouseMoveThreshold * root.altTabMouseMoveThreshold)
                                                        return;
                                                    root.altTabMouseSelectionArmed = true;
                                                    root.selectedIndex = tileIndex;
                                                }
                                                onClicked: {
                                                    root.selectedIndex = tileIndex;
                                                    root.focusSelectedAndClose();
                                                }
                                            }

                                            ButtonGroup {
                                                z: 2
                                                anchors.top: cardChrome.top
                                                anchors.right: cardChrome.right
                                                anchors.topMargin: root.tileFramePad + 2
                                                anchors.rightMargin: root.tileFramePad + 2
                                                padding: 0
                                                spacing: 0

                                                GroupButton {
                                                    colBackground: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer)
                                                    baseWidth: root.titleBarH - 10
                                                    baseHeight: root.titleBarH - 10
                                                    buttonRadius: Appearance.rounding.full
                                                    contentItem: MaterialSymbol {
                                                        anchors.centerIn: parent
                                                        horizontalAlignment: Text.AlignHCenter
                                                        text: "close"
                                                        iconSize: Appearance.font.pixelSize.smaller
                                                        color: Appearance.m3colors.m3onSurface
                                                    }
                                                    onClicked: {
                                                        root.closeWindowForAddress(card.address);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    }

    function normalizeAddress(addr) {
        const s = String(addr ?? "").toLowerCase();
        return s.startsWith("0x") ? s.slice(2) : s;
    }

    Connections {
        target: HyprlandData
        function onWindowListChanged() {
            if (!GlobalStates.altTabOpen)
                return;
            const prevAddr = root.cards[root.selectedIndex]?.address;
            root.rebuildCardsReselecting(prevAddr);
        }
    }

    Connections {
        target: Hyprland
        function onFocusedMonitorChanged() {
            if (!GlobalStates.altTabOpen || Config.options.altTab?.perMonitor !== true)
                return;
            const prevAddr = root.cards[root.selectedIndex]?.address;
            root.rebuildCardsReselecting(prevAddr);
        }
    }

    GlobalShortcut {
        name: "altTabNext"
        description: "Alt+Tab window switcher (forward)"

        onPressed: {
            root.globalAltTabStep(1);
        }
    }

    GlobalShortcut {
        name: "altTabPrev"
        description: "Alt+Shift+Tab window switcher (backward)"

        onPressed: {
            root.globalAltTabStep(-1);
        }
    }

    GlobalShortcut {
        name: "altTabCommit"
        description: "Release Alt to confirm alt-tab selection"

        onReleased: {
            root.tabHoldStop();
            if (!GlobalStates.altTabStickyMode)
                root.focusSelectedAndClose();
        }
    }

    GlobalShortcut {
        name: "altTabStickyNext"
        description: "Alt+Ctrl+Tab sticky window switcher (forward)"

        onPressed: {
            root.globalAltTabStickyStep(1);
        }
    }

    GlobalShortcut {
        name: "altTabStickyPrev"
        description: "Alt+Ctrl+Shift+Tab sticky window switcher (backward)"

        onPressed: {
            root.globalAltTabStickyStep(-1);
        }
    }
}