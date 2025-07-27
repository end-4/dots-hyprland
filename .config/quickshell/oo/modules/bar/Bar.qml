import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.singletons
import qs.modules.common.widgets

Scope {
    id: root

    Variants {
        // For each monitor
        model: Quickshell.screens
        LazyLoader {
            id: barLoader
            active: GlobalStates.barOpen
            required property ShellScreen modelData
            component: PanelWindow { // Bar window
                id: barRoot
                screen: barLoader.modelData

                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: Appearance.sizes.barHeight + Appearance.sizes.barBorder
                WlrLayershell.namespace: "oo:bar"
                implicitHeight: Appearance.sizes.barHeight + Appearance.sizes.barBorder
                mask: Region {
                    item: barContent
                }
                color: "transparent"

                anchors {
                    bottom: true
                    left: true
                    right: true
                }

                Item { // Bar content region
                    id: barContent
                    anchors {
                        right: parent.right
                        left: parent.left
                        bottom: parent.bottom
                    }
                    implicitHeight: Appearance.sizes.barHeight + Appearance.sizes.barBorder

                    // Background
                    Rectangle {
                        id: barBackground
                        anchors {
                            fill: parent
                            topMargin: Appearance.sizes.barBorder
                        }
                        color: Appearance.colors.colLayer0
                    }
                    // Border
                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            bottomMargin: Appearance.sizes.barHeight
                        }
                        implicitHeight: Appearance.sizes.barBorder
                        color: Appearance.colors.colOutlineVariant
                    }

                    // Stuff
                    RowLayout {
                        anchors {
                            fill: parent
                            topMargin: Appearance.sizes.barBorder
                        }
                        BarButton {
                            id: startButton
                            Layout.fillHeight: true

                            property real targetRotation: 0
                            onPressed: targetRotation += 180
                            rotation: targetRotation
                            Behavior on rotation {
                                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                            }

                            onClicked: GlobalStates.launcherOpen = !GlobalStates.launcherOpen

                            HexRect {
                                anchors.centerIn: parent
                                color: startButton.active ? 
                                    (startButton.hovered ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary)
                                    : (startButton.hovered ? Appearance.colors.colLayer3Hover : Appearance.colors.colLayer3)
                                Behavior on borderColor {
                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                }
                                property real size: Appearance.sizes.barHeight * 0.75
                                property real sizeDown: size * 0.85
                                property real effectiveSize: startButton.down ? sizeDown : size
                                Behavior on effectiveSize {
                                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                }
                                implicitWidth: effectiveSize
                                implicitHeight: effectiveSize
                            }
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "add"
                                iconSize: Appearance.sizes.barHeight * 0.6
                                color: Appearance.colors.colOnLayer3
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "bar"

        function toggle(): void {
            GlobalStates.barOpen = !GlobalStates.barOpen;
        }

        function close(): void {
            GlobalStates.barOpen = false;
        }

        function open(): void {
            GlobalStates.barOpen = true;
        }
    }

    GlobalShortcut {
        name: "barToggle"
        description: "Toggles bar on press"

        onPressed: {
            GlobalStates.barOpen = !GlobalStates.barOpen;
        }
    }

    GlobalShortcut {
        name: "barOpen"
        description: "Opens bar on press"

        onPressed: {
            GlobalStates.barOpen = true;
        }
    }

    GlobalShortcut {
        name: "barClose"
        description: "Closes bar on press"

        onPressed: {
            GlobalStates.barOpen = false;
        }
    }
}
