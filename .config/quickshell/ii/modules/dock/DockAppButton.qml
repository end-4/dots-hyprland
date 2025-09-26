import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

DockButton {
    id: root
    property var appToplevel
    property var appListRoot
    property int lastFocused: -1
    property real iconSize: 35
    property real countDotWidth: 10
    property real countDotHeight: 4
    property bool appIsActive: appToplevel.toplevels.find(t => (t.activated == true)) !== undefined

    property bool isSeparator: appToplevel.appId === "SEPARATOR"
    property var desktopEntry: DesktopEntries.heuristicLookup(appToplevel.appId)
    enabled: !isSeparator
    implicitWidth: isSeparator ? 1 : implicitHeight - topInset - bottomInset

    // Drag and drop properties
    property bool isDragging: false
    property bool isDropTarget: false
    property real dragStartX: 0

    states: [
        State {
            name: "dragging"
            when: isDragging
            PropertyChanges {
                target: root
                z: 100
                scale: 1.05
                opacity: 0.8
            }
        },
        State {
            name: "dropTarget"
            when: isDropTarget
            PropertyChanges {
                target: root
                scale: 0.95
            }
        }
    ]

    transitions: [
        Transition {
            NumberAnimation {
                properties: "scale,opacity"
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
    ]

    Loader {
        active: isSeparator
        anchors {
            fill: parent
            topMargin: dockVisualBackground.margin + dockRow.padding + Appearance.rounding.normal
            bottomMargin: dockVisualBackground.margin + dockRow.padding + Appearance.rounding.normal
        }
        sourceComponent: DockSeparator {}
    }

    // Drag manager for drag and drop functionality
    DragManager {
        id: dragManager
        anchors.fill: parent
        enabled: !isSeparator
        hoverEnabled: true
        z: isDragging ? 200 : 1

        property bool dragThresholdMet: false
        property real dragThreshold: 8
        property point startPos: Qt.point(0, 0)

        onEntered: {
            if (!isDragging && appToplevel.toplevels.length > 0) {
                appListRoot.lastHoveredButton = root
                appListRoot.buttonHovered = true
                lastFocused = appToplevel.toplevels.length - 1
            }
        }

        onExited: {
            if (appListRoot.lastHoveredButton === root && !isDragging) {
                appListRoot.buttonHovered = false
            }
        }

        onPressed: (mouse) => {
            startPos = Qt.point(mouse.x, mouse.y)
            dragThresholdMet = false
            // Accept all clicks to ensure full icon coverage
            mouse.accepted = true
        }

        onDragPressed: (diffX, diffY) => {
            const distance = Math.sqrt(diffX * diffX + diffY * diffY)
            if (distance > dragThreshold && !dragThresholdMet) {
                dragThresholdMet = true
                isDragging = true
                // Notify parent about drag start
                if (appListRoot.onDragStart) {
                    appListRoot.onDragStart(root)
                }
            }

            if (isDragging && appListRoot.onDragMove) {
                // Calculate actual global position
                const globalPos = dragManager.mapToItem(appListRoot, startPos.x + diffX, startPos.y + diffY)
                appListRoot.onDragMove(root, globalPos.x, globalPos.y)
            }
        }

        onDragReleased: (diffX, diffY) => {
            if (isDragging) {
                isDragging = false
                if (appListRoot.onDragEnd) {
                    const globalPos = dragManager.mapToItem(appListRoot, startPos.x + diffX, startPos.y + diffY)
                    appListRoot.onDragEnd(root, globalPos.x, globalPos.y)
                }
            }
        }

        onClicked: {
            if (!dragThresholdMet) {
                // Normal click behavior
                if (appToplevel.toplevels.length === 0) {
                    root.desktopEntry?.execute();
                    return;
                }
                lastFocused = (lastFocused + 1) % appToplevel.toplevels.length
                appToplevel.toplevels[lastFocused].activate()
            }
        }
    }


    middleClickAction: () => {
        root.desktopEntry?.execute();
    }

    altAction: () => {
        if (Config.options.dock.pinnedApps.indexOf(appToplevel.appId) !== -1) {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.filter(id => id !== appToplevel.appId)
        } else {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.concat([appToplevel.appId])
        }
    }

    contentItem: Loader {
        active: !isSeparator
        sourceComponent: Item {
            anchors.centerIn: parent

            Loader {
                id: iconImageLoader
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                active: !root.isSeparator
                sourceComponent: IconImage {
                    source: Quickshell.iconPath(AppSearch.guessIcon(appToplevel.appId), "image-missing")
                    implicitSize: root.iconSize
                }
            }

            Loader {
                active: Config.options.dock.monochromeIcons
                anchors.fill: iconImageLoader
                sourceComponent: Item {
                    Desaturate {
                        id: desaturatedIcon
                        visible: false
                        anchors.fill: parent
                        source: iconImageLoader
                        desaturation: 0.8
                    }
                    ColorOverlay {
                        anchors.fill: desaturatedIcon
                        source: desaturatedIcon
                        color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.9)
                    }
                }
            }

            RowLayout {
                spacing: 3
                anchors {
                    top: iconImageLoader.bottom
                    topMargin: 2
                    horizontalCenter: parent.horizontalCenter
                }
                Repeater {
                    model: Math.min(appToplevel.toplevels.length, 3)
                    delegate: Rectangle {
                        required property int index
                        radius: Appearance.rounding.full
                        implicitWidth: (appToplevel.toplevels.length <= 3) ?
                            root.countDotWidth : root.countDotHeight // Circles when too many
                        implicitHeight: root.countDotHeight
                        color: appIsActive ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.4)
                    }
                }
            }
        }
    }
}
