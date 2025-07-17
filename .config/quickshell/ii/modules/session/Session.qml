import qs.modules.common
import qs
import qs.services
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)

    Loader {
        id: sessionLoader
        active: false

        sourceComponent: PanelWindow { // Session menu
            id: sessionRoot
            visible: sessionLoader.active
            property string subtitle
            
            function hide() {
                sessionLoader.active = false
            }
    

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:session"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: ColorUtils.transparentize(Appearance.m3colors.m3background, 0.3)

            anchors {
                top: true
                left: true
                right: true
            }

            implicitWidth: root.focusedScreen?.width ?? 0
            implicitHeight: root.focusedScreen?.height ?? 0

            MouseArea {
                id: sessionMouseArea
                anchors.fill: parent
                onClicked: {
                    sessionRoot.hide()
                }
            }

            ColumnLayout { // Content column
                anchors.centerIn: parent
                spacing: 15

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        sessionRoot.hide();
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
                        text: Translation.tr("Session")
                    }

                    StyledText { // Small instruction
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.normal
                        text: Translation.tr("Arrow keys to navigate, Enter to select\nEsc or click anywhere to cancel")
                    }
                }

                GridLayout {
                    columns: 4
                    columnSpacing: 15
                    rowSpacing: 15

                    SessionActionButton {
                        id: sessionLock
                        focus: sessionRoot.visible
                        buttonIcon: "lock"
                        buttonText: Translation.tr("Lock")
                        onClicked:  { Quickshell.execDetached(["loginctl", "lock-session"]); sessionRoot.hide() }
                        onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                        KeyNavigation.right: sessionSleep
                        KeyNavigation.down: sessionHibernate
                    }
                    SessionActionButton {
                        id: sessionSleep
                        buttonIcon: "dark_mode"
                        buttonText: Translation.tr("Sleep")
                        onClicked:  { Quickshell.execDetached(["bash", "-c", "systemctl suspend || loginctl suspend"]); sessionRoot.hide() }
                        onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                        KeyNavigation.left: sessionLock
                        KeyNavigation.right: sessionLogout
                        KeyNavigation.down: sessionShutdown
                    }
                    SessionActionButton {
                        id: sessionLogout
                        buttonIcon: "logout"
                        buttonText: Translation.tr("Logout")
                        onClicked: { Quickshell.execDetached(["pkill", "Hyprland"]); sessionRoot.hide() }
                        onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                        KeyNavigation.left: sessionSleep
                        KeyNavigation.right: sessionTaskManager
                        KeyNavigation.down: sessionReboot
                    }
                    SessionActionButton {
                        id: sessionTaskManager
                        buttonIcon: "browse_activity"
                        buttonText: Translation.tr("Task Manager")
                        onClicked:  { Quickshell.execDetached(["bash", "-c", `${Config.options.apps.taskManager}`]); sessionRoot.hide() }
                        onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                        KeyNavigation.left: sessionLogout
                        KeyNavigation.down: sessionFirmwareReboot
                    }

                    SessionActionButton {
                        id: sessionHibernate
                        buttonIcon: "downloading"
                        buttonText: Translation.tr("Hibernate")
                        onClicked:  { Quickshell.execDetached(["bash", "-c", `systemctl hibernate || loginctl hibernate`]); sessionRoot.hide() }
                        onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                        KeyNavigation.up: sessionLock
                        KeyNavigation.right: sessionShutdown
                    }
                    SessionActionButton {
                        id: sessionShutdown
                        buttonIcon: "power_settings_new"
                        buttonText: Translation.tr("Shutdown")
                        onClicked:  { Quickshell.execDetached(["bash", "-c", `systemctl poweroff || loginctl poweroff`]); sessionRoot.hide() }
                        onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                        KeyNavigation.left: sessionHibernate
                        KeyNavigation.right: sessionReboot
                        KeyNavigation.up: sessionSleep
                    }
                    SessionActionButton {
                        id: sessionReboot
                        buttonIcon: "restart_alt"
                        buttonText: Translation.tr("Reboot")
                        onClicked:  { Quickshell.execDetached(["bash", "-c", `reboot || loginctl reboot`]); sessionRoot.hide() }
                        onFocusChanged: { if (focus) sessionRoot.subtitle = buttonText }
                        KeyNavigation.left: sessionShutdown
                        KeyNavigation.right: sessionFirmwareReboot
                        KeyNavigation.up: sessionLogout
                    }
                    SessionActionButton {
                        id: sessionFirmwareReboot
                        buttonIcon: "settings_applications"
                        buttonText: Translation.tr("Reboot to firmware settings")
                        onClicked:  { Quickshell.execDetached(["bash", "-c", `systemctl reboot --firmware-setup || loginctl reboot --firmware-setup`]); sessionRoot.hide() }
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
                        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
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
            sessionLoader.active = !sessionLoader.active;
        }

        function close(): void {
            sessionLoader.active = false;
        }

        function open(): void {
            sessionLoader.active = true;
        }
    }

    GlobalShortcut {
        name: "sessionToggle"
        description: "Toggles session screen on press"

        onPressed: {
            sessionLoader.active = !sessionLoader.active;
        }
    }

    GlobalShortcut {
        name: "sessionOpen"
        description: "Opens session screen on press"

        onPressed: {
            sessionLoader.active = true;
        }
    }

}
