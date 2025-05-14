import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
    id: root
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    Variants {
        id: sessionVariants
        model: Quickshell.screens

        PanelWindow { // Session menu
            id: sessionRoot
            visible: false

            property var modelData
            property string subtitle

            screen: modelData
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:session"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: Appearance.transparentize(Appearance.m3colors.m3background, 0.4)

            anchors {
                top: true
                left: true
                right: true
            }

            implicitWidth: modelData.width
            implicitHeight: modelData.height

            MouseArea {
                id: sessionMouseArea
                anchors.fill: parent
                onClicked: {
                    sessionRoot.visible = false
                }
            }

            ColumnLayout { // Content column
                anchors.centerIn: parent
                spacing: 15

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        sessionRoot.visible = false;
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 0
                    StyledText { // Title
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        font.family: Appearance.font.family.title
                        font.pixelSize: Appearance.font.pixelSize.title
                        font.weight: Font.DemiBold
                        text: qsTr("Session")
                    }

                    StyledText { // Small instruction
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        font.family: Appearance.font.family.title
                        font.pixelSize: Appearance.font.pixelSize.normal
                        text: qsTr("Arrow keys to navigate, Enter to select\nEsc or click anywhere to cancel")
                    }
                }

                RowLayout { // First row of buttons
                    spacing: 15
                    SessionActionButton {
                        id: sessionLock
                        focus: sessionRoot.visible
                        buttonIcon: "lock"
                        buttonText: qsTr("Lock")
                        onClicked:  { Hyprland.dispatch("exec loginctl lock-session"); sessionRoot.visible = false }
                        onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                        KeyNavigation.right: sessionSleep
                        KeyNavigation.down: sessionHibernate
                    }
                    SessionActionButton {
                        id: sessionSleep
                        buttonIcon: "dark_mode"
                        buttonText: qsTr("Sleep")
                        onClicked:  { Hyprland.dispatch("exec systemctl suspend || loginctl suspend"); sessionRoot.visible = false }
                        onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                        KeyNavigation.left: sessionLock
                        KeyNavigation.right: sessionLogout
                        KeyNavigation.down: sessionShutdown
                    }
                    SessionActionButton {
                        id: sessionLogout
                        buttonIcon: "logout"
                        buttonText: qsTr("Logout")
                        onClicked: { Hyprland.dispatch("exec pkill Hyprland"); sessionRoot.visible = false }
                        onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                        KeyNavigation.left: sessionSleep
                        KeyNavigation.right: sessionTaskManager
                        KeyNavigation.down: sessionReboot
                    }
                    SessionActionButton {
                        id: sessionTaskManager
                        buttonIcon: "browse_activity"
                        buttonText: qsTr("Task Manager")
                        onClicked:  { Hyprland.dispatch("exec gnome-system-monitor & disown"); sessionRoot.visible = false }
                        onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                        KeyNavigation.left: sessionLogout
                        KeyNavigation.down: sessionFirmwareReboot
                    }
                }

                RowLayout { // Second row of buttons
                    spacing: 15
                    SessionActionButton {
                        id: sessionHibernate
                        buttonIcon: "downloading"
                        buttonText: qsTr("Hibernate")
                        onClicked:  { Hyprland.dispatch("exec systemctl hibernate || loginctl hibernate"); sessionRoot.visible = false }
                        onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                        KeyNavigation.up: sessionLock
                        KeyNavigation.right: sessionShutdown
                    }
                    SessionActionButton {
                        id: sessionShutdown
                        buttonIcon: "power_settings_new"
                        buttonText: qsTr("Shutdown")
                        onClicked:  { Hyprland.dispatch("exec systemctl poweroff || loginctl poweroff"); sessionRoot.visible = false }
                        onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                        KeyNavigation.left: sessionHibernate
                        KeyNavigation.right: sessionReboot
                        KeyNavigation.up: sessionSleep
                    }
                    SessionActionButton {
                        id: sessionReboot
                        buttonIcon: "restart_alt"
                        buttonText: qsTr("Reboot")
                        onClicked:  { Hyprland.dispatch("exec reboot || loginctl reboot"); sessionRoot.visible = false }
                        onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                        KeyNavigation.left: sessionShutdown
                        KeyNavigation.right: sessionFirmwareReboot
                        KeyNavigation.up: sessionLogout
                    }
                    SessionActionButton {
                        id: sessionFirmwareReboot
                        buttonIcon: "settings_applications"
                        buttonText: qsTr("Reboot to firmware settings")
                        onClicked:  { Hyprland.dispatch("exec systemctl reboot --firmware-setup || loginctl reboot --firmware-setup"); sessionRoot.visible = false }
                        onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                        KeyNavigation.up: sessionTaskManager
                        KeyNavigation.left: sessionReboot
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    radius: Appearance.rounding.normal
                    implicitHeight: sessionSubtitle.implicitHeight + 10 * 2
                    implicitWidth: sessionSubtitle.implicitWidth + 15 * 2
                    color: Appearance.colors.colTooltip
                    clip: true

                    Behavior on implicitWidth {
                        SmoothedAnimation {
                            velocity: Appearance.animation.elementMoveFast.velocity
                        }
                    }

                    StyledText {
                        id: sessionSubtitle
                        anchors.centerIn: parent
                        color: Appearance.colors.colOnTooltip
                        text: sessionRoot.subtitle
                    }
                }
            }

        }

    }

    IpcHandler {
        target: "session"

        function toggle(): void {
            for (let i = 0; i < sessionVariants.instances.length; i++) {
                let panelWindow = sessionVariants.instances[i];
                if (panelWindow.modelData.name == Hyprland.focusedMonitor.name) {
                    panelWindow.visible = !panelWindow.visible;
                }
            }
        }

        function close(): void {
            for (let i = 0; i < sessionVariants.instances.length; i++) {
                let panelWindow = sessionVariants.instances[i];
                if (panelWindow.modelData.name == Hyprland.focusedMonitor.name) {
                    panelWindow.visible = false;
                }
            }
        }

        function open(): void {
            for (let i = 0; i < sessionVariants.instances.length; i++) {
                let panelWindow = sessionVariants.instances[i];
                if (panelWindow.modelData.name == Hyprland.focusedMonitor.name) {
                    panelWindow.visible = true;
                }
            }
        }
    }

    GlobalShortcut {
        name: "sessionToggle"
        description: "Toggles session screen on press"

        onPressed: {
            for (let i = 0; i < sessionVariants.instances.length; i++) {
                let panelWindow = sessionVariants.instances[i];
                if (panelWindow.modelData.name == Hyprland.focusedMonitor.name) {
                    panelWindow.visible = !panelWindow.visible;
                }
            }
        }
    }
    GlobalShortcut {
        name: "sessionOpen"
        description: "Opens session screen on press"

        onPressed: {
            for (let i = 0; i < sessionVariants.instances.length; i++) {
                let panelWindow = sessionVariants.instances[i];
                if (panelWindow.modelData.name == Hyprland.focusedMonitor.name) {
                    panelWindow.visible = true
                }
            }
        }
    }

}
