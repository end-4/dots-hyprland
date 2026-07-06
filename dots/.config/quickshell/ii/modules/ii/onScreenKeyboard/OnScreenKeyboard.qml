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
    // 0=floating (draggable, content width), 1=fullwidth (draggable, full width)
    property int oskMode: Persistent.states.osk.mode
    property real floatY: Persistent.states.osk.floatY
    property real floatX: Persistent.states.osk.floatX
    onOskModeChanged: {
        if (root.oskMode === 1) {
            root.floatX = 0
            Persistent.states.osk.floatX = 0
        }
    }

    component OskControlButton: GroupButton { // Control button
        baseWidth: 40
        baseHeight: 40
        clickedWidth: baseWidth
        clickedHeight: baseHeight + 10
        buttonRadius: Appearance.rounding.normal
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
                top: true
                left: true
                right: root.oskMode === 1  // fullwidth stretches, floating is content-sized
            }
            margins {
                top: root.floatY
                left: root.oskMode === 0 ? root.floatX : 0
            }

            function hide() {
                GlobalStates.oskOpen = false
            }
            exclusiveZone: 0
            implicitWidth: oskBackground.width + Appearance.sizes.elevationMargin * 2
            implicitHeight: oskBackground.height + Appearance.sizes.elevationMargin * 2
            WlrLayershell.namespace: "quickshell:osk"
            WlrLayershell.layer: WlrLayer.Overlay
            // Hyprland 0.49: Focus is always exclusive and setting this breaks mouse focus grab
            // WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            mask: Region {
                item: oskBackground
            }

            // Center keyboard when entering floating mode
            Connections {
                target: root
                function onOskModeChanged() {
                    if (root.oskMode === 0 && oskRoot.screen) {
                        root.floatX = Math.max(0, (oskRoot.screen.width - oskBackground.implicitWidth) / 2)
                        Persistent.states.osk.floatX = root.floatX
                    }
                }
            }

            // Dismiss on click outside
            Component.onCompleted: {
                GlobalFocusGrab.addDismissable(oskRoot);
            }
            Component.onDestruction: {
                GlobalFocusGrab.removeDismissable(oskRoot);
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    oskRoot.hide();
                }
            }

            // Background
            StyledRectangularShadow {
                target: oskBackground
            }
            Rectangle {
                id: oskBackground
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                    width: root.oskMode === 1 ? parent.width : implicitWidth
                    color: Appearance.colors.colLayer0
                    radius: Appearance.rounding.windowRounding
                    property real padding: 10
                    property real dragHandleHeight: 24
                    implicitWidth: oskRowLayout.implicitWidth + padding * 2
                    implicitHeight: oskRowLayout.implicitHeight + dragHandleHeight + padding * 2

                    Keys.onPressed: (event) => { // Esc to close
                        if (event.key === Qt.Key_Escape) {
                            oskRoot.hide()
                        }
                    }

                    // handle
                    Item {
                        id: dragHandle
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: oskBackground.dragHandleHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.topMargin: 2
                            radius: Appearance.rounding.verysmall
                            color: Appearance.colors.colLayer1

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "drag_indicator"
                                iconSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer2
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.OpenHandCursor
                            property real lastY: 0
                            property real lastX: 0

                            onPressed: (mouse) => {
                                lastX = mouse.x
                                lastY = mouse.y
                            }
                            onPositionChanged: (mouse) => {
                                if (pressed) {
                                    if (root.oskMode === 0) {
                                        root.floatX = Math.max(0, root.floatX + (mouse.x - lastX))
                                        lastX = mouse.x
                                    }
                                    root.floatY = Math.max(0, root.floatY + (mouse.y - lastY))
                                    lastY = mouse.y
                                }
                            }
                            onReleased: {
                                Persistent.states.osk.floatX = root.floatX
                                Persistent.states.osk.floatY = root.floatY
                            }
                        }
                    }

                    RowLayout {
                        id: oskRowLayout
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: oskBackground.dragHandleHeight / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: root.oskMode === 1 ? parent.width - 2 * oskBackground.padding : implicitWidth
                        spacing: 5
                        VerticalButtonGroup {
                            OskControlButton { // Mode cycle button
                                toggled: root.oskMode === 1
                                downAction: () => {
                                    root.oskMode = (root.oskMode + 1) % 2
                                    Persistent.states.osk.mode = root.oskMode
                                }
                                contentItem: MaterialSymbol {
                                    text: ["open_in_full", "width_full"][root.oskMode]
                                    horizontalAlignment: Text.AlignHCenter
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: root.oskMode === 0 ? Appearance.colors.colOnLayer0 : Appearance.m3colors.m3onPrimary
                                }
                            }
                            OskControlButton {
                                onClicked: () => {
                                    oskRoot.hide()
                                }
                                contentItem: MaterialSymbol {
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "keyboard_hide"
                                    iconSize: Appearance.font.pixelSize.larger
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
                            stretchKeys: root.oskMode === 1
                        }                }
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
