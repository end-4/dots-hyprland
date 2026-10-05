import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: root
    forceWidth: true

    property int secondaryWorkspace: 10
    property string selectedSecondaryMonitor: secondaryMonitor()?.name ?? ""
    property string identifyingMonitorName: ""
    property bool identifyOverlayVisible: false
    property bool applyLayoutHintVisible: false
    property string pendingLayoutCommand: ""
    property var layoutPositions: ({})

    function monitors() {
        return HyprlandData.monitors.slice().sort((a, b) => a.x === b.x ? a.y - b.y : a.x - b.x);
    }

    function primaryMonitor() {
        const list = root.monitors();
        return list.find(monitor => monitor.focused) ?? list[0] ?? null;
    }

    function secondaryMonitor() {
        const primary = root.primaryMonitor();
        const list = root.monitors().filter(monitor => monitor.name !== primary?.name);
        return list[0] ?? primary ?? null;
    }

    function monitorWidth(monitor) {
        return (monitor.transform % 2 === 1) ? monitor.height : monitor.width;
    }

    function monitorHeight(monitor) {
        return (monitor.transform % 2 === 1) ? monitor.width : monitor.height;
    }

    function pendingX(monitor) {
        return layoutPositions[monitor.name]?.x ?? monitor.x;
    }

    function pendingY(monitor) {
        return layoutPositions[monitor.name]?.y ?? monitor.y;
    }

    function layoutBounds() {
        const list = root.monitors();
        if (list.length === 0)
            return { minX: 0, minY: 0, maxX: 1, maxY: 1, width: 1, height: 1 };

        let minX = Math.min(...list.map(monitor => root.pendingX(monitor)));
        let minY = Math.min(...list.map(monitor => root.pendingY(monitor)));
        let maxX = Math.max(...list.map(monitor => root.pendingX(monitor) + root.monitorWidth(monitor)));
        let maxY = Math.max(...list.map(monitor => root.pendingY(monitor) + root.monitorHeight(monitor)));
        return { minX, minY, maxX, maxY, width: Math.max(maxX - minX, 1), height: Math.max(maxY - minY, 1) };
    }

    function canvasScale() {
        const bounds = root.layoutBounds();
        return Math.min((layoutCanvas.width - 48) / bounds.width, (layoutCanvas.height - 48) / bounds.height);
    }

    function setMonitorPosition(monitor, x, y) {
        const positions = Object.assign({}, layoutPositions);
        positions[monitor.name] = {
            x: Math.round(x),
            y: Math.round(y)
        };
        layoutPositions = positions;
    }

    function snapHorizontalLayout() {
        const ordered = root.monitors().slice().sort((a, b) => {
            const centerA = root.pendingX(a) + root.monitorWidth(a) / 2;
            const centerB = root.pendingX(b) + root.monitorWidth(b) / 2;
            return centerA === centerB ? root.pendingY(a) - root.pendingY(b) : centerA - centerB;
        });
        const positions = {};
        let x = 0;
        for (const monitor of ordered) {
            positions[monitor.name] = {
                x,
                y: Math.round(root.pendingY(monitor))
            };
            x += root.monitorWidth(monitor);
        }
        layoutPositions = positions;
    }

    function updateDraggedMonitor(monitor, visualX, visualY) {
        const bounds = root.layoutBounds();
        const scale = root.canvasScale();
        root.setMonitorPosition(monitor, bounds.minX + (visualX - 24) / scale, bounds.minY + (visualY - 24) / scale);
        root.snapHorizontalLayout();
    }

    function setMonitorAxis(monitor, axis, valueText) {
        const value = parseInt(valueText);
        if (isNaN(value))
            return;

        if (axis === "x")
            root.setMonitorPosition(monitor, value, root.pendingY(monitor));
        else
            root.setMonitorPosition(monitor, root.pendingX(monitor), value);
        root.snapHorizontalLayout();
        root.triggerApplyLayoutHint();
    }

    function triggerApplyLayoutHint() {
        applyLayoutHintVisible = true;
        applyLayoutHintTimer.restart();
    }

    function resetLayout() {
        layoutPositions = ({});
    }

    function applyLayout() {
        const commands = [];
        for (const monitor of root.monitors()) {
            const position = `${root.pendingX(monitor)}x${root.pendingY(monitor)}`;
            commands.push(`hl.monitor({output="${monitor.name}", mode="preferred", position="${position}", scale=${monitor.scale}})`);
        }
        pendingLayoutCommand = commands.join("; ");
        Quickshell.execDetached(["hyprctl", "eval", pendingLayoutCommand]);
        layoutStabilizeTimer.restart();
        refreshTimer.restart();
    }

    function identifyMonitor(monitor) {
        if (!monitor)
            return;
        identifyingMonitorName = monitor.name;
        identifyOverlayVisible = true;
        identifyTimer.restart();
    }

    function identifyAllMonitors() {
        identifyingMonitorName = "__all__";
        identifyOverlayVisible = true;
        identifyTimer.restart();
    }

    function applySecondaryWorkspace() {
        const monitor = selectedSecondaryMonitor || root.secondaryMonitor()?.name || "";
        if (!monitor)
            return;
        Quickshell.execDetached(["bash", "-c", `hyprctl dispatch focusmonitor '${monitor}'; hyprctl dispatch workspace ${secondaryWorkspace}; hyprctl dispatch moveworkspacetomonitor ${secondaryWorkspace} '${monitor}'`]);
        refreshTimer.restart();
    }

    Component.onCompleted: {
        HyprlandData.updateMonitors();
        HyprlandData.updateWorkspaces();
    }

    Connections {
        target: HyprlandData

        function onMonitorsChanged() {
            if (!root.selectedSecondaryMonitor && root.secondaryMonitor())
                root.selectedSecondaryMonitor = root.secondaryMonitor().name;
        }
    }

    Timer {
        id: refreshTimer
        interval: 700
        repeat: false
        onTriggered: HyprlandData.updateAll()
    }

    Timer {
        id: layoutStabilizeTimer
        interval: 650
        repeat: false
        onTriggered: {
            if (!root.pendingLayoutCommand)
                return;
            Quickshell.execDetached(["hyprctl", "eval", root.pendingLayoutCommand]);
            HyprlandData.updateAll();
        }
    }

    Timer {
        id: applyLayoutHintTimer
        interval: 2000
        repeat: false
        onTriggered: root.applyLayoutHintVisible = false
    }

    Timer {
        id: identifyTimer
        interval: 1800
        repeat: false
        onTriggered: {
            root.identifyOverlayVisible = false;
            root.identifyingMonitorName = "";
        }
    }

    component MonitorItem: Rectangle {
        id: itemRoot
        required property var monitorData
        property bool expanded: false
        readonly property bool active: monitorData.focused

        Layout.fillWidth: true
        implicitHeight: monitorItemContent.implicitHeight + 16
        radius: Appearance.rounding.normal
        color: itemRoot.expanded ? Appearance.colors.colLayer3 : monitorMouseArea.containsMouse ? Appearance.colors.colLayer3Hover : "transparent"
        clip: true

        Behavior on implicitHeight {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        ColumnLayout {
            id: monitorItemContent
            anchors.fill: parent
            anchors.margins: 8
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item {
                    Layout.fillWidth: true
                    implicitHeight: monitorHeader.implicitHeight

                    MouseArea {
                        id: monitorMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: itemRoot.expanded = !itemRoot.expanded
                    }

                    RowLayout {
                        id: monitorHeader
                        anchors.fill: parent
                        spacing: 10

                        MaterialSymbol {
                            text: itemRoot.active ? "desktop_windows" : "monitor"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colOnSurfaceVariant
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: itemRoot.monitorData.name
                                color: Appearance.colors.colOnSurfaceVariant
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: `${itemRoot.monitorData.width}x${itemRoot.monitorData.height} @ ${Math.round(itemRoot.monitorData.refreshRate)}Hz - ${root.pendingX(itemRoot.monitorData)}, ${root.pendingY(itemRoot.monitorData)} - Workspace ${itemRoot.monitorData.activeWorkspace?.id ?? "?"}`
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.smallie
                                elide: Text.ElideRight
                            }
                        }

                    }
                }

                DialogButton {
                    buttonText: Translation.tr("Identify")
                    onClicked: root.identifyMonitor(itemRoot.monitorData)
                }

                MaterialSymbol {
                    text: "keyboard_arrow_down"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colSubtext
                    rotation: itemRoot.expanded ? 180 : 0

                    Behavior on rotation {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: itemRoot.expanded = !itemRoot.expanded
                    }
                }
            }

            RowLayout {
                visible: itemRoot.expanded
                Layout.fillWidth: true
                spacing: 10

                MaterialSymbol {
                    text: "open_with"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    text: Translation.tr("Pos X")
                    color: Appearance.colors.colOnSecondaryContainer
                }

                MaterialTextField {
                    id: posXField
                    Layout.preferredWidth: 82
                    Layout.preferredHeight: 44
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    text: `${root.pendingX(itemRoot.monitorData)}`
                    validator: IntValidator {
                        bottom: -20000
                        top: 20000
                    }
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    onAccepted: focus = false
                    onEditingFinished: root.setMonitorAxis(itemRoot.monitorData, "x", text)
                }

                StyledText {
                    text: Translation.tr("Pos Y")
                    color: Appearance.colors.colOnSecondaryContainer
                }

                MaterialTextField {
                    id: posYField
                    Layout.preferredWidth: 82
                    Layout.preferredHeight: 44
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    text: `${root.pendingY(itemRoot.monitorData)}`
                    validator: IntValidator {
                        bottom: -20000
                        top: 20000
                    }
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    onAccepted: focus = false
                    onEditingFinished: root.setMonitorAxis(itemRoot.monitorData, "y", text)
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Positions are snapped to avoid overlap.")
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.Wrap
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: identifyWindow
            required property var modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(identifyWindow.screen)

            screen: modelData
            visible: root.identifyOverlayVisible && (root.identifyingMonitorName === "__all__" || monitor?.name === root.identifyingMonitorName)
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:settings-monitor-identify"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Rectangle {
                anchors.centerIn: parent
                implicitWidth: identifyText.implicitWidth + 64
                implicitHeight: identifyText.implicitHeight + 40
                radius: Appearance.rounding.large
                color: Appearance.colors.colPrimaryContainer
                border.width: 2
                border.color: Appearance.colors.colPrimary

                StyledText {
                    id: identifyText
                    anchors.centerIn: parent
                    text: root.identifyingMonitorName === "__all__" ? (monitor?.name ?? "") : root.identifyingMonitorName
                    color: Appearance.colors.colOnPrimaryContainer
                    font.pixelSize: Appearance.font.pixelSize.title
                    font.weight: Font.Bold
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: -6
            spacing: 6

            OptionalMaterialSymbol {
                icon: "monitor"
                iconSize: Appearance.font.pixelSize.hugeass
            }

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Connected monitors")
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.Medium
                color: Appearance.colors.colOnSecondaryContainer
            }

            DialogButton {
                buttonText: Translation.tr("KDE display settings")
                onClicked: Quickshell.execDetached(["systemsettings", "display"])
            }
        }

        ContentSection {
            icon: "dashboard"
            title: Translation.tr("Layout")

            ConfigRow {
                DialogButton {
                    id: applyLayoutButton
                    buttonText: Translation.tr("Apply layout")
                    enabled: root.monitors().length > 0
                    colBackground: root.applyLayoutHintVisible ? Appearance.colors.colLayer3Hover : "transparent"
                    onClicked: root.applyLayout()
                }

                DialogButton {
                    buttonText: Translation.tr("Reset")
                    onClicked: root.resetLayout()
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Drag monitors to change their runtime position.")
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.Wrap
                }
            }

            Rectangle {
                id: layoutCanvas
                Layout.fillWidth: true
                implicitHeight: 260
                radius: Appearance.rounding.large
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: Appearance.colors.colLayer2
                clip: true

                Repeater {
                    model: root.monitors()

                    Rectangle {
                        id: monitorRect
                        required property var modelData
                        readonly property var bounds: root.layoutBounds()
                        readonly property real scaleFactor: root.canvasScale()
                        readonly property real baseX: 24 + (root.pendingX(modelData) - bounds.minX) * scaleFactor
                        readonly property real baseY: 24 + (root.pendingY(modelData) - bounds.minY) * scaleFactor

                        width: Math.max(root.monitorWidth(modelData) * scaleFactor, 88)
                        height: Math.max(root.monitorHeight(modelData) * scaleFactor, 56)
                        x: baseX
                        y: baseY
                        radius: Appearance.rounding.normal
                        color: modelData.focused ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2
                        border.width: 1
                        border.color: modelData.focused ? Appearance.colors.colPrimary : Appearance.colors.colLayer3
                        z: dragArea.drag.active ? 10 : 1

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: parent.width - 16
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData.name
                                color: modelData.focused ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer2
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: `${modelData.width}x${modelData.height}`
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.smallie
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: dragArea
                            anchors.fill: parent
                            cursorShape: Qt.SizeAllCursor
                            drag.target: parent
                            drag.minimumX: 8
                            drag.minimumY: 8
                            drag.maximumX: layoutCanvas.width - parent.width - 8
                            drag.maximumY: layoutCanvas.height - parent.height - 8
                            onReleased: {
                                root.updateDraggedMonitor(modelData, parent.x, parent.y);
                                monitorRect.x = Qt.binding(() => monitorRect.baseX);
                                monitorRect.y = Qt.binding(() => monitorRect.baseY);
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: root.monitors()

                MonitorItem {
                    required property var modelData
                    monitorData: modelData
                }
            }

            ConfigRow {
                DialogButton {
                    buttonText: Translation.tr("Refresh")
                    onClicked: HyprlandData.updateAll()
                }

                StyledText {
                    text: root.monitors().length === 1
                        ? Translation.tr("1 monitor connected")
                        : Translation.tr("%1 monitors connected").arg(root.monitors().length)
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.Wrap
                }

                Item {
                    Layout.fillWidth: true
                }

                DialogButton {
                    buttonText: Translation.tr("Identify all")
                    enabled: root.monitors().length > 0
                    onClicked: root.identifyAllMonitors()
                }
            }
        }
    }

    ContentSection {
        icon: "workspaces"
        title: Translation.tr("Secondary workspace")

        ConfigRow {
            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: 14
                text: Translation.tr("Choose where the secondary monitor should land by default.")
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }
        }

        ConfigRow {
            StyledText {
                text: Translation.tr("Monitor")
                color: Appearance.colors.colOnSecondaryContainer
            }

            StyledComboBox {
                Layout.fillWidth: true
                model: root.monitors().map(monitor => monitor.name)
                currentIndex: Math.max(0, root.monitors().map(monitor => monitor.name).indexOf(root.selectedSecondaryMonitor))
                onActivated: index => root.selectedSecondaryMonitor = root.monitors()[index]?.name ?? ""
            }
        }

        ConfigRow {
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Workspace")
                color: Appearance.colors.colOnSecondaryContainer
            }

            StyledSpinBox {
                from: 1
                to: 100
                value: root.secondaryWorkspace
                onValueChanged: root.secondaryWorkspace = value
            }

            DialogButton {
                buttonText: Translation.tr("Apply")
                onClicked: root.applySecondaryWorkspace()
            }
        }
    }
}
