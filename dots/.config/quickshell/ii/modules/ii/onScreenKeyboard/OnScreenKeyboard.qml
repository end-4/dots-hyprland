import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope { // Scope
    id: root
    property bool pinned: Config.options?.osk.pinnedOnStartup ?? false

    component OskControlButton: GroupButton { // Pin button
        baseWidth: 40
        baseHeight: width
        clickedWidth: width
        clickedHeight: width + 10
        buttonRadius: Appearance.rounding.normal

        height: width

        Layout.fillWidth: true
        Layout.preferredWidth: baseWidth

        function calculateIconSize() {
            return height >= 50 ? Appearance.font.pixelSize.huge : Appearance.font.pixelSize.larger;
        }
    }

    Loader {
        id: oskLoader
        active: GlobalStates.oskOpen
        onActiveChanged: {
            if (!oskLoader.active) {
                Ydotool.releaseAllKeys();
            }
        }
        
        sourceComponent: PanelWindow { // Window
            id: oskRoot
            visible: oskLoader.active && !GlobalStates.screenLocked

            anchors {
                bottom: true
                left: true
                right: true
            }

            function hide() {
                GlobalStates.oskOpen = false
            }
            exclusiveZone: root.pinned ? implicitHeight - Appearance.sizes.hyprlandGapsOut : 0
            implicitHeight: oskBackground.height + Appearance.sizes.elevationMargin * 2
            WlrLayershell.namespace: "quickshell:osk"
            WlrLayershell.layer: WlrLayer.Overlay
            // Hyprland 0.49: Focus is always exclusive and setting this breaks mouse focus grab
            // WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            mask: Region {
                item: oskBackground
            }


            // Background
            StyledRectangularShadow {
                target: oskBackground
            }
            Rectangle {
                id: oskBackground
                anchors.centerIn: parent
                property real maxWidth: {
                    return Math.max(Screen.width, Screen.height) * Config.options.osk.maxWidthFraction
                }
                property real aspectRatio: 0.35
                property real padding: 10
                implicitWidth: {
                    return Math.min(Screen.width - 2 * Appearance.sizes.elevationMargin, maxWidth)
                }
                implicitHeight: implicitWidth * aspectRatio + padding * 2
                color: Appearance.colors.colLayer0
                radius: Appearance.rounding.windowRounding

                Keys.onPressed: (event) => { // Esc to close
                    if (event.key === Qt.Key_Escape) {
                        oskRoot.hide()
                    }
                }

                RowLayout {
                    id: oskRowLayout
                    anchors {
                        fill: parent
                        margins: oskBackground.padding
                    }
                    spacing: oskBackground.padding
                    VerticalButtonGroup {
                        Layout.fillWidth: true
                        OskControlButton { // Pin button
                            toggled: root.pinned
                            downAction: () => root.pinned = !root.pinned
                            contentItem: MaterialSymbol {
                                text: "keep"
                                horizontalAlignment: Text.AlignHCenter
                                iconSize: parent.calculateIconSize()
                                color: root.pinned ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer0
                            }
                            onHeightChanged: {
                                contentItem.iconSize = calculateIconSize()
                            }
                        }
                        OskControlButton {
                            onClicked: () => {
                                oskRoot.hide()
                            }
                            contentItem: MaterialSymbol {
                                horizontalAlignment: Text.AlignHCenter
                                text: "keyboard_hide"
                                iconSize: parent.calculateIconSize()
                            }
                            onHeightChanged: {
                                contentItem.iconSize = calculateIconSize()
                            }
                        }
                    }
                    Rectangle {
                        Layout.topMargin: 20
                        Layout.bottomMargin: 20
                        Layout.fillHeight: true
                        implicitWidth: 1
                        color: Appearance.colors.colOutlineVariant
                    }
                    OskContent {
                        id: oskContent
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }

        }
    }

    IpcHandler {
        target: "osk"

        function toggle(): void {
            GlobalStates.oskOpen = !GlobalStates.oskOpen;
        }

        function close(): void {
            GlobalStates.oskOpen = false
        }

        function open(): void {
            GlobalStates.oskOpen = true
        }
    }

    GlobalShortcut {
        name: "oskToggle"
        description: "Toggles on screen keyboard on press"

        onPressed: {
            GlobalStates.oskOpen = !GlobalStates.oskOpen;
        }
    }

    GlobalShortcut {
        name: "oskOpen"
        description: "Opens on screen keyboard on press"

        onPressed: {
            GlobalStates.oskOpen = true
        }
    }

    GlobalShortcut {
        name: "oskClose"
        description: "Closes on screen keyboard on press"

        onPressed: {
            GlobalStates.oskOpen = false
        }
    }

}
