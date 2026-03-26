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
    property int lastFocused: -1
    property real iconSize: 35
    property real countDotWidth: 10
    property real countDotHeight: 4
    property bool appIsActive: appToplevel.toplevels.find(function(t) { return t.activated === true }) !== undefined

    // ── Magnify: SmoothedAnimation = NO jerks ──
    property real targetMagnifyScale: {
        if (!appListRoot || !appListRoot.dockHovered)
            return 1.0

        var centerX = root.mapToItem(appListRoot, root.width / 2, 0).x
        var dist = Math.abs(centerX - appListRoot.hoverMouseX)
        var radius = 90
        var maxExtra = 0.65
        var t = Math.max(0, 1 - dist / radius)

        return 1.0 + maxExtra * (t * t * (3 - 2 * t))
    }

    property real magnifyScale: 1.0

    // SmoothedAnimation: velocity-limited, naturally jerk-free
    Behavior on magnifyScale {
        SmoothedAnimation {
            velocity: 5.0
            duration: -1  // velocity-only mode, no fixed duration
        }
    }

    onTargetMagnifyScaleChanged: {
        magnifyScale = targetMagnifyScale
    }

    readonly property bool isSeparator: appToplevel.appId === "SEPARATOR"
    property var desktopEntry: DesktopEntries.heuristicLookup(appToplevel.appId)

    enabled: !isSeparator
    implicitWidth: isSeparator ? 1 : implicitHeight - topInset - bottomInset

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.desktopEntry = DesktopEntries.heuristicLookup(appToplevel.appId)
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

    HoverHandler {
        id: hoverHandler
        enabled: !root.isSeparator

        onHoveredChanged: {
            if (hovered) {
                appListRoot.lastHoveredButton = root
                appListRoot.buttonHovered = appToplevel.toplevels.length > 0
                appListRoot.dockHovered = true
                appListRoot.hoverMouseX = root.mapToItem(appListRoot, root.width / 2, 0).x
                lastFocused = Math.max(0, appToplevel.toplevels.length - 1)
            } else {
                if (appListRoot.lastHoveredButton === root) {
                    appListRoot.buttonHovered = false
                    appListRoot.lastHoveredButton = null
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        enabled: !root.isSeparator

        onPositionChanged: function(mouse) {
            appListRoot.dockHovered = true
            appListRoot.hoverMouseX = root.mapToItem(appListRoot, mouse.x, 0).x
        }
    }

    onClicked: {
        if (appToplevel.toplevels.length === 0) {
            root.desktopEntry?.execute()
            return
        }

        lastFocused = (lastFocused + 1) % appToplevel.toplevels.length
        appToplevel.toplevels[lastFocused].activate()
    }

    middleClickAction: function() {
        root.desktopEntry?.execute()
    }

    altAction: function() {
        TaskbarApps.togglePin(appToplevel.appId)
    }

    contentItem: Loader {
        active: !isSeparator

        sourceComponent: Item {
            implicitWidth: root.iconSize * 1.8
            implicitHeight: root.iconSize * 1.8
            clip: false
            anchors.centerIn: parent

            Loader {
                id: iconImageLoader
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -3
                active: !root.isSeparator

                sourceComponent: IconImage {
                    source: Quickshell.iconPath(AppSearch.guessIcon(appToplevel.appId), "image-missing")
                    implicitSize: root.iconSize
                    scale: root.magnifyScale
                    transformOrigin: Item.Bottom
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

                property int totalWindows: appToplevel.toplevels.length
                property bool showLongBar: totalWindows >= 4
                property bool anyFocused: {
                    for (var i = 0; i < appToplevel.toplevels.length; i++) {
                        if (appToplevel.toplevels[i] && appToplevel.toplevels[i].activated)
                            return true
                    }
                    return false
                }
                property int activeIndex: {
                    for (var i = 0; i < appToplevel.toplevels.length; i++) {
                        if (appToplevel.toplevels[i] && appToplevel.toplevels[i].activated)
                            return i
                    }
                    return -1
                }

                Loader {
                    active: parent.showLongBar

                    sourceComponent: Rectangle {
                        id: longBar
                        property bool isFocused: parent.parent.anyFocused

                        implicitWidth: root.countDotWidth * 3
                        implicitHeight: root.countDotHeight
                        radius: 2
                        color: isFocused
                            ? Appearance.colors.colPrimary
                            : ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.45)

                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }

                        layer.enabled: isFocused
                        layer.effect: Glow {
                            radius: 6
                            samples: 13
                            color: Appearance.colors.colPrimary
                            spread: 0.4
                        }
                    }
                }

                Repeater {
                    model: parent.showLongBar ? 0 : Math.min(parent.totalWindows, 3)

                    delegate: Item {
                        required property int index

                        property var thisToplevel: appToplevel.toplevels[index]
                        property bool isActivated: thisToplevel ? thisToplevel.activated : false

                        implicitWidth: isActivated ? root.countDotWidth : root.countDotHeight
                        implicitHeight: root.countDotHeight

                        Behavior on implicitWidth {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: isActivated ? 2 : Appearance.rounding.full
                            color: isActivated
                                ? Appearance.colors.colPrimary
                                : ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.45)

                            Behavior on color {
                                ColorAnimation { duration: 200 }
                            }

                            Behavior on radius {
                                NumberAnimation { duration: 200 }
                            }

                            layer.enabled: isActivated
                            layer.effect: Glow {
                                radius: 6
                                samples: 13
                                color: Appearance.colors.colPrimary
                                spread: 0.4
                            }
                        }
                    }
                }
            }
        }
    }
}
