import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    property var screen
    property real maxWindowPreviewHeight: 200
    property real maxWindowPreviewWidth: 300
    property real windowControlsHeight: 30
    property real buttonPadding: 5

    property Item lastHoveredButton
    readonly property bool buttonHovered: !!lastHoveredButton && !!lastHoveredButton.previewHover
    property bool requestDockShow: previewPopup.show

    Layout.fillHeight: true
    Layout.topMargin: Appearance.sizes.hyprlandGapsOut // why does this work
    implicitWidth: listView.implicitWidth
    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property var visibleApps: {
        if (!(Config.options?.dock.perMonitorAppIcons ?? false)) {
            return TaskbarApps.apps;
        }

        const monitorId = monitor?.id;
        if (monitorId === undefined || monitorId === null) {
            return TaskbarApps.apps;
        }

        const apps = [];
        for (const app of TaskbarApps.apps) {
            if (app.appId === "SEPARATOR") {
                apps.push(app);
                continue;
            }

            const toplevels = app.toplevels.filter(toplevel => {
                const client = HyprlandData.clientForToplevel(toplevel);
                return client?.monitor === monitorId;
            });

            if (app.pinned || toplevels.length > 0) {
                apps.push({
                    appId: app.appId,
                    pinned: app.pinned,
                    toplevels: toplevels
                });
            }
        }
        return apps;
    }
    
    StyledListView {
        id: listView
        spacing: 2
        orientation: ListView.Horizontal
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        implicitWidth: contentWidth

        Behavior on implicitWidth {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        model: ScriptModel {
            objectProp: "appId"
            values: root.visibleApps
        }
        delegate: DockAppButton {
            required property var modelData
            appToplevel: modelData
            appListRoot: root

            topInset: Appearance.sizes.hyprlandGapsOut + root.buttonPadding
            bottomInset: Appearance.sizes.hyprlandGapsOut + root.buttonPadding
        }
    }

    PopupWindow {
        id: previewPopup
        property var appTopLevel: root.lastHoveredButton?.appToplevel
        property bool allPreviewsReady: false
        property bool mapped: false
        // Delay capture to avoid focus leaking to window on brief hovers (Hyprland toplevel export side effect)
        property bool captureReady: false
        Connections {
            target: root
            function onLastHoveredButtonChanged() {
                previewPopup.allPreviewsReady = false; // Reset readiness when the hovered button changes
            } 
        }
        function updatePreviewReadiness() {
            for(var i = 0; i < previewRowLayout.children.length; i++) {
                const view = previewRowLayout.children[i];
                if (view.hasContent === false) {
                    allPreviewsReady = false;
                    return;
                }
            }
            allPreviewsReady = true;
        }
        // Only accept popupMouseArea hovers during grace period after leaving icon - prevents
        // invisible mapped popup from phantom-triggering preview when mouse passes through
        property bool previewSessionActive: false
        property bool shouldShow: {
            if (root.buttonHovered) return true;
            // Only let popup hover keep it alive once it is actually shown.
            // This prevents rapid flyovers from latching an invisible mapped popup.
            return previewPopup.show && popupMouseArea.containsMouse && previewPopup.previewSessionActive;
        }
        property bool show: false

        Connections {
            target: root
            function onButtonHoveredChanged() {
                if (root.buttonHovered) {
                    previewSessionTimer.stop();
                    previewPopup.previewSessionActive = true;
                } else {
                    previewSessionTimer.restart();
                }
            }
        }
        Connections {
            target: popupMouseArea
            function onContainsMouseChanged() {
                if (popupMouseArea.containsMouse && previewPopup.previewSessionActive) {
                    previewSessionTimer.stop();
                } else if (!root.buttonHovered) {
                    previewSessionTimer.restart();
                }
            }
        }
        Timer {
            id: previewSessionTimer
            interval: 400
            onTriggered: previewPopup.previewSessionActive = false
        }

        onShowChanged: {
            if (show) {
                mapped = true;
                hideTimer.stop();
                captureReady = false;
                captureDelayTimer.restart();
            } else {
                captureDelayTimer.stop();
                captureReady = false;
                hideTimer.restart();
            }
        }
        Timer {
            id: hideTimer
            // Keep popup mapped briefly so opacity fade-out can complete.
            interval: 170
            onTriggered: {
                if (!previewPopup.show && !previewPopup.shouldShow) {
                    previewPopup.mapped = false;
                    if (!root.buttonHovered && !popupMouseArea.containsMouse) {
                        root.lastHoveredButton = null;
                    }
                }
            }
        }
        Timer {
            id: captureDelayTimer
            interval: 150
            onTriggered: previewPopup.captureReady = true
        }

        onShouldShowChanged: {
            if (shouldShow) {
                mapped = true;
                hideTimer.stop();
            }
            // Match working version behavior: debounce via a single fast timer.
            updateTimer.restart();
        }
        Timer {
            id: updateTimer
            interval: 100
            onTriggered: {
                previewPopup.show = previewPopup.shouldShow
            }
        }
        anchor {
            window: root.QsWindow.window
            adjustment: PopupAdjustment.None
            gravity: Edges.Top | Edges.Right
            edges: Edges.Top | Edges.Left

        }
        // Stay mapped when lastHoveredButton set so opacity exit animation can complete (grace period prevents phantom hovers)
        visible: mapped
        color: "transparent"
        implicitWidth: previewPopup.show ? (root.QsWindow.window?.width ?? 1) : 1
        implicitHeight: previewPopup.show ? (popupMouseArea.implicitHeight + root.windowControlsHeight + Appearance.sizes.elevationMargin * 2) : 1
        mask: Region {
            item: popupMouseArea
        }

        MouseArea {
            id: popupMouseArea
            enabled: previewPopup.show
            acceptedButtons: Qt.NoButton
            anchors.bottom: parent.bottom
            implicitWidth: previewPopup.show ? (popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2) : 0
            implicitHeight: previewPopup.show ? (root.maxWindowPreviewHeight + root.windowControlsHeight + Appearance.sizes.elevationMargin * 2) : 0
            hoverEnabled: previewPopup.show
            x: {
                if (!root.QsWindow || !root.lastHoveredButton) {
                    return 0;
                }

                const itemCenter = root.QsWindow.mapFromItem(root.lastHoveredButton, root.lastHoveredButton.width / 2, 0);
                return itemCenter.x - width / 2;
            }
            StyledRectangularShadow {
                target: popupBackground
                opacity: previewPopup.show ? 1 : 0
                visible: opacity > 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
            Rectangle {
                id: popupBackground
                property real padding: 5
                opacity: previewPopup.show ? 1 : 0
                visible: opacity > 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                clip: true
                color: Appearance.m3colors.m3surfaceContainer
                radius: Appearance.rounding.normal
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Appearance.sizes.elevationMargin
                anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: previewRowLayout.implicitHeight + padding * 2
                implicitWidth: previewRowLayout.implicitWidth + padding * 2
                Behavior on implicitWidth {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on implicitHeight {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                RowLayout {
                    id: previewRowLayout
                    anchors.centerIn: parent
                    Repeater {
                        model: ScriptModel {
                            values: previewPopup.appTopLevel?.toplevels ?? []
                        }
                        RippleButton {
                            id: windowButton
                            required property var modelData
                            padding: 0
                            middleClickAction: () => {
                                windowButton.modelData?.close();
                            }
                            onClicked: {
                                windowButton.modelData?.activate();
                            }
                            contentItem: ColumnLayout {
                                implicitWidth: screencopyView.implicitWidth
                                implicitHeight: screencopyView.implicitHeight

                                ButtonGroup {
                                    contentWidth: parent.width - anchors.margins * 2
                                    WrapperRectangle {
                                        Layout.fillWidth: true
                                        color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer)
                                        radius: Appearance.rounding.small
                                        margin: 5
                                        StyledText {
                                            Layout.fillWidth: true
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            text: windowButton.modelData?.title
                                            elide: Text.ElideRight
                                            color: Appearance.m3colors.m3onSurface
                                        }
                                    }
                                    GroupButton {
                                        id: closeButton
                                        colBackground: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer)
                                        baseWidth: windowControlsHeight
                                        baseHeight: windowControlsHeight
                                        buttonRadius: Appearance.rounding.full
                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            horizontalAlignment: Text.AlignHCenter
                                            text: "close"
                                            iconSize: Appearance.font.pixelSize.normal
                                            color: Appearance.m3colors.m3onSurface
                                        }
                                        onClicked: {
                                            windowButton.modelData?.close();
                                        }
                                    }
                                }
                                ScreencopyView {
                                    id: screencopyView
                                    // Only capture when preview is shown - avoids focus leaking to captured window on hover
                                    captureSource: previewPopup.show ? windowButton.modelData : null
                                    live: true
                                    paintCursor: false
                                    constraintSize: Qt.size(root.maxWindowPreviewWidth, root.maxWindowPreviewHeight)
                                    onHasContentChanged: {
                                        previewPopup.updatePreviewReadiness();
                                    }
                                    layer.enabled: true
                                    layer.effect: OpacityMask {
                                        maskSource: Rectangle {
                                            width: screencopyView.width
                                            height: screencopyView.height
                                            radius: Appearance.rounding.small
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
