import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root
    required property var service

    property var viewport: null
    readonly property var windowByAddress: HyprlandData.windowByAddress
    readonly property var monitors: HyprlandData.monitors
    readonly property int cardCount: root.service.filteredToplevels.length
    property int frameWidth: cardCount >= 4
        ? 1000
        : Math.max(300, cardCount * root.cardWidth
            + Math.max(0, cardCount - 1) * root.cardSpacing
            + root.framePadding * 4)
    property int frameHeight: 240

    function isPreviewVisible(toplevel) {
        return root.service.visibleToplevels.indexOf(toplevel) >= 0
    }
    function ensureSelectedCardVisible() {
        if (root.viewport) root.viewport.ensureSelectedVisible()
    }

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
    property int cardSpacing: 45
    property int framePadding: 16

    Component.onCompleted: GlobalFocusGrab.addDismissable(root)
    Component.onDestruction: GlobalFocusGrab.removeDismissable(root)

    Connections {
        target: GlobalFocusGrab
        function onDismissed() {
            root.service.alttabOpen = false
            root.service.currentToplevel = null
            root.service.currentIndex = 0
        }
    }

    function windowDataForToplevel(toplevel) {
        if (!toplevel) return null
        const addr = `0x${toplevel.HyprlandToplevel?.address}`
        return windowByAddress[addr] ?? null
    }

    function monitorDataForToplevel(toplevel) {
        if (!toplevel) return null
        const winData = windowDataForToplevel(toplevel)
        if (!winData) return null
        return monitors.find(m => m.id === winData.monitor) ?? null
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
            border.width: 0
            border.color: "transparent"
            clip: true

            StyledText {
                anchors.centerIn: parent
                text: "None"
                visible: root.service.filteredToplevels.length === 0
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Bold
            }
            Flickable {
                id: cardViewport
                anchors.fill: parent
                anchors.margins: root.framePadding
                Component.onCompleted: root.viewport = cardViewport
                Component.onDestruction: {
                    if (root.viewport === cardViewport) root.viewport = null
                }
                property int cardCount: root.service.filteredToplevels.length
                contentWidth: cardRow.implicitWidth
                contentHeight: cardRow.implicitHeight

                function ensureSelectedVisible() {
                    const itemWidth = root.cardWidth + root.cardSpacing
                    const selectedLeft = root.service.currentIndex * itemWidth
                    const selectedRight = selectedLeft + root.cardWidth
                    const maxContentX = Math.max(0, contentWidth - width)
                    let targetX = contentX
                    if (selectedLeft < contentX)
                        targetX = selectedLeft
                    else if (selectedRight > contentX + width)
                        targetX = selectedRight - width
                    targetX = Math.max(0, Math.min(targetX, maxContentX))
                    contentX = targetX
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
                        root.ensureSelectedCardVisible()
                    }
                }
                Row {
                    id: cardRow
                    x: root.cardCount <= 4
                        ? Math.max(0, (root.frameWidth - root.framePadding * 4 - implicitWidth) / 2)
                        : 0
                    y: Math.max(0, (root.frameHeight - root.framePadding * 4 - implicitHeight) / 2)
                    width: implicitWidth
                    spacing: root.cardSpacing

                    Repeater {
                        model: root.service.filteredToplevels
                        delegate: AltTabCard {
                            required property var modelData
                            required property int index
                            toplevel: modelData
                            windowData: root.windowDataForToplevel(modelData)
                            monitorData: root.monitorDataForToplevel(modelData)
                            isSelected: modelData === root.service.currentToplevel || index === root.service.currentIndex
                            captureEnabled: root.service.alttabOpen && root.isPreviewVisible(modelData)
                            cardWidth: root.cardWidth
                            cardHeight: root.cardHeight
                        }
                    }
                }
            }
        }
    }
    }
