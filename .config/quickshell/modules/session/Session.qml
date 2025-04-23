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

            width: modelData.width
            height: modelData.height

            HyprlandFocusGrab {
                id: grab
                windows: [ sessionRoot ]
                active: false
                onCleared: () => {
                    if (!active) sessionRoot.visible = false
                }
            }

            Connections {
                target: sessionRoot
                function onVisibleChanged() {
                    delayedGrabTimer.start()
                }
            }

            Timer {
                id: delayedGrabTimer
                interval: ConfigOptions.hacks.arbitraryRaceConditionDelay
                repeat: false
                onTriggered: {
                    grab.active = sessionRoot.visible
                }
            }

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
                        text: "Session"
                    }

                    StyledText { // Small instruction
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        font.family: Appearance.font.family.title
                        font.pixelSize: Appearance.font.pixelSize.normal
                        text: "Arrow keys to navigate, Enter to select\nEsc or click anywhere to cancel"
                    }
                }

                RowLayout { // First row of buttons
                    spacing: 15
                    SessionActionButton {
                        id: sessionLock
                        focus: sessionRoot.visible
                        buttonIcon: "lock"
                        buttonText: "Lock"
                        onClicked:  { lock.running = true; sessionRoot.visible = false }
                        onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                        KeyNavigation.right: sessionSleep
                        KeyNavigation.down: sessionHibernate
                    }
                    SessionActionButton {
                        id: sessionSleep
                        focus: sessionRoot.visible
                        buttonIcon: "dark_mode"
                        buttonText: "Sleep"
                        onClicked:  { sleep.running = true; sessionRoot.visible = false }
                        onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                        KeyNavigation.left: sessionLock
                        KeyNavigation.right: sessionLogout
                        KeyNavigation.down: sessionShutdown
                    }
                    SessionActionButton {
                        id: sessionLogout
                        focus: sessionRoot.visible
                        buttonIcon: "logout"
                        buttonText: "Logout"
                        onClicked: { logout.running = true; sessionRoot.visible = false }
                        onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                        KeyNavigation.left: sessionSleep
                        KeyNavigation.right: sessionTaskManager
                        KeyNavigation.down: sessionReboot
                    }
                    SessionActionButton {
                        id: sessionTaskManager
                        focus: sessionRoot.visible
                        buttonIcon: "browse_activity"
                        buttonText: "Task Manager"
                        onClicked:  { taskManager.running = true; sessionRoot.visible = false }
                        onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                        KeyNavigation.left: sessionLogout
                        KeyNavigation.down: sessionFirmwareReboot
                    }
                }

                RowLayout { // Second row of buttons
                    spacing: 15
                    SessionActionButton {
                        id: sessionHibernate
                        focus: sessionRoot.visible
                        buttonIcon: "downloading"
                        buttonText: "Hibernate"
                        onClicked:  { hibernate.running = true; sessionRoot.visible = false }
                        onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                        KeyNavigation.up: sessionLock
                        KeyNavigation.right: sessionShutdown
                    }
                    SessionActionButton {
                        id: sessionShutdown
                        focus: sessionRoot.visible
                        buttonIcon: "power_settings_new"
                        buttonText: "Shutdown"
                        onClicked:  { shutdown.running = true; sessionRoot.visible = false }
                        onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                        KeyNavigation.left: sessionHibernate
                        KeyNavigation.right: sessionReboot
                        KeyNavigation.up: sessionSleep
                    }
                    SessionActionButton {
                        id: sessionReboot
                        focus: sessionRoot.visible
                        buttonIcon: "restart_alt"
                        buttonText: "Reboot"
                        onClicked:  { reboot.running = true; sessionRoot.visible = false }
                        onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                        KeyNavigation.left: sessionShutdown
                        KeyNavigation.right: sessionFirmwareReboot
                        KeyNavigation.up: sessionLogout
                    }
                    SessionActionButton {
                        id: sessionFirmwareReboot
                        focus: sessionRoot.visible
                        buttonIcon: "settings_applications"
                        buttonText: "Reboot to firmware settings"
                        onClicked:  { firmwareReboot.running = true; sessionRoot.visible = false }
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
                            velocity: Appearance.animation.elementDecelFast.velocity
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

    Process {
        id: lock
        command: ["bash", "-c", "loginctl lock-session"]
    }
    Process {
        id: sleep
        command: ["bash", "-c", "systemctl suspend || loginctl suspend"]
    }
    Process {
        id: logout
        command: ["bash", "-c", "loginctl terminate-session $XDG_SESSION_ID"]
    }
    Process {
        id: hibernate
        command: ["bash", "-c", "systemctl hibernate || loginctl hibernate"]
    }
    Process {
        id: shutdown
        command: ["bash", "-c", "systemctl poweroff || loginctl poweroff"]
    }
    Process {
        id: reboot
        command: ["bash", "-c", "systemctl reboot || loginctl reboot"]
    }
    Process {
        id: firmwareReboot
        command: ["bash", "-c", "systemctl reboot --firmware-setup || loginctl reboot --firmware-setup"]
    }
    Process {
        id: taskManager
        command: ["bash", "-c", "gnome-system-monitor & disown"]
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

}
