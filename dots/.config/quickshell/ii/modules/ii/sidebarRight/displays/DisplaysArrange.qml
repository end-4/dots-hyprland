import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

FloatingWindow {
    id: win
    title: Translation.tr("Arrange displays")
    implicitWidth: 820
    implicitHeight: 760
    color: Appearance.colors.colLayer0
    visible: Displays.arrangeOpen
    property bool modeListOpen: false

    onVisibleChanged: {
        if (!visible) {
            win.modeListOpen = false;
            return;
        }
        canvas.sync();
    }

    TextInput {
        id: keySink
        width: 0
        height: 0
        opacity: 0
        focus: true
        activeFocusOnPress: false
        color: Appearance.colors.colOnSurface
        selectionColor: Appearance.colors.colPrimary
        selectedTextColor: Appearance.colors.colOnPrimary
        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        Keys.onEscapePressed: {
            if (Displays.confirmOpen) Displays.revertChanges();
            else Displays.arrangeOpen = false;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Arrange displays")
                color: Appearance.colors.colOnSurface
                font.pixelSize: Appearance.font.pixelSize.title
            }

            RippleButton {
                implicitWidth: 36
                implicitHeight: 36
                buttonRadius: height / 2
                onClicked: Displays.arrangeOpen = false
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    iconSize: 20
                    color: Appearance.colors.colOnSurfaceVariant
                    text: "close"
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.small
            text: Displays.duplicating
                  ? Translation.tr("Duplicate shows the same image on every screen. Extend gives each screen its own place. Dragging is for Extend only.")
                  : Translation.tr("Drag a screen. Edges snap together, and the position is applied when you let go.")
        }

        Item {
            id: canvas
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            Layout.fillHeight: false
            clip: true

            property var placed: []
            property string selected: ""
            property bool dragging: false
            property bool moved: false
            property string dragName: ""
            property real dragFit: 1
            property real dragMinX: 0
            property real dragMinY: 0
            property real dragSpanX: 1
            property real dragSpanY: 1

            readonly property var liveBounds: boundsOf(placed)
            readonly property real viewFit: dragging ? dragFit : liveFit
            readonly property real viewMinX: dragging ? dragMinX : liveBounds.minX
            readonly property real viewMinY: dragging ? dragMinY : liveBounds.minY
            readonly property real viewSpanX: dragging ? dragSpanX : liveBounds.spanX
            readonly property real viewSpanY: dragging ? dragSpanY : liveBounds.spanY
            readonly property real liveFit: {
                const sx = Math.max(1, width - 28);
                const sy = Math.max(1, height - 28);
                return Math.min(sx / liveBounds.spanX, sy / liveBounds.spanY);
            }
            readonly property real offsetX: (width - viewSpanX * viewFit) / 2
            readonly property real offsetY: (height - viewSpanY * viewFit) / 2

            onSelectedChanged: win.modeListOpen = false

            function boundsOf(list) {
                let minX = 0;
                let minY = 0;
                let maxX = 1;
                let maxY = 1;
                const items = list || [];
                if (items.length) {
                    minX = Infinity;
                    minY = Infinity;
                    maxX = -Infinity;
                    maxY = -Infinity;
                    for (let i = 0; i < items.length; i++) {
                        const m = items[i];
                        minX = Math.min(minX, m.posX);
                        minY = Math.min(minY, m.posY);
                        maxX = Math.max(maxX, m.posX + (m.boxW || 1));
                        maxY = Math.max(maxY, m.posY + (m.boxH || 1));
                    }
                }
                return {
                    minX: minX,
                    minY: minY,
                    spanX: Math.max(1, maxX - minX),
                    spanY: Math.max(1, maxY - minY),
                };
            }

            function sync() {
                if (dragging) return;
                const list = Displays.previewLayout(Displays.monitors).map(m => {
                    const copy = Object.assign({}, m);
                    copy.baseX = m.posX;
                    copy.baseY = m.posY;
                    return copy;
                });
                placed = list;
                if (Displays.cycleName && selected === Displays.cycleName)
                    return;
                if (!list.some(m => m.name === selected))
                    selected = list.length ? list[0].name : "";
            }

            function copyPlaced() {
                return (placed || []).map(m => Object.assign({}, m));
            }

            function hit(px, py) {
                const list = placed || [];
                for (let i = list.length - 1; i >= 0; i--) {
                    const m = list[i];
                    const rx = offsetX + (m.posX - viewMinX) * viewFit;
                    const ry = offsetY + (m.posY - viewMinY) * viewFit;
                    const rw = (m.boxW || 1) * viewFit;
                    const rh = (m.boxH || 1) * viewFit;
                    if (px >= rx && py >= ry && px <= rx + rw && py <= ry + rh)
                        return m;
                }
                return null;
            }

            function snap(target, x, y, list) {
                const threshold = 18 / Math.max(viewFit, 0.05);
                let bestX = x;
                let bestY = y;
                let bestDx = threshold;
                let bestDy = threshold;
                const w = target.boxW || 1;
                const h = target.boxH || 1;
                for (let i = 0; i < list.length; i++) {
                    const other = list[i];
                    if (other.name === target.name) continue;
                    const xs = [other.posX - w, other.posX, other.posX + other.boxW - w, other.posX + other.boxW];
                    const ys = [other.posY - h, other.posY, other.posY + other.boxH - h, other.posY + other.boxH];
                    for (let xi = 0; xi < xs.length; xi++) {
                        const d = Math.abs(xs[xi] - x);
                        if (d < bestDx) {
                            bestDx = d;
                            bestX = xs[xi];
                        }
                    }
                    for (let yi = 0; yi < ys.length; yi++) {
                        const d = Math.abs(ys[yi] - y);
                        if (d < bestDy) {
                            bestDy = d;
                            bestY = ys[yi];
                        }
                    }
                }
                return { x: bestX, y: bestY };
            }

            function preview(name, x, y) {
                const list = copyPlaced();
                const target = list.find(m => m.name === name);
                if (!target) return;
                const snapped = snap(target, x, y, list);
                target.posX = snapped.x;
                target.posY = snapped.y;
                placed = list;
            }

            function separate(list, name) {
                const target = list.find(m => m.name === name);
                if (!target) return;
                for (let pass = 0; pass < list.length; pass++) {
                    for (let i = 0; i < list.length; i++) {
                        const other = list[i];
                        if (other.name === target.name) continue;
                        const overlapX = Math.min(target.posX + target.boxW, other.posX + other.boxW) - Math.max(target.posX, other.posX);
                        const overlapY = Math.min(target.posY + target.boxH, other.posY + other.boxH) - Math.max(target.posY, other.posY);
                        if (overlapX <= 0 || overlapY <= 0) continue;
                        if (overlapX < overlapY)
                            target.posX += (target.posX + target.boxW / 2) < (other.posX + other.boxW / 2) ? -overlapX : overlapX;
                        else
                            target.posY += (target.posY + target.boxH / 2) < (other.posY + other.boxH / 2) ? -overlapY : overlapY;
                    }
                }
            }

            function logicalPoint(list, name) {
                const moved = list.find(m => m.name === name);
                if (!moved) return;
                const sx = moved.lw / Math.max(1, moved.boxW);
                const sy = moved.lh / Math.max(1, moved.boxH);
                let lx = moved.lx + (moved.posX - moved.baseX) * sx;
                let ly = moved.ly + (moved.posY - moved.baseY) * sy;
                const threshold = 18 / Math.max(viewFit, 0.05);
                let bestX = threshold;
                let bestY = threshold;
                for (let i = 0; i < list.length; i++) {
                    const other = list[i];
                    if (other.name === moved.name) continue;
                    const yOverlap = Math.min(moved.posY + moved.boxH, other.posY + other.boxH) - Math.max(moved.posY, other.posY);
                    const xOverlap = Math.min(moved.posX + moved.boxW, other.posX + other.boxW) - Math.max(moved.posX, other.posX);
                    if (yOverlap > 0) {
                        const edges = [
                            { d: Math.abs(moved.posX - (other.posX + other.boxW)), v: other.lx + other.lw },
                            { d: Math.abs((moved.posX + moved.boxW) - other.posX), v: other.lx - moved.lw },
                            { d: Math.abs(moved.posX - other.posX), v: other.lx },
                            { d: Math.abs((moved.posX + moved.boxW) - (other.posX + other.boxW)), v: other.lx + other.lw - moved.lw },
                        ];
                        for (let e = 0; e < edges.length; e++) {
                            if (edges[e].d > bestX) continue;
                            bestX = edges[e].d;
                            lx = edges[e].v;
                        }
                    }
                    if (xOverlap > 0) {
                        const edges = [
                            { d: Math.abs(moved.posY - (other.posY + other.boxH)), v: other.ly + other.lh },
                            { d: Math.abs((moved.posY + moved.boxH) - other.posY), v: other.ly - moved.lh },
                            { d: Math.abs(moved.posY - other.posY), v: other.ly },
                            { d: Math.abs((moved.posY + moved.boxH) - (other.posY + other.boxH)), v: other.ly + other.lh - moved.lh },
                        ];
                        for (let e = 0; e < edges.length; e++) {
                            if (edges[e].d > bestY) continue;
                            bestY = edges[e].d;
                            ly = edges[e].v;
                        }
                    }
                }
                moved.lx = Math.round(lx);
                moved.ly = Math.round(ly);
            }

            function commit() {
                const list = copyPlaced();
                separate(list, dragName);
                logicalPoint(list, dragName);
                const full = Displays.snapshot();
                for (let i = 0; i < list.length; i++) {
                    const src = list[i];
                    const dst = full.find(m => m.name === src.name);
                    if (!dst) continue;
                    dst.x = src.lx;
                    dst.y = src.ly;
                    dst.pendingPosition = "";
                }
                dragging = false;
                Displays.applyPositions(full);
            }

            Rectangle {
                anchors.fill: parent
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: Appearance.colors.colOutlineVariant
            }

            Repeater {
                model: ScriptModel {
                    values: canvas.placed || []
                }
                delegate: Rectangle {
                    required property var modelData
                    x: canvas.offsetX + (modelData.posX - canvas.viewMinX) * canvas.viewFit
                    y: canvas.offsetY + (modelData.posY - canvas.viewMinY) * canvas.viewFit
                    width: (modelData.boxW || 1) * canvas.viewFit
                    height: (modelData.boxH || 1) * canvas.viewFit
                    radius: 8
                    color: Appearance.colors.colLayer2
                    border.width: modelData.name === canvas.selected ? 2 : 1
                    border.color: modelData.name === canvas.selected ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 12
                        spacing: 2

                        StyledText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            color: Appearance.colors.colOnLayer2
                            text: modelData.name
                        }
                        StyledText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            text: modelData.textW + "×" + modelData.textH
                        }
                    }
                }
            }

            MouseArea {
                id: pointer
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                property real startMouseX: 0
                property real startMouseY: 0
                property real startMonX: 0
                property real startMonY: 0

                onPressed: (event) => {
                    const hit = canvas.hit(event.x, event.y);
                    if (!hit) return;
                    canvas.selected = hit.name;
                    if (Displays.duplicating) {
                        canvas.dragging = false;
                        canvas.dragName = "";
                        canvas.moved = false;
                        return;
                    }
                    canvas.moved = false;
                    canvas.dragName = hit.name;
                    canvas.dragFit = canvas.liveFit;
                    canvas.dragMinX = canvas.liveBounds.minX;
                    canvas.dragMinY = canvas.liveBounds.minY;
                    canvas.dragSpanX = canvas.liveBounds.spanX;
                    canvas.dragSpanY = canvas.liveBounds.spanY;
                    canvas.dragging = true;
                    startMouseX = event.x;
                    startMouseY = event.y;
                    startMonX = hit.posX;
                    startMonY = hit.posY;
                }
                onPositionChanged: (event) => {
                    if (Displays.duplicating || !canvas.dragging || !canvas.dragName) return;
                    const dx = event.x - startMouseX;
                    const dy = event.y - startMouseY;
                    if (dx * dx + dy * dy < 16) return;
                    canvas.moved = true;
                    canvas.preview(canvas.dragName, startMonX + dx / canvas.dragFit, startMonY + dy / canvas.dragFit);
                }
                onReleased: {
                    if (Displays.duplicating) {
                        canvas.dragging = false;
                        canvas.dragName = "";
                        canvas.moved = false;
                        return;
                    }
                    if (canvas.dragging && canvas.moved)
                        canvas.commit();
                    else
                        canvas.dragging = false;
                    canvas.dragName = "";
                }
                onCanceled: {
                    canvas.dragging = false;
                    canvas.dragName = "";
                    canvas.sync();
                }
            }
        }

        RowLayout {
            visible: Displays.enabledCount > 1
            Layout.fillWidth: true
            spacing: 8

            DisplayButton {
                toggled: !Displays.duplicating
                buttonText: Translation.tr("Extend")
                onClicked: Displays.setExtended()
            }
            DisplayButton {
                toggled: Displays.duplicating
                buttonText: Translation.tr("Duplicate")
                onClicked: Displays.setDuplicated(Displays.duplicating ? Displays.mirrorSource : (canvas.selected || Displays.mirrorSource))
            }
        }

        RowLayout {
            visible: Displays.duplicating
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small
                text: Translation.tr("Source")
            }
            Repeater {
                model: ScriptModel {
                    values: (Displays.monitors || []).filter(m => !m.disabled)
                }
                delegate: DisplayButton {
                    required property var modelData
                    toggled: modelData.name === Displays.mirrorSource
                    buttonText: modelData.name
                    onClicked: Displays.setDuplicated(modelData.name)
                }
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: settingsCol.implicitHeight
            flickableDirection: Flickable.VerticalFlick

            ColumnLayout {
                id: settingsCol
                width: parent.width
                spacing: 8

                readonly property var selectedMonitor: (Displays.monitors || []).find(m => m.name === canvas.selected) || null
                readonly property bool showControls: !!selectedMonitor
                readonly property var modeOptions: {
                    const monitor = selectedMonitor;
                    const out = ["preferred"];
                    const seen = { preferred: true };
                    const modes = monitor ? (monitor.availableModes || []) : [];
                    for (let i = 0; i < modes.length; i++) {
                        if (seen[modes[i]]) continue;
                        seen[modes[i]] = true;
                        out.push(modes[i]);
                    }
                    return out;
                }

                StyledText {
                    visible: !settingsCol.selectedMonitor
                    color: Appearance.colors.colSubtext
                    text: Translation.tr("Select a screen")
                }

                StyledText {
                    visible: !!settingsCol.selectedMonitor
                    color: Appearance.colors.colOnSurface
                    text: settingsCol.selectedMonitor ? settingsCol.selectedMonitor.name : ""
                }

                StyledText {
                    visible: settingsCol.showControls
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: Translation.tr("Rotation")
                }
                RowLayout {
                    visible: settingsCol.showControls
                    Layout.fillWidth: true
                    spacing: 4
                    Repeater {
                        model: [0, 90, 180, 270]
                        delegate: DisplayButton {
                            required property var modelData
                            readonly property int current: ((settingsCol.selectedMonitor && settingsCol.selectedMonitor.transform) | 0) & 3
                            toggled: current === (modelData === 270 ? 3 : modelData === 180 ? 2 : modelData === 90 ? 1 : 0)
                            buttonText: modelData + "°"
                            onClicked: {
                                if (!settingsCol.selectedMonitor) return;
                                const rot = modelData === 270 ? 3 : modelData === 180 ? 2 : modelData === 90 ? 1 : 0;
                                const flip = (settingsCol.selectedMonitor.transform | 0) >= 4;
                                Displays.setTransform(settingsCol.selectedMonitor.name, (flip ? 4 : 0) + rot);
                            }
                        }
                    }
                    DisplayButton {
                        toggled: settingsCol.selectedMonitor && ((settingsCol.selectedMonitor.transform | 0) >= 4)
                        buttonText: Translation.tr("Flip")
                        onClicked: {
                            if (!settingsCol.selectedMonitor) return;
                            const current = settingsCol.selectedMonitor.transform | 0;
                            const rot = current & 3;
                            const flip = current < 4;
                            Displays.setTransform(settingsCol.selectedMonitor.name, (flip ? 4 : 0) + rot);
                        }
                    }
                }

                DisplayButton {
                    visible: settingsCol.showControls
                    toggled: !!(settingsCol.selectedMonitor && settingsCol.selectedMonitor.vrr)
                    buttonText: Translation.tr("Variable refresh")
                    onClicked: {
                        if (!settingsCol.selectedMonitor) return;
                        Displays.setVrr(settingsCol.selectedMonitor.name, !settingsCol.selectedMonitor.vrr);
                    }
                }

                StyledText {
                    visible: settingsCol.showControls
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: Translation.tr("Resolution")
                }
                DisplayButton {
                    visible: settingsCol.showControls
                    Layout.fillWidth: true
                    buttonText: {
                        const mode = settingsCol.selectedMonitor ? settingsCol.selectedMonitor.mode : "";
                        if (!mode || mode === "preferred") return Translation.tr("Preferred");
                        return mode;
                    }
                    onClicked: win.modeListOpen = !win.modeListOpen
                }
                Flickable {
                    visible: settingsCol.showControls && win.modeListOpen
                    Layout.fillWidth: true
                    Layout.preferredHeight: 160
                    Layout.maximumHeight: 160
                    contentHeight: modeCol.implicitHeight
                    clip: true
                    flickableDirection: Flickable.VerticalFlick

                    Column {
                        id: modeCol
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: ScriptModel {
                                values: settingsCol.modeOptions
                            }
                            delegate: DisplayButton {
                                required property var modelData
                                width: modeCol.width
                                toggled: settingsCol.selectedMonitor && settingsCol.selectedMonitor.mode === modelData
                                buttonText: modelData === "preferred" ? Translation.tr("Preferred") : modelData
                                onClicked: {
                                    if (!settingsCol.selectedMonitor) return;
                                    Displays.setMode(settingsCol.selectedMonitor.name, modelData);
                                    win.modeListOpen = false;
                                }
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item { Layout.fillWidth: true }

            DisplayButton {
                primary: true
                buttonText: Translation.tr("Keep")
                onClicked: {
                    Displays.keepChanges();
                    Displays.arrangeOpen = false;
                }
            }
        }
    }

    Connections {
        target: Displays
        function onMonitorsChanged() { canvas.sync(); }
    }

    Component.onCompleted: canvas.sync()
}
