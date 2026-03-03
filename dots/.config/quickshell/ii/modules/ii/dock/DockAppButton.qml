import qs.services
import qs.modules.common
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

DockButton {
    id: root
    property var appToplevel
    property var appListRoot
    property int delegateIndex: -1
    property int lastFocused: -1
    property real iconSize: 35
    property real countDotWidth: 10
    property real countDotHeight: 4
    property bool appIsActive: appToplevel.toplevels.find(t => (t.activated == true)) !== undefined

    readonly property bool isSeparator: appToplevel.appId === "SEPARATOR"
    property var desktopEntry: DesktopEntries.heuristicLookup(appToplevel.appId)

    Timer {
        // Retry looking up the desktop entry if it failed (e.g. database not loaded yet)
        property int retryCount: 5
        interval: 1000
        running: !root.isSeparator && root.desktopEntry === null && retryCount > 0
        repeat: true
        onTriggered: {
            retryCount--;
            root.desktopEntry = DesktopEntries.heuristicLookup(root.appToplevel.appId);
        }
    }

    enabled: !isSeparator
    implicitWidth: isSeparator ? 1 : implicitHeight - topInset - bottomInset

    // Drag-to-reorder
    readonly property bool isDragged: appListRoot.dragging && delegateIndex === appListRoot.dragSourceIndex
    readonly property real dragTranslateX: {
        if (!appListRoot.dragging) return 0;
        if (isDragged) return appListRoot.dragCursorX - appListRoot.dragStartCursorX;
        if (!appToplevel.pinned || isSeparator) return 0;
        var src = appListRoot.dragSourceIndex;
        var tgt = appListRoot.dragTargetIndex;
        var idx = delegateIndex;
        if (src < tgt && idx > src && idx <= tgt) return -appListRoot.slotWidth;
        if (src > tgt && idx >= tgt && idx < src) return appListRoot.slotWidth;
        return 0;
    }
    z: isDragged ? 100 : 0
    opacity: isDragged ? 0.85 : (enabled ? 1 : 0.4)
    scale: isDragged ? 1.05 : 1

    transform: Translate {
        x: root.dragTranslateX
        Behavior on x {
            enabled: !root.isDragged && !appListRoot._suppressTranslateAnim
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    Loader {
        active: isSeparator
        anchors {
            fill: parent
            topMargin: dockVisualBackground.margin + dockRow.padding + Appearance.rounding.normal
            bottomMargin: dockVisualBackground.margin + dockRow.padding + Appearance.rounding.normal
        }
        sourceComponent: DockSeparator {}
    }

    Loader {
        anchors.fill: parent
        active: appToplevel.toplevels.length > 0
        sourceComponent: MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: {
                appListRoot.lastHoveredButton = root
                appListRoot.buttonHovered = true
                lastFocused = appToplevel.toplevels.length - 1
            }
            onExited: {
                if (appListRoot.lastHoveredButton === root) {
                    appListRoot.buttonHovered = false
                }
            }
        }
    }

    // Drag overlay for pinned non-separator items
    Loader {
        anchors.fill: parent
        z: 10
        active: appToplevel.pinned && !isSeparator
        sourceComponent: MouseArea {
            id: dragOverlay
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            preventStealing: true
            property real pressX: 0
            property bool dragActive: false

            onPressed: (event) => {
                pressX = event.x;
                root.down = true;
                root.startRipple(event.x, event.y);
            }
            onPositionChanged: (event) => {
                if (!pressed) return;
                var dist = Math.abs(event.x - pressX);
                if (!dragActive && dist > 5) {
                    dragActive = true;
                    root.cancelRipple();
                    root.down = false;
                    appListRoot.buttonHovered = false;
                    // Set all state BEFORE enabling drag to avoid stale computations
                    appListRoot.dragSourceIndex = root.delegateIndex;
                    var mapped = mapToItem(appListRoot, event.x, event.y);
                    appListRoot.dragStartCursorX = mapped.x;
                    appListRoot.dragCursorX = mapped.x;
                    appListRoot.slotWidth = root.width + 2; // width + listView spacing
                    appListRoot.dragging = true;
                }
                if (dragActive) {
                    var mapped = mapToItem(appListRoot, event.x, event.y);
                    appListRoot.dragCursorX = mapped.x;
                }
            }
            onReleased: (event) => {
                if (dragActive) {
                    dragActive = false;
                    appListRoot.finishDrag();
                } else {
                    root.down = false;
                    root.cancelRipple();
                    root.click();
                }
            }
            onCanceled: {
                if (dragActive) {
                    dragActive = false;
                    appListRoot.cancelDrag();
                }
                root.down = false;
                root.cancelRipple();
            }
        }
    }

    onClicked: {
        if (appToplevel.toplevels.length === 0) {
            root.desktopEntry?.execute();
            return;
        }
        lastFocused = (lastFocused + 1) % appToplevel.toplevels.length
        appToplevel.toplevels[lastFocused].activate()
    }

    middleClickAction: () => {
        root.desktopEntry?.execute();
    }

    altAction: () => {
        appListRoot.openContextMenu(root, appToplevel);
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
                        visible: false // There's already color overlay
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
