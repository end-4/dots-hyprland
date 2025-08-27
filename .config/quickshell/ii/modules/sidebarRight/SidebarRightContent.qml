import qs
import qs.services
import qs.services.network
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import "./quickToggles/"
import "./wifiNetworks/"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    property int sidebarWidth: Appearance.sizes.sidebarWidth
    property int sidebarPadding: 12
    property string settingsQmlPath: Quickshell.shellPath("settings.qml")
    property bool showDialog: false
    property bool dialogIsWifi: true

    Connections {
        target: GlobalStates
        function onSidebarRightOpenChanged() {
            if (!GlobalStates.sidebarRightOpen) {
                root.showDialog = false
            }
        }
    }

    implicitHeight: sidebarRightBackground.implicitHeight
    implicitWidth: sidebarRightBackground.implicitWidth

    StyledRectangularShadow {
        target: sidebarRightBackground
    }
    Rectangle {
        id: sidebarRightBackground

        anchors.fill: parent
        implicitHeight: parent.height - Appearance.sizes.hyprlandGapsOut * 2
        implicitWidth: sidebarWidth - Appearance.sizes.hyprlandGapsOut * 2
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: sidebarPadding
            spacing: sidebarPadding

            RowLayout {
                Layout.fillHeight: false
                spacing: 10
                Layout.margins: 10
                Layout.topMargin: 5
                Layout.bottomMargin: 0

                CustomIcon {
                    id: distroIcon
                    width: 25
                    height: 25
                    source: SystemInfo.distroIcon
                    colorize: true
                    color: Appearance.colors.colOnLayer0
                }

                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer0
                    text: Translation.tr("Up %1").arg(DateTime.uptime)
                    textFormat: Text.MarkdownText
                }

                Item {
                    Layout.fillWidth: true
                }

                ButtonGroup {
                    QuickToggleButton {
                        toggled: false
                        buttonIcon: "restart_alt"
                        onClicked: {
                            Hyprland.dispatch("reload")
                            Quickshell.reload(true)
                        }
                        StyledToolTip {
                            content: Translation.tr("Reload Hyprland & Quickshell")
                        }
                    }
                    QuickToggleButton {
                        toggled: false
                        buttonIcon: "settings"
                        onClicked: {
                            GlobalStates.sidebarRightOpen = false
                            Quickshell.execDetached(["qs", "-p", root.settingsQmlPath])
                        }
                        StyledToolTip {
                            content: Translation.tr("Settings")
                        }
                    }
                    QuickToggleButton {
                        toggled: false
                        buttonIcon: "power_settings_new"
                        onClicked: {
                            GlobalStates.sessionOpen = true
                        }
                        StyledToolTip {
                            content: Translation.tr("Session")
                        }
                    }
                }
            }

            ButtonGroup {
                Layout.alignment: Qt.AlignHCenter
                spacing: 5
                padding: 5
                color: Appearance.colors.colLayer1

                NetworkToggle {
                    altAction: () => {
                        Network.enableWifi()
                        Network.rescanWifi()
                        root.dialogIsWifi = true
                        root.showDialog = true
                    }
                }
                BluetoothToggle {}
                NightLight {}
                GameMode {}
                IdleInhibitor {}
                EasyEffectsToggle {}
                CloudflareWarp {}
            }

            CenterWidgetGroup {
                focus: sidebarRoot.visible
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            BottomWidgetGroup {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: false
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
            }
        }
    }

    WindowDialog {
        show: root.showDialog
        onDismiss: root.showDialog = false
        anchors {
            fill: parent
        }
        
        WindowDialogTitle {
            text: Translation.tr("Connect to Wi-Fi")
        }
        WindowDialogSeparator {
            // TODO: add indeterminate progress bar when scanning
        }
        StyledListView {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.topMargin: -15
            Layout.bottomMargin: -16
            Layout.leftMargin: -Appearance.rounding.large
            Layout.rightMargin: -Appearance.rounding.large
            
            clip: true
            spacing: 0
            animateAppearance: false

            model: ScriptModel {
                values: [...Network.wifiNetworks].sort((a, b) => {
                    if (a.active && !b.active) return -1;
                    if (!a.active && b.active) return 1;
                    return b.strength - a.strength;
                })
            }
            // model: Network.wifiNetworks
            delegate: WifiNetworkItem {
                required property WifiAccessPoint modelData
                wifiNetwork: modelData
                anchors {
                    left: parent?.left
                    right: parent?.right
                }
            }
        }
        WindowDialogSeparator {}
        WindowDialogButtonRow {
            DialogButton {
                buttonText: Translation.tr("Details")
                onClicked: {
                    Quickshell.execDetached(["bash", "-c", `${Network.ethernet ? Config.options.apps.networkEthernet : Config.options.apps.network}`])
                    GlobalStates.sidebarRightOpen = false
                }
            }

            Item {
                Layout.fillWidth: true
            }

            DialogButton {
                buttonText: Translation.tr("Done")
                onClicked: root.showDialog = false
            }
        }
    }
}
