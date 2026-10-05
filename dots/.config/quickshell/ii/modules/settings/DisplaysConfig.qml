import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.functions as CF
import qs.modules.common.widgets

Item {
    id: root

    Component.onCompleted: {
        DisplayService.refresh();
    }

    readonly property var disp: DisplayService.selectedDisplay
    readonly property var specs: DisplayService.selectedDisplaySpecs

    // ================= Hardware Specs Helpers =================
    readonly property real diagonalInches: {
        if (!disp || !disp.physicalWidth || !disp.physicalHeight) return 0;
        let diagMm = Math.sqrt(disp.physicalWidth * disp.physicalWidth + disp.physicalHeight * disp.physicalHeight);
        return diagMm / 25.4;
    }

    readonly property real ppi: {
        if (!disp || diagonalInches <= 0) return 0;
        let diagPx = Math.sqrt(disp.width * disp.width + disp.height * disp.height);
        return diagPx / diagonalInches;
    }

    readonly property string aspectRatioStr: {
        if (!disp || !disp.width || !disp.height) return "";
        let w = disp.width;
        let h = disp.height;
        let gcd = function(a, b) { return b === 0 ? a : gcd(b, a % b); };
        let d = gcd(w, h);
        let rw = w / d;
        let rh = h / d;
        if (rw === 16 && rh === 9) return "16:9 (Widescreen)";
        if (rw === 16 && rh === 10) return "16:10 (Productivity)";
        if (rw === 21 && rh === 9) return "21:9 (Ultrawide)";
        if (rw === 4 && rh === 3) return "4:3 (Classic)";
        if (rw === 8 && rh === 5) return "16:10 (8:5)";
        return `${rw}:${rh}`;
    }

    // Unique resolutions extracted from availableModes
    readonly property var parsedModes: {
        if (!disp || !disp.availableModes || disp.availableModes.length === 0) {
            let defW = (disp && disp.width) ? disp.width : 1920;
            let defH = (disp && disp.height) ? disp.height : 1080;
            return { resolutions: [`${defW}x${defH}`], rateMap: {} };
        }
        let map = {};
        for (let i = 0; i < disp.availableModes.length; i++) {
            let m = disp.availableModes[i];
            let match = m.match(/^(\d+x\d+)@([\d\.]+)Hz?$/);
            if (match) {
                let res = match[1];
                let hz = parseFloat(match[2]);
                if (!map[res]) map[res] = [];
                if (!map[res].some(h => Math.abs(h - hz) < 0.05)) {
                    map[res].push(hz);
                }
            }
        }
        let resList = Object.keys(map);
        resList.sort((a, b) => {
            let [wa, ha] = a.split("x").map(Number);
            let [wb, hb] = b.split("x").map(Number);
            return (wb * hb) - (wa * ha);
        });
        for (let r in map) {
            map[r].sort((a, b) => b - a);
        }
        return { resolutions: resList, rateMap: map };
    }

    readonly property string currentResStr: disp ? `${disp.width}x${disp.height}` : "1920x1080"
    readonly property var currentRates: parsedModes.rateMap[currentResStr] || [60.0]

    // ================= 2D Canvas Geometry & Dragging State =================
    property real canvasWidth: 800
    property real canvasHeight: 440
    property string activeDraggingDisplay: ""
    property real dragStartX: 0
    property real dragStartY: 0
    property real dragItemStartX: 0
    property real dragItemStartY: 0
    property real frozenOriginX: 0
    property real frozenOriginY: 0
    property real frozenScaleFactor: 1.0
    property real activeDisplayVirtX: 0
    property real activeDisplayVirtY: 0

    property real snapGuideX: -1
    property real snapGuideY: -1
    property bool showSnapGuideX: false
    property bool showSnapGuideY: false

    property bool showSavedFeedback: false

    Timer {
        id: savedFeedbackTimer
        interval: 2500
        onTriggered: root.showSavedFeedback = false
    }

    readonly property var boundingBox: {
        let list = DisplayService.pendingDisplays.filter(d => !d.disabled);
        if (list.length === 0) return { minX: 0, maxX: 1920, minY: 0, maxY: 1080, width: 1920, height: 1080 };

        let minX = list[0].x;
        let minY = list[0].y;
        let maxX = minX + ((list[0].transform === 1 || list[0].transform === 3) ? list[0].height : list[0].width) / (list[0].scale || 1.0);
        let maxY = minY + ((list[0].transform === 1 || list[0].transform === 3) ? list[0].width : list[0].height) / (list[0].scale || 1.0);

        for (let i = 1; i < list.length; i++) {
            let d = list[i];
            let effW = (d.transform === 1 || d.transform === 3) ? d.height : d.width;
            let effH = (d.transform === 1 || d.transform === 3) ? d.width : d.height;
            let logW = effW / (d.scale || 1.0);
            let logH = effH / (d.scale || 1.0);

            if (d.x < minX) minX = d.x;
            if (d.y < minY) minY = d.y;
            if (d.x + logW > maxX) maxX = d.x + logW;
            if (d.y + logH > maxY) maxY = d.y + logH;
        }

        let w = Math.max(maxX - minX, 100);
        let h = Math.max(maxY - minY, 100);
        return { minX: minX, maxX: maxX, minY: minY, maxY: maxY, width: w, height: h };
    }

    readonly property real canvasMargin: 30
    readonly property real availCanvasWidth: Math.max(canvasWidth - canvasMargin * 2, 200)
    readonly property real availCanvasHeight: Math.max(canvasHeight - canvasMargin * 2, 150)
    readonly property real scaleFactor: {
        let paddingW = boundingBox.width + 400;
        let paddingH = boundingBox.height + 400;
        let sx = availCanvasWidth / paddingW;
        let sy = availCanvasHeight / paddingH;
        return Math.min(sx, sy);
    }

    readonly property real originX: (canvasWidth - boundingBox.width * scaleFactor) / 2 - boundingBox.minX * scaleFactor
    readonly property real originY: (canvasHeight - boundingBox.height * scaleFactor) / 2 - boundingBox.minY * scaleFactor

    // ================= Main Content Page =================
    ContentPage {
        anchors.fill: parent
        forceWidth: false
        baseWidth: Math.min(920, root.width - 40)

        // ---------------- Header Section ----------------
            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                StyledRectangle {
                    width: 48
                    height: 48
                    radius: 24
                    color: Appearance.m3colors.m3primaryContainer

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "screenshot_monitor"
                        iconSize: 26
                        color: Appearance.m3colors.m3onPrimaryContainer
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        spacing: 10
                        StyledText {
                            text: Translation.tr("Displays & Monitors")
                            font.bold: true
                            font.pixelSize: Appearance.font.pixelSize.large
                            color: Appearance.m3colors.m3onSurface
                        }

                        StyledRectangle {
                            visible: DisplayService.dirty
                            implicitHeight: 22
                            radius: 11
                            color: Appearance.m3colors.m3tertiaryContainer
                            RowLayout {
                                anchors.centerIn: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 4
                                MaterialSymbol {
                                    text: "edit"
                                    iconSize: 14
                                    color: Appearance.m3colors.m3onTertiaryContainer
                                }
                                StyledText {
                                    text: Translation.tr("Unsaved Changes")
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Appearance.m3colors.m3onTertiaryContainer
                                }
                            }
                        }
                    }

                    StyledText {
                        text: Translation.tr("Arrange multi-monitor layout with drag-and-drop, configure refresh rates, scale, and VRR.")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.m3colors.m3onSurfaceVariant
                    }
                }

                RippleButton {
                    implicitWidth: refreshRow.implicitWidth + 24
                    implicitHeight: 36
                    padding: 10
                    buttonRadius: Appearance.rounding.full
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    onClicked: DisplayService.refresh()

                    RowLayout {
                        id: refreshRow
                        anchors.centerIn: parent
                        spacing: 6
                        MaterialSymbol {
                            text: "refresh"
                            iconSize: 18
                            color: Appearance.m3colors.m3onSurface
                        }
                        StyledText {
                            text: Translation.tr("Refresh")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.m3colors.m3onSurface
                        }
                    }
                    StyledToolTip { text: Translation.tr("Re-scan connected displays") }
                }
            }

            // ---------------- 2D Drag-and-Drop Spatial Canvas ----------------
            StyledRectangle {
                id: canvasArea
                Layout.fillWidth: true
                implicitHeight: 440
                radius: Appearance.rounding.normal
                color: Appearance.m3colors.m3surfaceContainerLow
                clip: true

                onWidthChanged: {
                    if (width > 0) root.canvasWidth = width;
                }
                onHeightChanged: {
                    if (height > 0) root.canvasHeight = height;
                }
                Component.onCompleted: {
                    if (width > 0) root.canvasWidth = width;
                    if (height > 0) root.canvasHeight = height;
                }

                // Subtle Canvas Grid Pattern
                Canvas {
                    id: gridCanvas
                    anchors.fill: parent
                    opacity: 0.15
                    onPaint: {
                        let ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.fillStyle = Appearance.m3colors.m3onSurfaceVariant;
                        let step = 24;
                        for (let x = 12; x < width; x += step) {
                            for (let y = 12; y < height; y += step) {
                                ctx.beginPath();
                                ctx.arc(x, y, 1.2, 0, Math.PI * 2);
                                ctx.fill();
                            }
                        }
                    }
                    Connections {
                        target: Appearance
                        function onM3colorsChanged() { gridCanvas.requestPaint(); }
                    }
                }

                // Top Toolbar inside canvas
                RowLayout {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 12
                    }
                    spacing: 8
                    z: 10

                    RowLayout {
                        spacing: 6
                        MaterialSymbol {
                            text: "touch_app"
                            iconSize: 18
                            color: Appearance.m3colors.m3primary
                        }
                        StyledText {
                            text: Translation.tr("Drag displays to rearrange physical layout")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.m3colors.m3onSurfaceVariant
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RippleButton {
                        implicitWidth: lrRow.implicitWidth + 20
                        implicitHeight: 28
                        padding: 8
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.m3colors.m3surfaceContainerHigh
                        onClicked: DisplayService.alignDisplays("left-to-right")
                        RowLayout {
                            id: lrRow
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialSymbol { text: "view_column"; iconSize: 16; color: Appearance.m3colors.m3onSurface }
                            StyledText { text: Translation.tr("Side-by-Side"); font.pixelSize: Appearance.font.pixelSize.small }
                        }
                        StyledToolTip { text: Translation.tr("Align monitors horizontally left to right") }
                    }

                    RippleButton {
                        implicitWidth: stackRow.implicitWidth + 20
                        implicitHeight: 28
                        padding: 8
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.m3colors.m3surfaceContainerHigh
                        onClicked: DisplayService.alignDisplays("stacked")
                        RowLayout {
                            id: stackRow
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialSymbol { text: "table_rows"; iconSize: 16; color: Appearance.m3colors.m3onSurface }
                            StyledText { text: Translation.tr("Stacked"); font.pixelSize: Appearance.font.pixelSize.small }
                        }
                        StyledToolTip { text: Translation.tr("Stack monitors vertically") }
                    }

                    RippleButton {
                        implicitWidth: idRow.implicitWidth + 20
                        implicitHeight: 28
                        padding: 8
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.m3colors.m3primaryContainer
                        onClicked: DisplayService.identifyDisplays()
                        RowLayout {
                            id: idRow
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialSymbol { text: "visibility"; iconSize: 16; color: Appearance.m3colors.m3onPrimaryContainer }
                            StyledText {
                                text: Translation.tr("Identify")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.m3colors.m3onPrimaryContainer
                            }
                        }
                        StyledToolTip { text: Translation.tr("Show screen number badges on all physical displays") }
                    }
                }

                // Snap Guide Lines
                Rectangle {
                    visible: root.showSnapGuideX
                    x: root.snapGuideX
                    y: 0
                    width: 2
                    height: parent.height
                    color: Appearance.m3colors.m3primary
                    z: 99
                }

                Rectangle {
                    visible: root.showSnapGuideY
                    x: 0
                    y: root.snapGuideY
                    width: parent.width
                    height: 2
                    color: Appearance.m3colors.m3primary
                    z: 99
                }

                // Draggable Monitor Cards
                Repeater {
                    model: DisplayService.pendingDisplays

                    delegate: Item {
                        id: monitorItem
                        required property var modelData
                        required property int index

                        readonly property bool isSelected: DisplayService.selectedDisplayName === modelData.name
                        readonly property bool isDragging: root.activeDraggingDisplay === modelData.name
                        readonly property bool isDisabled: modelData.disabled
                        readonly property real effW: (modelData.transform === 1 || modelData.transform === 3) ? modelData.height : modelData.width
                        readonly property real effH: (modelData.transform === 1 || modelData.transform === 3) ? modelData.width : modelData.height
                        readonly property real logW: effW / (modelData.scale || 1.0)
                        readonly property real logH: effH / (modelData.scale || 1.0)

                        readonly property real currentVirtX: isDragging ? root.activeDisplayVirtX : modelData.x
                        readonly property real currentVirtY: isDragging ? root.activeDisplayVirtY : modelData.y
                        readonly property real currentScale: root.activeDraggingDisplay !== "" ? root.frozenScaleFactor : root.scaleFactor
                        readonly property real currentOriginX: root.activeDraggingDisplay !== "" ? root.frozenOriginX : root.originX
                        readonly property real currentOriginY: root.activeDraggingDisplay !== "" ? root.frozenOriginY : root.originY

                        x: currentOriginX + currentVirtX * currentScale
                        y: currentOriginY + currentVirtY * currentScale
                        width: Math.max(logW * currentScale, 110)
                        height: Math.max(logH * currentScale, 72)
                        z: isDragging ? 30 : (isSelected ? 10 : 1)
                        scale: isDragging ? 1.04 : 1.0

                        Behavior on scale {
                            NumberAnimation { duration: 100 }
                        }

                        StyledRectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.small
                            color: monitorItem.isDisabled ? Appearance.m3colors.m3surfaceVariant : (monitorItem.isSelected ? Appearance.m3colors.m3surfaceContainerHighest : Appearance.m3colors.m3surfaceContainer)
                            border.width: monitorItem.isSelected || monitorItem.isDragging ? 2 : 1
                            border.color: monitorItem.isSelected || monitorItem.isDragging ? Appearance.m3colors.m3primary : Appearance.m3colors.m3outlineVariant
                            opacity: monitorItem.isDisabled ? 0.45 : 1.0

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    StyledRectangle {
                                        width: 20
                                        height: 20
                                        radius: 10
                                        color: monitorItem.isSelected ? Appearance.m3colors.m3primary : Appearance.m3colors.m3surfaceContainerHigh
                                        StyledText {
                                            anchors.centerIn: parent
                                            text: String(monitorItem.index + 1)
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: monitorItem.isSelected ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurface
                                        }
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: monitorItem.modelData.name
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.bold: monitorItem.isSelected
                                        elide: Text.ElideRight
                                        color: monitorItem.isSelected ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurface
                                    }

                                    MaterialSymbol {
                                        visible: monitorItem.modelData.focused
                                        text: "star"
                                        iconSize: 14
                                        color: Appearance.m3colors.m3primary
                                        StyledToolTip { text: Translation.tr("Primary focused display") }
                                    }
                                }

                                Item { Layout.fillHeight: true }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: monitorItem.modelData.model || monitorItem.modelData.description || monitorItem.modelData.name
                                    font.pixelSize: 10
                                    color: Appearance.m3colors.m3onSurfaceVariant
                                    elide: Text.ElideRight
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    StyledText {
                                        text: `${Math.round(monitorItem.modelData.width)}×${Math.round(monitorItem.modelData.height)}`
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: Appearance.m3colors.m3onSurface
                                    }
                                    StyledText {
                                        text: `@ ${Math.round(monitorItem.modelData.refreshRate)}Hz`
                                        font.pixelSize: 10
                                        color: Appearance.m3colors.m3onSurfaceVariant
                                    }
                                }
                            }
                        }

                        // Drag & Selection Mouse Area covering the entire card on top of everything
                        MouseArea {
                            id: dragArea
                            anchors.fill: parent
                            z: 50
                            preventStealing: true
                            cursorShape: (root.activeDraggingDisplay === monitorItem.modelData.name) ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                            onPressed: (mouse) => {
                                DisplayService.selectedDisplayName = monitorItem.modelData.name;
                                root.frozenOriginX = root.originX;
                                root.frozenOriginY = root.originY;
                                root.frozenScaleFactor = root.scaleFactor;
                                root.activeDraggingDisplay = monitorItem.modelData.name;
                                root.activeDisplayVirtX = monitorItem.modelData.x;
                                root.activeDisplayVirtY = monitorItem.modelData.y;

                                let pt = mapToItem(monitorItem.parent, mouse.x, mouse.y);
                                root.dragStartX = pt.x;
                                root.dragStartY = pt.y;
                                root.dragItemStartX = monitorItem.modelData.x;
                                root.dragItemStartY = monitorItem.modelData.y;
                            }

                            onPositionChanged: (mouse) => {
                                if (root.activeDraggingDisplay !== monitorItem.modelData.name) return;

                                let pt = mapToItem(monitorItem.parent, mouse.x, mouse.y);
                                let pixelDx = pt.x - root.dragStartX;
                                let pixelDy = pt.y - root.dragStartY;

                                let virtDx = pixelDx / root.frozenScaleFactor;
                                let virtDy = pixelDy / root.frozenScaleFactor;

                                let targetVirtX = Math.round(root.dragItemStartX + virtDx);
                                let targetVirtY = Math.round(root.dragItemStartY + virtDy);

                                let snapThresholdVirt = 45 / root.frozenScaleFactor;
                                let snappedX = targetVirtX;
                                let snappedY = targetVirtY;
                                let snapGuideXCanvas = -1;
                                let snapGuideYCanvas = -1;

                                let myEffW = (monitorItem.modelData.transform === 1 || monitorItem.modelData.transform === 3) ? monitorItem.modelData.height : monitorItem.modelData.width;
                                let myEffH = (monitorItem.modelData.transform === 1 || monitorItem.modelData.transform === 3) ? monitorItem.modelData.width : monitorItem.modelData.height;
                                let myLogW = myEffW / (monitorItem.modelData.scale || 1.0);
                                let myLogH = myEffH / (monitorItem.modelData.scale || 1.0);

                                let others = DisplayService.pendingDisplays.filter(d => d.name !== monitorItem.modelData.name && !d.disabled);
                                for (let i = 0; i < others.length; i++) {
                                    let o = others[i];
                                    let oEffW = (o.transform === 1 || o.transform === 3) ? o.height : o.width;
                                    let oEffH = (o.transform === 1 || o.transform === 3) ? o.width : o.height;
                                    let oLogW = oEffW / (o.scale || 1.0);
                                    let oLogH = oEffH / (o.scale || 1.0);

                                    // X snapping
                                    if (Math.abs(targetVirtX - (o.x + oLogW)) < snapThresholdVirt) {
                                        snappedX = o.x + oLogW;
                                        snapGuideXCanvas = root.frozenOriginX + snappedX * root.frozenScaleFactor;
                                    } else if (Math.abs((targetVirtX + myLogW) - o.x) < snapThresholdVirt) {
                                        snappedX = o.x - myLogW;
                                        snapGuideXCanvas = root.frozenOriginX + o.x * root.frozenScaleFactor;
                                    } else if (Math.abs(targetVirtX - o.x) < snapThresholdVirt) {
                                        snappedX = o.x;
                                        snapGuideXCanvas = root.frozenOriginX + o.x * root.frozenScaleFactor;
                                    } else if (Math.abs((targetVirtX + myLogW) - (o.x + oLogW)) < snapThresholdVirt) {
                                        snappedX = o.x + oLogW - myLogW;
                                        snapGuideXCanvas = root.frozenOriginX + (o.x + oLogW) * root.frozenScaleFactor;
                                    }

                                    // Y snapping
                                    if (Math.abs(targetVirtY - (o.y + oLogH)) < snapThresholdVirt) {
                                        snappedY = o.y + oLogH;
                                        snapGuideYCanvas = root.frozenOriginY + snappedY * root.frozenScaleFactor;
                                    } else if (Math.abs((targetVirtY + myLogH) - o.y) < snapThresholdVirt) {
                                        snappedY = o.y - myLogH;
                                        snapGuideYCanvas = root.frozenOriginY + o.y * root.frozenScaleFactor;
                                    } else if (Math.abs(targetVirtY - o.y) < snapThresholdVirt) {
                                        snappedY = o.y;
                                        snapGuideYCanvas = root.frozenOriginY + o.y * root.frozenScaleFactor;
                                    } else if (Math.abs((targetVirtY + myLogH) - (o.y + oLogH)) < snapThresholdVirt) {
                                        snappedY = o.y + oLogH - myLogH;
                                        snapGuideYCanvas = root.frozenOriginY + (o.y + oLogH) * root.frozenScaleFactor;
                                    } else if (Math.abs((targetVirtY + myLogH / 2) - (o.y + oLogH / 2)) < snapThresholdVirt) {
                                        snappedY = o.y + (oLogH - myLogH) / 2;
                                        snapGuideYCanvas = root.frozenOriginY + (o.y + oLogH / 2) * root.frozenScaleFactor;
                                    }
                                }

                                if (snapGuideXCanvas >= 0) {
                                    root.snapGuideX = snapGuideXCanvas;
                                    root.showSnapGuideX = true;
                                } else {
                                    root.showSnapGuideX = false;
                                }

                                if (snapGuideYCanvas >= 0) {
                                    root.snapGuideY = snapGuideYCanvas;
                                    root.showSnapGuideY = true;
                                } else {
                                    root.showSnapGuideY = false;
                                }

                                root.activeDisplayVirtX = snappedX;
                                root.activeDisplayVirtY = snappedY;
                            }

                            onReleased: {
                                root.showSnapGuideX = false;
                                root.showSnapGuideY = false;

                                if (root.activeDraggingDisplay === monitorItem.modelData.name) {
                                    let finalX = root.activeDisplayVirtX;
                                    let finalY = root.activeDisplayVirtY;
                                    DisplayService.setPosition(monitorItem.modelData.name, finalX, finalY);

                                    // Normalize positions so minX and minY are 0
                                    let list = DisplayService.pendingDisplays;
                                    if (list.length > 0) {
                                        let minX = list[0].x;
                                        let minY = list[0].y;
                                        for (let i = 1; i < list.length; i++) {
                                            if (list[i].x < minX) minX = list[i].x;
                                            if (list[i].y < minY) minY = list[i].y;
                                        }
                                        if (minX !== 0 || minY !== 0) {
                                            for (let i = 0; i < list.length; i++) {
                                                DisplayService.setPosition(list[i].name, list[i].x - minX, list[i].y - minY);
                                            }
                                        }
                                    }
                                }

                                root.activeDraggingDisplay = "";
                            }

                            onCanceled: {
                                root.showSnapGuideX = false;
                                root.showSnapGuideY = false;
                                root.activeDraggingDisplay = "";
                            }
                        }
                    }
                }
            }

            // ---------------- Display Selection Chips ----------------
            StyledRectangle {
                Layout.fillWidth: true
                implicitHeight: 48
                radius: Appearance.rounding.small
                color: Appearance.m3colors.m3surfaceContainerLow

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    StyledText {
                        text: Translation.tr("Selected Display:")
                        font.bold: true
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.m3colors.m3onSurfaceVariant
                    }

                    Repeater {
                        model: DisplayService.pendingDisplays

                        delegate: RippleButton {
                            id: chipBtn
                            required property var modelData
                            required property int index

                            readonly property bool isSelected: DisplayService.selectedDisplayName === modelData.name
                            implicitWidth: chipRow.implicitWidth + 24
                            implicitHeight: 32
                            padding: 10
                            buttonRadius: Appearance.rounding.full
                            colBackground: isSelected ? Appearance.m3colors.m3primary : Appearance.m3colors.m3surfaceContainerHigh
                            onClicked: DisplayService.selectedDisplayName = modelData.name

                            RowLayout {
                                id: chipRow
                                anchors.centerIn: parent
                                spacing: 6

                                StyledRectangle {
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: parent.parent.isSelected ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3surfaceContainerHighest
                                    StyledText {
                                        anchors.centerIn: parent
                                        text: String(index + 1)
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: parent.parent.parent.isSelected ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurface
                                    }
                                }

                                StyledText {
                                    text: `${modelData.name} ${modelData.model ? `(${modelData.model})` : ""}`
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.bold: isSelected
                                    color: isSelected ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurface
                                }

                                StyledText {
                                    visible: modelData.disabled
                                    text: Translation.tr("[Off]")
                                    font.pixelSize: 10
                                    color: isSelected ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3error
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 8
                        StyledText {
                            text: Translation.tr("Display Active")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.m3colors.m3onSurface
                        }
                        StyledSwitch {
                            checked: root.disp ? !root.disp.disabled : true
                            enabled: {
                                if (!root.disp) return false;
                                if (root.disp.disabled) return true;
                                let activeCount = DisplayService.pendingDisplays.filter(d => !d.disabled).length;
                                return activeCount > 1;
                            }
                            onCheckedChanged: {
                                if (root.disp && checked === root.disp.disabled) {
                                    DisplayService.updateDisplayProp(root.disp.name, "disabled", !checked);
                                }
                            }
                        }
                    }
                }
            }

            // ---------------- Bento Grid (4 Cards) ----------------
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 14
                rowSpacing: 14

                // CARD 1: Hardware Specifications
                StyledRectangle {
                    Layout.fillWidth: true
                    implicitHeight: card1Layout.implicitHeight + 28
                    radius: Appearance.rounding.normal
                    color: Appearance.m3colors.m3surfaceContainer
                    border.width: 1
                    border.color: Appearance.m3colors.m3outlineVariant

                    ColumnLayout {
                        id: card1Layout
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        RowLayout {
                            spacing: 8
                            MaterialSymbol { text: "info"; iconSize: 20; color: Appearance.m3colors.m3primary }
                            StyledText {
                                text: Translation.tr("Hardware Specifications")
                                font.bold: true
                                font.pixelSize: Appearance.font.pixelSize.normal + 1
                                color: Appearance.m3colors.m3onSurface
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Appearance.m3colors.m3outlineVariant }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: 6
                            columnSpacing: 12

                            StyledText { text: Translation.tr("Make & Model:"); color: Appearance.m3colors.m3onSurfaceVariant; font.pixelSize: Appearance.font.pixelSize.small }
                            StyledText { text: ((root.disp && root.disp.make) ? root.disp.make + " " : "") + ((root.disp && root.disp.model) ? root.disp.model : ((root.disp && root.disp.description) ? root.disp.description : Translation.tr("Generic Monitor"))); font.bold: true; font.pixelSize: Appearance.font.pixelSize.small; elide: Text.ElideRight }

                            StyledText { text: Translation.tr("Output Port:"); color: Appearance.m3colors.m3onSurfaceVariant; font.pixelSize: Appearance.font.pixelSize.small }
                            StyledText { text: (root.disp && root.disp.name) ? root.disp.name : ""; font.bold: true; font.pixelSize: Appearance.font.pixelSize.small }

                            StyledText { text: Translation.tr("Physical Size:"); color: Appearance.m3colors.m3onSurfaceVariant; font.pixelSize: Appearance.font.pixelSize.small }
                            StyledText {
                                text: root.diagonalInches > 0 ? `${Math.round(root.disp.physicalWidth)} × ${Math.round(root.disp.physicalHeight)} mm (~${root.diagonalInches.toFixed(1)}")` : Translation.tr("Unknown")
                                font.pixelSize: Appearance.font.pixelSize.small
                            }

                            StyledText { text: Translation.tr("Pixel Density:"); color: Appearance.m3colors.m3onSurfaceVariant; font.pixelSize: Appearance.font.pixelSize.small }
                            StyledText { text: root.ppi > 0 ? `${root.ppi.toFixed(1)} PPI` : Translation.tr("Standard"); font.pixelSize: Appearance.font.pixelSize.small }

                            StyledText { text: Translation.tr("Aspect Ratio:"); color: Appearance.m3colors.m3onSurfaceVariant; font.pixelSize: Appearance.font.pixelSize.small }
                            StyledText { text: root.aspectRatioStr; font.pixelSize: Appearance.font.pixelSize.small }

                            StyledText { text: Translation.tr("Pixel Format:"); color: Appearance.m3colors.m3onSurfaceVariant; font.pixelSize: Appearance.font.pixelSize.small }
                            StyledText { text: (root.disp && root.disp.currentFormat) ? root.disp.currentFormat : "XRGB8888"; font.pixelSize: Appearance.font.pixelSize.small }

                            StyledText { text: Translation.tr("Serial Number:"); color: Appearance.m3colors.m3onSurfaceVariant; font.pixelSize: Appearance.font.pixelSize.small }
                            StyledText { text: (root.disp && root.disp.serial) ? root.disp.serial : Translation.tr("Not specified"); font.pixelSize: Appearance.font.pixelSize.small }

                            StyledText { text: Translation.tr("Display Controller:"); color: Appearance.m3colors.m3onSurfaceVariant; font.pixelSize: Appearance.font.pixelSize.small }
                            StyledText {
                                text: {
                                    if (root.disp && DisplayService.gpuInfo.connectors && DisplayService.gpuInfo.connectors[root.disp.name]) {
                                        let c = DisplayService.gpuInfo.connectors[root.disp.name];
                                        return `${c.gpuName} (${c.card} / ${c.driver})`;
                                    }
                                    return DisplayService.gpuInfo.primaryRenderer || Translation.tr("KMS Display Controller");
                                }
                                font.bold: true
                                font.pixelSize: Appearance.font.pixelSize.small
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            StyledText { text: Translation.tr("3D Acceleration:"); color: Appearance.m3colors.m3onSurfaceVariant; font.pixelSize: Appearance.font.pixelSize.small }
                            StyledText {
                                text: {
                                    if (DisplayService.gpuInfo.hasDgpu && DisplayService.gpuInfo.dgpu) {
                                        let prefix = DisplayService.gpuInfo.offloadPrefix ? DisplayService.gpuInfo.offloadPrefix.trim() : "PRIME";
                                        return `${DisplayService.gpuInfo.dgpu.name} (${prefix} Offload)`;
                                    }
                                    return Translation.tr("Unified Hardware Acceleration");
                                }
                                font.bold: true
                                font.pixelSize: Appearance.font.pixelSize.small
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                // CARD 2: Graphics & GPU Architecture
                StyledRectangle {
                    Layout.fillWidth: true
                    implicitHeight: gpuCardLayout.implicitHeight + 28
                    radius: Appearance.rounding.normal
                    color: Appearance.m3colors.m3surfaceContainer
                    border.width: 1
                    border.color: Appearance.m3colors.m3outlineVariant

                    ColumnLayout {
                        id: gpuCardLayout
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        // Card Header
                        RowLayout {
                            spacing: 8
                            MaterialSymbol { text: "developer_board"; iconSize: 20; color: Appearance.m3colors.m3primary }
                            StyledText {
                                text: Translation.tr("Graphics & GPU Architecture")
                                font.bold: true
                                font.pixelSize: Appearance.font.pixelSize.normal + 1
                                color: Appearance.m3colors.m3onSurface
                            }
                            Item { Layout.fillWidth: true }
                            StyledRectangle {
                                radius: Appearance.rounding.full
                                color: DisplayService.gpuInfo.isHybrid ? Appearance.m3colors.m3primaryContainer : Appearance.m3colors.m3secondaryContainer
                                implicitWidth: hybridTagRow.implicitWidth + 16
                                implicitHeight: 24
                                RowLayout {
                                    id: hybridTagRow
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol {
                                        text: DisplayService.gpuInfo.isHybrid ? "sync_alt" : "verified"
                                        iconSize: 14
                                        color: DisplayService.gpuInfo.isHybrid ? Appearance.m3colors.m3onPrimaryContainer : Appearance.m3colors.m3onSecondaryContainer
                                    }
                                    StyledText {
                                        text: DisplayService.gpuInfo.isHybrid ? Translation.tr("PRIME Hybrid Active") : Translation.tr("Unified Graphics")
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        font.bold: true
                                        color: DisplayService.gpuInfo.isHybrid ? Appearance.m3colors.m3onPrimaryContainer : Appearance.m3colors.m3onSecondaryContainer
                                    }
                                }
                            }
                        }

                        // Sub-cards for iGPU and dGPU (or unified GPU)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            // 1. Primary Display Controller Box
                            StyledRectangle {
                                Layout.fillWidth: true
                                implicitHeight: igpuBoxCol.implicitHeight + 20
                                radius: Appearance.rounding.small
                                color: Appearance.m3colors.m3surfaceContainerHigh
                                border.width: 1
                                border.color: Appearance.m3colors.m3outlineVariant

                                ColumnLayout {
                                    id: igpuBoxCol
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 6

                                    RowLayout {
                                        spacing: 6
                                        MaterialSymbol { text: "desktop_windows"; iconSize: 18; color: Appearance.m3colors.m3primary }
                                        StyledText {
                                            text: (DisplayService.gpuInfo.gpus && DisplayService.gpuInfo.gpus[0]) ? DisplayService.gpuInfo.gpus[0].name : (DisplayService.gpuInfo.primaryRenderer || Translation.tr("Primary Graphics"))
                                            font.bold: true
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            color: Appearance.m3colors.m3onSurface
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        StyledRectangle {
                                            radius: Appearance.rounding.full
                                            color: Appearance.m3colors.m3surfaceVariant
                                            implicitWidth: igpuBadgeText.implicitWidth + 10
                                            implicitHeight: 18
                                            StyledText {
                                                id: igpuBadgeText
                                                anchors.centerIn: parent
                                                text: DisplayService.gpuInfo.isHybrid ? Translation.tr("Display Master") : Translation.tr("Unified KMS")
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: Appearance.m3colors.m3onSurfaceVariant
                                            }
                                        }
                                    }

                                    StyledText {
                                        text: DisplayService.gpuInfo.isHybrid ?
                                            Translation.tr("Controls scanout for connected displays (%1). Low-power desktop compositing.").arg(Object.keys(DisplayService.gpuInfo.connectors || {}).join(", ")) :
                                            Translation.tr("High-efficiency GPU architecture directly powering all connected monitors and desktop composition.")
                                        wrapMode: Text.Wrap
                                        Layout.fillWidth: true
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.m3colors.m3onSurfaceVariant
                                    }

                                    RowLayout {
                                        spacing: 12
                                        StyledText {
                                            text: `Driver: ${(DisplayService.gpuInfo.gpus && DisplayService.gpuInfo.gpus[0]) ? DisplayService.gpuInfo.gpus[0].driver : "KMS"}`
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.m3colors.m3outline
                                        }
                                        StyledText {
                                            text: `PCI: ${(DisplayService.gpuInfo.gpus && DisplayService.gpuInfo.gpus[0]) ? DisplayService.gpuInfo.gpus[0].pci : "0000:00:02.0"}`
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.m3colors.m3outline
                                        }
                                    }
                                }
                            }

                            // 2. Secondary / Dedicated dGPU Box (Visible if dGPU present)
                            StyledRectangle {
                                visible: DisplayService.gpuInfo.hasDgpu
                                Layout.fillWidth: true
                                implicitHeight: dgpuBoxCol.implicitHeight + 20
                                radius: Appearance.rounding.small
                                color: Appearance.m3colors.m3surfaceContainerHigh
                                border.width: 1
                                border.color: Appearance.m3colors.m3outlineVariant

                                ColumnLayout {
                                    id: dgpuBoxCol
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 6

                                    RowLayout {
                                        spacing: 6
                                        MaterialSymbol { text: "rocket_launch"; iconSize: 18; color: Appearance.m3colors.m3secondary }
                                        StyledText {
                                            text: DisplayService.gpuInfo.dgpu ? DisplayService.gpuInfo.dgpu.name : Translation.tr("Dedicated GPU")
                                            font.bold: true
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            color: Appearance.m3colors.m3onSurface
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        StyledRectangle {
                                            radius: Appearance.rounding.full
                                            color: Appearance.m3colors.m3secondaryContainer
                                            implicitWidth: dgpuBadgeText.implicitWidth + 10
                                            implicitHeight: 18
                                            StyledText {
                                                id: dgpuBadgeText
                                                anchors.centerIn: parent
                                                text: Translation.tr("3D Offload")
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: Appearance.m3colors.m3onSecondaryContainer
                                            }
                                        }
                                    }

                                    StyledText {
                                        text: {
                                            if (!DisplayService.gpuInfo.dgpu) return "";
                                            let vram = (DisplayService.gpuInfo.dgpu.vramUsed && DisplayService.gpuInfo.dgpu.vramTotal) ?
                                                `${DisplayService.gpuInfo.dgpu.vramUsed} / ${DisplayService.gpuInfo.dgpu.vramTotal}` : Translation.tr("Dedicated VRAM");
                                            let util = DisplayService.gpuInfo.dgpu.utilization ? ` (${DisplayService.gpuInfo.dgpu.utilization} util)` : "";
                                            return Translation.tr("Dedicated accelerator for 3D gaming, CAD, and AI. VRAM: %1%2").arg(vram).arg(util);
                                        }
                                        wrapMode: Text.Wrap
                                        Layout.fillWidth: true
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.m3colors.m3onSurfaceVariant
                                    }

                                    RowLayout {
                                        spacing: 12
                                        StyledText {
                                            visible: !!DisplayService.gpuInfo.dgpu?.temp
                                            text: `Temp: ${DisplayService.gpuInfo.dgpu?.temp || ""}`
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.m3colors.m3outline
                                        }
                                        StyledText {
                                            visible: !!DisplayService.gpuInfo.dgpu?.power
                                            text: `Power: ${DisplayService.gpuInfo.dgpu?.power || ""}`
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.m3colors.m3outline
                                        }
                                        StyledText {
                                            text: `Driver: ${DisplayService.gpuInfo.dgpu?.driverVersion || DisplayService.gpuInfo.dgpu?.driver || "active"}`
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.m3colors.m3outline
                                        }
                                    }
                                }
                            }
                        }

                        // Explanatory Banner: Multi-GPU Offloading vs Unified
                        StyledRectangle {
                            Layout.fillWidth: true
                            implicitHeight: bannerCol.implicitHeight + 16
                            radius: Appearance.rounding.small
                            color: Appearance.m3colors.m3surfaceVariant
                            border.width: 1
                            border.color: Appearance.m3colors.m3outlineVariant

                            ColumnLayout {
                                id: bannerCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 6

                                RowLayout {
                                    spacing: 6
                                    MaterialSymbol { text: "info"; iconSize: 16; color: Appearance.m3colors.m3primary }
                                    StyledText {
                                        text: DisplayService.gpuInfo.isHybrid ?
                                            Translation.tr("Multi-GPU Architecture & Dynamic Application Offloading") :
                                            Translation.tr("Direct Kernel Mode Setting (KMS) & Display Hotplug")
                                        font.bold: true
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.m3colors.m3onSurface
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: DisplayService.gpuInfo.isHybrid ?
                                        Translation.tr("Motherboard video ports are physically wired to the primary display controller. To run any 3D game, emulator, or heavy rendering app on the dedicated GPU with full acceleration, launch it with:") :
                                        Translation.tr("All connected monitors run directly on hardware scanout with full Wayland hardware acceleration. Simply connect any HDMI, DisplayPort, or USB-C monitor and arrange it dynamically above.")
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    wrapMode: Text.Wrap
                                    color: Appearance.m3colors.m3onSurfaceVariant
                                }

                                RowLayout {
                                    visible: DisplayService.gpuInfo.isHybrid
                                    spacing: 8
                                    StyledRectangle {
                                        radius: 6
                                        color: Appearance.m3colors.m3surfaceContainerHighest
                                        implicitWidth: codeText.implicitWidth + 16
                                        implicitHeight: 26
                                        StyledText {
                                            id: codeText
                                            anchors.centerIn: parent
                                            text: DisplayService.gpuInfo.offloadCommand || "prime-run <command>"
                                            font.bold: true
                                            font.family: "monospace"
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.m3colors.m3primary
                                        }
                                    }

                                    RippleButton {
                                        implicitWidth: copyRow.implicitWidth + 14
                                        implicitHeight: 26
                                        buttonRadius: Appearance.rounding.full
                                        colBackground: Appearance.m3colors.m3secondaryContainer
                                        onClicked: {
                                            Quickshell.clipboardText = DisplayService.gpuInfo.offloadPrefix || "prime-run ";
                                        }
                                        RowLayout {
                                            id: copyRow
                                            anchors.centerIn: parent
                                            spacing: 4
                                            MaterialSymbol { text: "content_copy"; iconSize: 14; color: Appearance.m3colors.m3onSecondaryContainer }
                                            StyledText {
                                                text: Translation.tr("Copy Prefix")
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                color: Appearance.m3colors.m3onSecondaryContainer
                                            }
                                        }
                                        StyledToolTip { text: Translation.tr("Copy command prefix to clipboard") }
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: Translation.tr("e.g. %1blender, %1steam").arg(DisplayService.gpuInfo.offloadPrefix || "prime-run ")
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.m3colors.m3outline
                                    }
                                }
                            }
                        }
                    }
                }

                // CARD 3: Resolution & Refresh Rate
                StyledRectangle {
                    Layout.fillWidth: true
                    implicitHeight: card2Layout.implicitHeight + 28
                    radius: Appearance.rounding.normal
                    color: Appearance.m3colors.m3surfaceContainer
                    border.width: 1
                    border.color: Appearance.m3colors.m3outlineVariant

                    ColumnLayout {
                        id: card2Layout
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        RowLayout {
                            spacing: 8
                            MaterialSymbol { text: "speed"; iconSize: 20; color: Appearance.m3colors.m3primary }
                            StyledText {
                                text: Translation.tr("Resolution & Refresh Rate")
                                font.bold: true
                                font.pixelSize: Appearance.font.pixelSize.normal + 1
                                color: Appearance.m3colors.m3onSurface
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Appearance.m3colors.m3outlineVariant }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            StyledText { text: Translation.tr("Display Resolution"); font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.m3colors.m3onSurfaceVariant }
                            StyledComboBox {
                                Layout.fillWidth: true
                                model: root.parsedModes.resolutions
                                currentIndex: Math.max(0, root.parsedModes.resolutions.indexOf(root.currentResStr))
                                onActivated: (index) => {
                                    let chosenRes = root.parsedModes.resolutions[index];
                                    let [w, h] = chosenRes.split("x").map(Number);
                                    let rates = root.parsedModes.rateMap[chosenRes] || [60];
                                    let chosenHz = rates[0];
                                    DisplayService.updateDisplayProp(root.disp.name, "width", w);
                                    DisplayService.updateDisplayProp(root.disp.name, "height", h);
                                    DisplayService.updateDisplayProp(root.disp.name, "refreshRate", chosenHz);
                                    DisplayService.updateDisplayProp(root.disp.name, "mode", `${chosenRes}@${chosenHz.toFixed(2)}`);
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            StyledText { text: Translation.tr("Refresh Rate (Hz)"); font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.m3colors.m3onSurfaceVariant }

                            Flow {
                                Layout.fillWidth: true
                                spacing: 8

                                Repeater {
                                    model: root.currentRates

                                    delegate: RippleButton {
                                        required property real modelData
                                        readonly property bool isCurrent: root.disp && Math.abs(root.disp.refreshRate - modelData) < 0.1
                                        implicitWidth: rateLabel.implicitWidth + 24
                                        implicitHeight: 28
                                        padding: 10
                                        buttonRadius: Appearance.rounding.full
                                        colBackground: isCurrent ? Appearance.m3colors.m3primary : Appearance.m3colors.m3surfaceContainerHigh
                                        onClicked: {
                                            DisplayService.updateDisplayProp(root.disp.name, "refreshRate", modelData);
                                            DisplayService.updateDisplayProp(root.disp.name, "mode", `${root.disp.width}x${root.disp.height}@${modelData.toFixed(2)}`);
                                        }

                                        StyledText {
                                            id: rateLabel
                                            anchors.centerIn: parent
                                            text: `${Math.round(modelData)} Hz`
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            font.bold: parent.isCurrent
                                            color: parent.isCurrent ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurface
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // CARD 3: Scaling & Orientation
                StyledRectangle {
                    Layout.fillWidth: true
                    implicitHeight: card3Layout.implicitHeight + 28
                    radius: Appearance.rounding.normal
                    color: Appearance.m3colors.m3surfaceContainer
                    border.width: 1
                    border.color: Appearance.m3colors.m3outlineVariant

                    ColumnLayout {
                        id: card3Layout
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        RowLayout {
                            spacing: 8
                            MaterialSymbol { text: "aspect_ratio"; iconSize: 20; color: Appearance.m3colors.m3primary }
                            StyledText {
                                text: Translation.tr("Scaling & Orientation")
                                font.bold: true
                                font.pixelSize: Appearance.font.pixelSize.normal + 1
                                color: Appearance.m3colors.m3onSurface
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Appearance.m3colors.m3outlineVariant }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                StyledText { text: Translation.tr("Interface Scale"); font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.m3colors.m3onSurfaceVariant }
                                Item { Layout.fillWidth: true }
                                StyledText {
                                    text: `${Math.round(((root.disp && root.disp.scale) ? root.disp.scale : 1.0) * 100)}%`
                                    font.bold: true
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.m3colors.m3primary
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Repeater {
                                    model: [1.0, 1.25, 1.5, 1.75, 2.0]

                                    delegate: RippleButton {
                                        required property real modelData
                                        readonly property bool isSelected: root.disp && Math.abs(root.disp.scale - modelData) < 0.05
                                        Layout.fillWidth: true
                                        implicitHeight: 28
                                        buttonRadius: Appearance.rounding.small
                                        colBackground: isSelected ? Appearance.m3colors.m3primary : Appearance.m3colors.m3surfaceContainerHigh
                                        onClicked: DisplayService.updateDisplayProp(root.disp.name, "scale", modelData)

                                        StyledText {
                                            anchors.centerIn: parent
                                            text: `${Math.round(modelData * 100)}%`
                                            font.pixelSize: 11
                                            font.bold: parent.isSelected
                                            color: parent.isSelected ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurface
                                        }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            StyledText { text: Translation.tr("Orientation / Rotation"); font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.m3colors.m3onSurfaceVariant }

                            StyledComboBox {
                                Layout.fillWidth: true
                                model: [
                                    Translation.tr("Standard Landscape (0°)"),
                                    Translation.tr("Portrait Left (90°)"),
                                    Translation.tr("Inverted Landscape (180°)"),
                                    Translation.tr("Portrait Right (270°)")
                                ]
                                currentIndex: root.disp ? Math.min(root.disp.transform, 3) : 0
                                onActivated: (index) => {
                                    DisplayService.updateDisplayProp(root.disp.name, "transform", index);
                                }
                            }
                        }
                    }
                }

                // CARD 4: Position Coordinates & Advanced Sync
                StyledRectangle {
                    Layout.fillWidth: true
                    implicitHeight: card4Layout.implicitHeight + 28
                    radius: Appearance.rounding.normal
                    color: Appearance.m3colors.m3surfaceContainer
                    border.width: 1
                    border.color: Appearance.m3colors.m3outlineVariant

                    ColumnLayout {
                        id: card4Layout
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        RowLayout {
                            spacing: 8
                            MaterialSymbol { text: "tune"; iconSize: 20; color: Appearance.m3colors.m3primary }
                            StyledText {
                                text: Translation.tr("Position & Advanced Sync")
                                font.bold: true
                                font.pixelSize: Appearance.font.pixelSize.normal + 1
                                color: Appearance.m3colors.m3onSurface
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Appearance.m3colors.m3outlineVariant }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                StyledText { text: Translation.tr("Position X (px)"); font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.m3colors.m3onSurfaceVariant }
                                StyledSpinBox {
                                    Layout.fillWidth: true
                                    from: 0
                                    to: 15000
                                    stepSize: 50
                                    value: root.disp ? Math.round(root.disp.x) : 0
                                    onValueModified: {
                                        DisplayService.setPosition(root.disp.name, value, root.disp.y);
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                StyledText { text: Translation.tr("Position Y (px)"); font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.m3colors.m3onSurfaceVariant }
                                StyledSpinBox {
                                    Layout.fillWidth: true
                                    from: 0
                                    to: 15000
                                    stepSize: 50
                                    value: root.disp ? Math.round(root.disp.y) : 0
                                    onValueModified: {
                                        DisplayService.setPosition(root.disp.name, root.disp.x, value);
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                StyledText { text: Translation.tr("VRR / Adaptive Sync"); font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.m3colors.m3onSurfaceVariant }
                                StyledComboBox {
                                    Layout.fillWidth: true
                                    model: [
                                        Translation.tr("Off"),
                                        Translation.tr("On (Always)"),
                                        Translation.tr("Fullscreen Only")
                                    ]
                                    currentIndex: root.disp ? root.disp.vrr : 0
                                    onActivated: (index) => {
                                        DisplayService.updateDisplayProp(root.disp.name, "vrr", index);
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                StyledText { text: Translation.tr("Mirror Display"); font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.m3colors.m3onSurfaceVariant }
                                StyledComboBox {
                                    Layout.fillWidth: true
                                    readonly property var mirrorOptions: {
                                        let opts = [Translation.tr("None (Extended)")];
                                        let currentName = root.disp ? root.disp.name : "";
                                        let others = DisplayService.pendingDisplays.filter(d => d.name !== currentName);
                                        for (let i = 0; i < others.length; i++) {
                                            opts.push(`Mirror ${others[i].name}`);
                                        }
                                        return opts;
                                    }
                                    model: mirrorOptions
                                    currentIndex: {
                                        if (!root.disp || !root.disp.mirror) return 0;
                                        let idx = mirrorOptions.indexOf(`Mirror ${root.disp.mirror}`);
                                        return idx >= 0 ? idx : 0;
                                    }
                                    onActivated: (index) => {
                                        if (!root.disp) return;
                                        if (index === 0) {
                                            DisplayService.updateDisplayProp(root.disp.name, "mirror", "");
                                        } else {
                                            let currentName = root.disp.name;
                                            let others = DisplayService.pendingDisplays.filter(d => d.name !== currentName);
                                            let target = others[index - 1];
                                            DisplayService.updateDisplayProp(root.disp.name, "mirror", target ? target.name : "");
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---------------- Action Bar ----------------
            StyledRectangle {
                Layout.fillWidth: true
                implicitHeight: 64
                radius: Appearance.rounding.normal
                color: Appearance.m3colors.m3surfaceContainerLow
                border.width: 1
                border.color: Appearance.m3colors.m3outlineVariant

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    RippleButton {
                        implicitWidth: resetRow.implicitWidth + 24
                        implicitHeight: 40
                        padding: 14
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.m3colors.m3surfaceContainerHigh
                        onClicked: DisplayService.resetDefaults()

                        RowLayout {
                            id: resetRow
                            anchors.centerIn: parent
                            spacing: 6
                            MaterialSymbol { text: "restart_alt"; iconSize: 18; color: Appearance.m3colors.m3onSurface }
                            StyledText {
                                text: Translation.tr("Reset Defaults")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.m3colors.m3onSurface
                            }
                        }
                        StyledToolTip { text: Translation.tr("Reset all displays to auto positions and scale 1.0") }
                    }

                    Item { Layout.fillWidth: true }

                    RippleButton {
                        visible: DisplayService.dirty
                        implicitWidth: discardRow.implicitWidth + 24
                        implicitHeight: 40
                        padding: 14
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.m3colors.m3surfaceContainerHighest
                        onClicked: DisplayService.revert()

                        RowLayout {
                            id: discardRow
                            anchors.centerIn: parent
                            spacing: 6
                            MaterialSymbol { text: "undo"; iconSize: 18; color: Appearance.m3colors.m3onSurface }
                            StyledText {
                                text: Translation.tr("Discard Changes")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.m3colors.m3onSurface
                            }
                        }
                    }

                    RippleButton {
                        implicitWidth: applyRow.implicitWidth + 28
                        implicitHeight: 40
                        padding: 16
                        buttonRadius: Appearance.rounding.full
                        colBackground: DisplayService.dirty ? Appearance.m3colors.m3primary : Appearance.m3colors.m3surfaceContainerHigh
                        enabled: DisplayService.dirty
                        opacity: DisplayService.dirty ? 1.0 : 0.6
                        onClicked: DisplayService.applyLive(true)

                        RowLayout {
                            id: applyRow
                            anchors.centerIn: parent
                            spacing: 6
                            MaterialSymbol {
                                text: "play_arrow"
                                iconSize: 18
                                color: DisplayService.dirty ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurfaceVariant
                            }
                            StyledText {
                                text: Translation.tr("Apply & Test")
                                font.bold: true
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: DisplayService.dirty ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurfaceVariant
                            }
                        }
                        StyledToolTip { text: Translation.tr("Test settings live with a 15-second safety auto-revert timer") }
                    }

                    RippleButton {
                        implicitWidth: saveRow.implicitWidth + 28
                        implicitHeight: 40
                        padding: 16
                        buttonRadius: Appearance.rounding.full
                        colBackground: root.showSavedFeedback ? Appearance.m3colors.m3primaryContainer : Appearance.m3colors.m3secondaryContainer
                        onClicked: {
                            DisplayService.confirmChanges();
                            root.showSavedFeedback = true;
                            savedFeedbackTimer.restart();
                        }

                        RowLayout {
                            id: saveRow
                            anchors.centerIn: parent
                            spacing: 6
                            MaterialSymbol {
                                text: root.showSavedFeedback ? "check_circle" : "save"
                                iconSize: 18
                                color: root.showSavedFeedback ? Appearance.m3colors.m3onPrimaryContainer : Appearance.m3colors.m3onSecondaryContainer
                            }
                            StyledText {
                                text: root.showSavedFeedback ? Translation.tr("Saved as Default!") : Translation.tr("Save as Default")
                                font.bold: true
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: root.showSavedFeedback ? Appearance.m3colors.m3onPrimaryContainer : Appearance.m3colors.m3onSecondaryContainer
                            }
                        }
                        StyledToolTip { text: Translation.tr("Apply and save current monitor setup permanently to ~/.config/hypr/monitors.lua") }
                    }
                }
            }

            Item { Layout.fillWidth: true; implicitHeight: 20 }
    }

    // ================= Safety Countdown Modal Dialog =================
    Item {
        id: safetyModal
        anchors.fill: parent
        visible: DisplayService.safetyDialogVisible
        z: 999

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.6)
            opacity: safetyModal.visible ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }
        }

        StyledRectangle {
            anchors.centerIn: parent
            width: 440
            implicitHeight: dialogContent.implicitHeight + 40
            radius: Appearance.rounding.normal
            color: Appearance.m3colors.m3surfaceContainerHigh
            border.width: 1
            border.color: Appearance.m3colors.m3outlineVariant

            ColumnLayout {
                id: dialogContent
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    StyledRectangle {
                        width: 44
                        height: 44
                        radius: 22
                        color: Appearance.m3colors.m3secondaryContainer

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "timer"
                            iconSize: 24
                            color: Appearance.m3colors.m3onSecondaryContainer
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            text: Translation.tr("Keep Display Settings?")
                            font.bold: true
                            font.pixelSize: Appearance.font.pixelSize.large
                            color: Appearance.m3colors.m3onSurface
                        }

                        StyledText {
                            text: Translation.tr("Reverting automatically in %1s").arg(DisplayService.safetyCountdown)
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.m3colors.m3primary
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.m3colors.m3onSurfaceVariant
                    text: Translation.tr("New display configuration has been applied. If your screen goes blank or looks distorted, no action is needed — settings will automatically revert.")
                }

                StyledProgressBar {
                    Layout.fillWidth: true
                    from: 0
                    to: 15
                    value: DisplayService.safetyCountdown
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 40
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.m3colors.m3surfaceContainerHighest
                        onClicked: DisplayService.revert()

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            MaterialSymbol { text: "undo"; iconSize: 18; color: Appearance.m3colors.m3onSurface }
                            StyledText {
                                text: Translation.tr("Revert Now")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.m3colors.m3onSurface
                            }
                        }
                    }

                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 40
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.m3colors.m3primary
                        onClicked: DisplayService.confirmChanges()

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            MaterialSymbol { text: "check"; iconSize: 18; color: Appearance.m3colors.m3onPrimary }
                            StyledText {
                                text: Translation.tr("Keep Changes")
                                font.bold: true
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.m3colors.m3onPrimary
                            }
                        }
                    }
                }
            }
        }
    }

    // ================= Multi-Monitor Screen Identification Overlay =================
    Scope {
        Variants {
            model: Quickshell.screens
            delegate: PanelWindow {
                id: identifyOverlay
                required property var modelData
                screen: modelData
                visible: DisplayService.identifyVisible

                readonly property int dispNumber: {
                    for (let i = 0; i < DisplayService.pendingDisplays.length; i++) {
                        if (DisplayService.pendingDisplays[i].name === modelData.name) {
                            return i + 1;
                        }
                    }
                    return 1;
                }
                readonly property var dispInfo: {
                    for (let i = 0; i < DisplayService.pendingDisplays.length; i++) {
                        if (DisplayService.pendingDisplays[i].name === modelData.name) {
                            return DisplayService.pendingDisplays[i];
                        }
                    }
                    return null;
                }

                color: "transparent"
                WlrLayershell.namespace: "quickshell:displayIdentify"
                WlrLayershell.layer: WlrLayer.Overlay
                exclusionMode: ExclusionMode.Ignore
                anchors {
                    left: true
                    right: true
                    top: true
                    bottom: true
                }

                mask: Region {
                    item: cardContainer
                }

                Item {
                    id: overlayWrapper
                    anchors.fill: parent
                    opacity: DisplayService.identifyAnimActive ? 1.0 : 0.0
                    scale: DisplayService.identifyAnimActive ? 1.0 : 0.88
                    Behavior on opacity {
                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 250; easing.type: Easing.OutBack }
                    }

                    StyledRectangle {
                        id: cardContainer
                        anchors.centerIn: parent
                        implicitWidth: Math.max(380, mainCardLayout.implicitWidth + 48)
                        implicitHeight: mainCardLayout.implicitHeight + 40
                        radius: Appearance.rounding.large
                        color: Appearance.m3colors.m3surface
                        border.width: 2
                        border.color: Appearance.m3colors.m3primary

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: DisplayService.dismissIdentify()
                        }

                        ColumnLayout {
                            id: mainCardLayout
                            anchors.centerIn: parent
                            spacing: 14

                            // Top badge & connector
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 16

                                // Big Display Number Pill/Circle
                                StyledRectangle {
                                    width: 72
                                    height: 72
                                    radius: 36
                                    color: Appearance.m3colors.m3primary

                                    StyledText {
                                        anchors.centerIn: parent
                                        text: String(identifyOverlay.dispNumber)
                                        font.pixelSize: 42
                                        font.bold: true
                                        color: Appearance.m3colors.m3onPrimary
                                    }
                                }

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter

                                    StyledText {
                                        text: identifyOverlay.dispInfo ? identifyOverlay.dispInfo.name : identifyOverlay.modelData.name
                                        font.pixelSize: 24
                                        font.bold: true
                                        color: Appearance.m3colors.m3onSurface
                                    }

                                    StyledText {
                                        text: {
                                            if (identifyOverlay.dispInfo && identifyOverlay.dispInfo.model) {
                                                return identifyOverlay.dispInfo.model;
                                            }
                                            return identifyOverlay.modelData.model || Translation.tr("Physical Display");
                                        }
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        color: Appearance.m3colors.m3onSurfaceVariant
                                    }
                                }
                            }

                            // Spec Chips (Resolution, Refresh Rate, Scale, Coordinates)
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 8

                                // Resolution & Rate
                                StyledRectangle {
                                    radius: Appearance.rounding.small
                                    color: Appearance.m3colors.m3surfaceContainerHigh
                                    border.width: 1
                                    border.color: Appearance.m3colors.m3outlineVariant
                                    implicitWidth: resLayout.implicitWidth + 16
                                    implicitHeight: 32

                                    RowLayout {
                                        id: resLayout
                                        anchors.centerIn: parent
                                        spacing: 6
                                        MaterialSymbol {
                                            text: "aspect_ratio"
                                            iconSize: 16
                                            color: Appearance.m3colors.m3primary
                                        }
                                        StyledText {
                                            text: {
                                                if (identifyOverlay.dispInfo) {
                                                    return `${identifyOverlay.dispInfo.width}×${identifyOverlay.dispInfo.height} @ ${Math.round(identifyOverlay.dispInfo.refreshRate)}Hz`;
                                                }
                                                return `${identifyOverlay.modelData.width}×${identifyOverlay.modelData.height}`;
                                            }
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            font.bold: true
                                            color: Appearance.m3colors.m3onSurface
                                        }
                                    }
                                }

                                // Scale Chip
                                StyledRectangle {
                                    radius: Appearance.rounding.small
                                    color: Appearance.m3colors.m3surfaceContainerHigh
                                    border.width: 1
                                    border.color: Appearance.m3colors.m3outlineVariant
                                    implicitWidth: scaleLayout.implicitWidth + 16
                                    implicitHeight: 32

                                    RowLayout {
                                        id: scaleLayout
                                        anchors.centerIn: parent
                                        spacing: 6
                                        MaterialSymbol {
                                            text: "density_medium"
                                            iconSize: 16
                                            color: Appearance.m3colors.m3secondary
                                        }
                                        StyledText {
                                            text: `${Math.round((identifyOverlay.dispInfo?.scale || 1.0) * 100)}%`
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            font.bold: true
                                            color: Appearance.m3colors.m3onSurface
                                        }
                                    }
                                }

                                // Position Chip
                                StyledRectangle {
                                    radius: Appearance.rounding.small
                                    color: Appearance.m3colors.m3surfaceContainerHigh
                                    border.width: 1
                                    border.color: Appearance.m3colors.m3outlineVariant
                                    implicitWidth: posLayout.implicitWidth + 16
                                    implicitHeight: 32

                                    RowLayout {
                                        id: posLayout
                                        anchors.centerIn: parent
                                        spacing: 6
                                        MaterialSymbol {
                                            text: "pin_drop"
                                            iconSize: 16
                                            color: Appearance.m3colors.m3tertiary
                                        }
                                        StyledText {
                                            text: identifyOverlay.dispInfo ? `(${identifyOverlay.dispInfo.x}, ${identifyOverlay.dispInfo.y})` : "(0, 0)"
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            font.bold: true
                                            color: Appearance.m3colors.m3onSurface
                                        }
                                    }
                                }
                            }

                            // Dismiss hint
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: Translation.tr("Click to dismiss")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.m3colors.m3outline
                            }
                        }
                    }
                }
            }
        }
    }
}
