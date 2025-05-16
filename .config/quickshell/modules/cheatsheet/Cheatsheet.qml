import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

Scope { // Scope
    id: root

    Variants { // Window repeater
        id: cheatsheetVariants
        model: Quickshell.screens

        PanelWindow { // Window
            id: cheatsheetRoot
            visible: false
            focusable: true

            property var modelData

            screen: modelData
            exclusiveZone: 0
            implicitWidth: cheatsheetBackground.width + Appearance.sizes.elevationMargin * 2
            implicitHeight: cheatsheetBackground.height + Appearance.sizes.elevationMargin * 2
            WlrLayershell.namespace: "quickshell:cheatsheet"
            // Hyprland 0.49: Focus is always exclusive and setting this breaks mouse focus grab
            // WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            mask: Region {
                item: cheatsheetBackground
            }

            HyprlandFocusGrab { // Click outside to close
                id: grab
                windows: [ cheatsheetRoot ]
                active: false
                onCleared: () => {
                    if (!active) cheatsheetRoot.visible = false
                }
            }

            Connections {
                target: cheatsheetRoot
                function onVisibleChanged() {
                    delayedGrabTimer.start()
                }
            }

            Timer {
                id: delayedGrabTimer
                interval: ConfigOptions.hacks.arbitraryRaceConditionDelay
                repeat: false
                onTriggered: {
                    grab.active = cheatsheetRoot.visible
                }
            }

            // Background
            Rectangle {
                id: cheatsheetBackground
                anchors.centerIn: parent
                color: Appearance.colors.colLayer0
                radius: Appearance.rounding.windowRounding
                property real padding: 30
                implicitWidth: cheatsheetColumnLayout.implicitWidth + padding * 2
                implicitHeight: cheatsheetColumnLayout.implicitHeight + padding * 2

                Keys.onPressed: (event) => { // Esc to close
                    if (event.key === Qt.Key_Escape) {
                        cheatsheetRoot.visible = false
                    }
                }

                Button { // Close button
                    id: closeButton
                    focus: cheatsheetRoot.visible
                    implicitWidth: 40
                    implicitHeight: 40
                    anchors {
                        top: parent.top
                        right: parent.right
                        topMargin: 20
                        rightMargin: 20
                    }

                    PointingHandInteraction {}
                    onClicked: {
                        cheatsheetRoot.visible = false
                    }

                    background: Item {}
                    contentItem: Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.full
                        color: closeButton.pressed ? Appearance.colors.colLayer0Active :
                            closeButton.hovered ? Appearance.colors.colLayer0Hover :
                            Appearance.transparentize(Appearance.colors.colLayer0, 1)
                        
                        Behavior on color {
                            ColorAnimation {
                                duration: Appearance.animation.elementMoveFast.duration
                                easing.type: Appearance.animation.elementMoveFast.type
                                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                            }
                        }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            font.pixelSize: Appearance.font.pixelSize.title
                            text: "close"
                        }
                    }
                }

                ColumnLayout { // Real content
                    id: cheatsheetColumnLayout
                    anchors.centerIn: parent
                    spacing: 20

                    StyledText {
                        id: cheatsheetTitle
                        Layout.alignment: Qt.AlignHCenter
                        font.family: Appearance.font.family.title
                        font.pixelSize: Appearance.font.pixelSize.title
                        text: qsTr("Cheat sheet")
                    }
                    CheatsheetKeybinds {}
                }
            }

            // Shadow
            DropShadow {
                anchors.fill: cheatsheetBackground
                horizontalOffset: 0
                verticalOffset: 2
                radius: Appearance.sizes.elevationMargin
                samples: Appearance.sizes.elevationMargin * 2 + 1 // Ideally should be 2 * radius + 1, see qt docs
                color: Appearance.colors.colShadow
                source: cheatsheetBackground
            }

        }

    }

    IpcHandler {
        target: "cheatsheet"

        function toggle(): void {
            for (let i = 0; i < cheatsheetVariants.instances.length; i++) {
                let panelWindow = cheatsheetVariants.instances[i];
                if (panelWindow.modelData.name == Hyprland.focusedMonitor.name) {
                    panelWindow.visible = !panelWindow.visible;
                    if(panelWindow.visible) Notifications.timeoutAll();
                }
            }
        }

        function close(): void {
            for (let i = 0; i < cheatsheetVariants.instances.length; i++) {
                let panelWindow = cheatsheetVariants.instances[i];
                if (panelWindow.modelData.name == Hyprland.focusedMonitor.name) {
                    panelWindow.visible = false;
                }
            }
        }

        function open(): void {
            for (let i = 0; i < cheatsheetVariants.instances.length; i++) {
                let panelWindow = cheatsheetVariants.instances[i];
                if (panelWindow.modelData.name == Hyprland.focusedMonitor.name) {
                    panelWindow.visible = true;
                    if(panelWindow.visible) Notifications.timeoutAll();
                }
            }
        }
    }

    GlobalShortcut {
        name: "cheatsheetToggle"
        description: "Toggles cheatsheet on press"

        onPressed: {
            for (let i = 0; i < cheatsheetVariants.instances.length; i++) {
                let panelWindow = cheatsheetVariants.instances[i];
                if (panelWindow.modelData.name == Hyprland.focusedMonitor.name) {
                    panelWindow.visible = !panelWindow.visible;
                    if(panelWindow.visible) Notifications.timeoutAll();
                }
            }
        }
    }

    GlobalShortcut {
        name: "cheatsheetOpen"
        description: "Opens cheatsheet on press"

        onPressed: {
            for (let i = 0; i < cheatsheetVariants.instances.length; i++) {
                let panelWindow = cheatsheetVariants.instances[i];
                if (panelWindow.modelData.name == Hyprland.focusedMonitor.name) {
                    panelWindow.visible = true;
                    if(panelWindow.visible) Notifications.timeoutAll();
                }
            }
        }
    }

    GlobalShortcut {
        name: "cheatsheetClose"
        description: "Closes cheatsheet on press"

        onPressed: {
            for (let i = 0; i < cheatsheetVariants.instances.length; i++) {
                let panelWindow = cheatsheetVariants.instances[i];
                if (panelWindow.modelData.name == Hyprland.focusedMonitor.name) {
                    panelWindow.visible = false;
                }
            }
        }
    }

}
