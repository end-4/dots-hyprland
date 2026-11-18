import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root
    required property var service

    readonly property var windowByAddress: HyprlandData.windowByAddress
    readonly property var monitors: HyprlandData.monitors
    readonly property int cardCount: root.service.displayToplevels.length

    WlrLayershell.namespace: "quickshell:alttab"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"
    exclusiveZone: 0
    visible: root.service.alttabOpen
    implicitWidth: cardFrame.width
    implicitHeight: cardFrame.height
    anchors {
        top: true
        left: true
    }
    margins {
        top: Math.max(0, ((screen?.height ?? 1080) - cardFrame.height) / 2)
        left: Math.max(0, ((screen?.width ?? 1920) - cardFrame.width) / 2)
    }

    mask: Region {
        item: cardFrame
    }

    property int cardWidth: 220
    property int cardHeight: 124
    property int cardSpacing: 12
    property int framePadding: 16
    property int frameWidth: root.cardCount >= 4
        ? 1000
        : Math.max(
            300,
            root.cardCount * root.cardWidth
            + Math.max(0, root.cardCount - 1) * root.cardSpacing
            + root.framePadding * 2
            + 52
        )
    property int frameHeight: 240

    Component.onCompleted: GlobalFocusGrab.addDismissable(root)
    Component.onDestruction: GlobalFocusGrab.removeDismissable(root)

    Connections {
        target: GlobalFocusGrab
        function onDismissed() {
            root.service.alttabOpen = false;
            root.service.currentToplevel = null;
            root.service.currentIndex = 0;
        }
    }

    function windowDataForToplevel(toplevel) {
        if (!toplevel)
            return null;
        const addr = `0x${toplevel.HyprlandToplevel?.address}`;
        return windowByAddress[addr] ?? null;
    }

    function monitorDataForToplevel(toplevel) {
        if (!toplevel)
            return null;
        const winData = windowDataForToplevel(toplevel);
        if (!winData)
            return null;
        return monitors.find(m => m.id === winData.monitor) ?? null;
    }

    Rectangle {
        id: cardFrame
        color: Appearance.colors.colLayer1Base
        width: root.frameWidth
        height: root.frameHeight
        radius: Appearance.rounding.large
        border.width: 2
        border.color: Appearance.m3colors.m3outline

        Rectangle {
            id: innerFrame
            anchors.fill: parent
            anchors.margins: root.framePadding
            color: Appearance.colors.colLayer1Base
            radius: Appearance.rounding.small
            border.width: 1
            border.color: Appearance.m3colors.m3outline
            clip: true

            StyledText {
                anchors.centerIn: parent
                text: "None"
                visible: root.service.displayToplevels.length === 0
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Bold
            }

            Flickable {
                id: cardViewport
                anchors.fill: parent
                anchors.margins: root.framePadding
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                property int cardCount: root.cardCount
                contentWidth: cardRow.implicitWidth
                contentHeight: cardRow.implicitHeight

                function ensureSelectedVisible() {
                    const itemWidth = root.cardWidth + root.cardSpacing;
                    const selectedLeft = root.service.currentIndex * itemWidth;
                    const selectedRight = selectedLeft + root.cardWidth;
                    const maxContentX = Math.max(0, contentWidth - width);
                    let targetX = contentX;
                    if (selectedLeft < contentX)
                        targetX = selectedLeft;
                    else if (selectedRight > contentX + width)
                        targetX = selectedRight - width;
                    targetX = Math.max(0, Math.min(targetX, maxContentX));
                    contentX = targetX;
                }
                Behavior on contentX {
                    NumberAnimation {
                        duration: 240
                        easing.type: Easing.OutCubic
                    }
                }

                Connections {
                    target: root.service
                    function onCurrentIndexChanged() {
                        cardViewport.ensureSelectedVisible();
                    }
                    function onFilteredToplevelsChanged() {
                        cardViewport.ensureSelectedVisible();
                    }
                }

                Row {
                    id: cardRow
                    width: cardViewport.cardCount <= 4 ? cardViewport.width : implicitWidth
                    spacing: cardViewport.cardCount > 1 && cardViewport.cardCount <= 4 ? (cardViewport.width - cardViewport.cardCount * root.cardWidth) / (cardViewport.cardCount - 1) : root.cardSpacing

                    Repeater {
                        model: root.service.displayToplevels
                        delegate: AltTabCard {
                            required property var modelData
                            toplevel: modelData
                            windowData: root.windowDataForToplevel(modelData)
                            monitorData: root.monitorDataForToplevel(modelData)
                            isSelected: modelData === root.service.currentToplevel
                            cardWidth: root.cardWidth
                            cardHeight: root.cardHeight
                        }
                    }
                }
            }
        }
    }
}
