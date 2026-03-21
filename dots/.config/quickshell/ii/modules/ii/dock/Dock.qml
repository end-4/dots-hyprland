import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

Scope { // Scope
    id: root
    property bool pinned: Config.options?.dock.pinnedOnStartup ?? false

    // Hyprland workaround: moving cursor away before toggling pin avoids exclusive zone
    // changes leaving input stuck on one monitor (bottom becomes non-interactable)
    Process {
        id: pinWithHyprlandWorkaroundProc
        property var cursorHook: null
        property int cursorX: 0
        property int cursorY: 0
        function doIt() {
            cursorHook = (output) => {
                const parts = output.trim().split(",")
                cursorX = parseInt(parts[0]) || 0
                cursorY = parseInt(parts[1]) || 0
                doIt2()
            }
            command = ["hyprctl", "cursorpos"]
            running = true
        }
        function doIt2() {
            cursorHook = () => doIt3()
            command = ["bash", "-c", "hyprctl dispatch movecursor 9999 9999"]
            running = true
        }
        function doIt3() {
            root.pinned = !root.pinned
            if (Config.options?.dock) Config.options.dock.pinnedOnStartup = root.pinned
            cursorHook = null
            command = ["bash", "-c", `sleep 0.02; hyprctl dispatch movecursor ${cursorX} ${cursorY}`]
            running = true
        }
        stdout: StdioCollector {
            onStreamFinished: {
                if (pinWithHyprlandWorkaroundProc.cursorHook)
                    pinWithHyprlandWorkaroundProc.cursorHook(text)
            }
        }
    }

    function togglePin() {
        if (!root.pinned) pinWithHyprlandWorkaroundProc.doIt()
        else {
            root.pinned = false
            if (Config.options?.dock) Config.options.dock.pinnedOnStartup = false
        }
    }

    Variants {
        // For each monitor
        model: Quickshell.screens

        PanelWindow {
            id: dockRoot
            // Window
            required property var modelData
            screen: modelData
            visible: !GlobalStates.screenLocked

            property bool reveal: root.pinned || (Config.options?.dock.hoverToReveal && dockMouseArea.containsMouse) || dockApps.requestDockShow || (!ToplevelManager.activeToplevel?.activated)
            onRevealChanged: revealSettleTimer.restart()

            anchors {
                bottom: true
                left: true
                right: true
            }

            exclusiveZone: root.pinned ? implicitHeight - (Appearance.sizes.hyprlandGapsOut) - (Appearance.sizes.elevationMargin - Appearance.sizes.hyprlandGapsOut) : 0

            implicitWidth: dockBackground.implicitWidth
            WlrLayershell.namespace: "quickshell:dock"
            // Explicit None to avoid layer-shell focus getting stuck (Hyprland OnDemand bugs)
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            color: "transparent"

            implicitHeight: (Config.options?.dock.height ?? 70) + Appearance.sizes.elevationMargin + Appearance.sizes.hyprlandGapsOut

            mask: Region {
                id: dockMask
                item: dockMouseArea
            }

            Connections {
                target: GlobalStates
                function onSidebarLeftOpenChanged() {
                    Qt.callLater(() => dockMask.changed())
                }
                function onSidebarRightOpenChanged() {
                    Qt.callLater(() => dockMask.changed())
                }
            }

            // Refresh Region after reveal animation completes. Rapid hover (before animation
            // plays) can leave the input region in a broken state; this ensures we resync.
            Timer {
                id: revealSettleTimer
                interval: 250  // elementMoveFast is 200ms, add buffer
                repeat: false
                onTriggered: dockMask.changed()
            }

            MouseArea {
                id: dockMouseArea
                height: parent.height
                anchors {
                    top: parent.top
                    topMargin: dockRoot.reveal ? 0 : Config.options?.dock.hoverToReveal ? (dockRoot.implicitHeight - Config.options.dock.hoverRegionHeight) : (dockRoot.implicitHeight + 1)
                    horizontalCenter: parent.horizontalCenter
                }
                implicitWidth: dockHoverRegion.implicitWidth + Appearance.sizes.elevationMargin * 2
                hoverEnabled: true

                Behavior on anchors.topMargin {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                Item {
                    id: dockHoverRegion
                    anchors.fill: parent
                    implicitWidth: dockBackground.implicitWidth

                    Item { // Wrapper for the dock background
                        id: dockBackground
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                        }

                        implicitWidth: dockRow.implicitWidth + 5 * 2
                        height: parent.height - Appearance.sizes.elevationMargin - Appearance.sizes.hyprlandGapsOut

                        StyledRectangularShadow {
                            target: dockVisualBackground
                        }
                        Rectangle { // The real rectangle that is visible
                            id: dockVisualBackground
                            property real margin: Appearance.sizes.elevationMargin
                            anchors.fill: parent
                            anchors.topMargin: Appearance.sizes.elevationMargin
                            anchors.bottomMargin: Appearance.sizes.hyprlandGapsOut
                            color: Appearance.colors.colLayer0
                            border.width: 1
                            border.color: Appearance.colors.colLayer0Border
                            radius: Appearance.rounding.large
                        }

                        RowLayout {
                            id: dockRow
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 3
                            property real padding: 5

                            VerticalButtonGroup {
                                Layout.topMargin: Appearance.sizes.hyprlandGapsOut // why does this work
                                GroupButton {
                                    // Pin button
                                    baseWidth: 35
                                    baseHeight: 35
                                    clickedWidth: baseWidth
                                    clickedHeight: baseHeight + 20
                                    buttonRadius: Appearance.rounding.normal
                                    toggled: root.pinned
                                    onClicked: root.togglePin()
                                    contentItem: MaterialSymbol {
                                        text: "keep"
                                        horizontalAlignment: Text.AlignHCenter
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: root.pinned ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer0
                                    }
                                }
                            }
                            DockSeparator {}
                            DockApps {
                                id: dockApps
                                screen: dockRoot.screen
                                buttonPadding: dockRow.padding
                            }
                            DockSeparator {}
                            DockButton {
                                Layout.fillHeight: true
                                onClicked: GlobalStates.overviewOpen = !GlobalStates.overviewOpen
                                topInset: Appearance.sizes.hyprlandGapsOut + dockRow.padding
                                bottomInset: Appearance.sizes.hyprlandGapsOut + dockRow.padding
                                contentItem: MaterialSymbol {
                                    anchors.fill: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    font.pixelSize: parent.width / 2
                                    text: "apps"
                                    color: Appearance.colors.colOnLayer0
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
