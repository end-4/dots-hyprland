import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "./quickToggles/"
import "./wifiNetworks/"
import "./bluetoothDevices/"
import "./"
import "./quickPanel/"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland

Item {
    id: root
    property int sidebarWidth: Appearance.sizes.sidebarWidth
    property int sidebarPadding: 12
    property string settingsQmlPath: Quickshell.shellPath("settings.qml")
    property bool showWifiDialog: WifiDialogContext.showWifiDialog
    property bool showBluetoothDialog: BluetoothDialogContext.showBluetoothDialog

    Connections {
        target: GlobalStates
        function onSidebarRightOpenChanged() {
            if (!GlobalStates.sidebarRightOpen) {
                WifiDialogContext.showWifiDialog = false;
                BluetoothDialog.showBluetoothDialog = false;
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
                            Hyprland.dispatch("reload");
                            Quickshell.reload(true);
                        }
                        StyledToolTip {
                            content: Translation.tr("Reload Hyprland & Quickshell")
                        }
                    }
                    QuickToggleButton {
                        toggled: false
                        buttonIcon: "settings"
                        onClicked: {
                            GlobalStates.sidebarRightOpen = false;
                            Quickshell.execDetached(["qs", "-p", root.settingsQmlPath]);
                        }
                        StyledToolTip {
                            content: Translation.tr("Settings")
                        }
                    }
                    QuickToggleButton {
                        toggled: false
                        buttonIcon: "power_settings_new"
                        onClicked: {
                            GlobalStates.sessionOpen = true;
                        }
                        StyledToolTip {
                            content: Translation.tr("Session")
                        }
                    }
                }
            }

            Loader {
                Layout.alignment: Qt.AlignHCenter
                sourceComponent: Config?.options.quickToggle.style === 0 ?  classicPanel : androidPanel
            }

            Component {
                id: classicPanel
                ButtonGroup {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 5
                    padding: 5
                    color: Appearance.colors.colLayer1

                    NetworkToggle {
                        altAction: () => {
                            Network.enableWifi();
                            Network.rescanWifi();
                            WifiDialogContext.showWifiDialog = true;
                        }
                    }
                    BluetoothToggle {
                        altAction: () => {
                            Bluetooth.defaultAdapter.enabled = true;
                            Bluetooth.defaultAdapter.discovering = true;
                            BluetoothDialogContext.showBluetoothDialog = true;
                        }
                    }
                    NightLight {}
                    GameMode {}
                    IdleInhibitor {}
                    EasyEffectsToggle {}
                    CloudflareWarp {}
                } }

            Component {
                id: androidPanel
                QuickPanel {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: false
                    Layout.fillHeight: false
                    Layout.preferredHeight: implicitHeight
                }

            }


            CenterWidgetGroup {
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

    onShowWifiDialogChanged: () => {
        if (WifiDialogContext.showWifiDialog) wifiDialogLoader.active = true;
    }

    Loader {
        id: wifiDialogLoader
        anchors.fill: parent
        active: WifiDialogContext.showWifiDialog || item.visible
        onActiveChanged: {
            if (active) {
                item.show = true;
                item.forceActiveFocus();
            }
        }

        sourceComponent: WifiDialog {
            onDismiss: {
                show = false
                WifiDialogContext.showWifiDialog = false
            }
            onVisibleChanged: {
                if (!visible && !WifiDialogContext.showWifiDialog) wifiDialogLoader.active = false;
            }
        }
    }

    onShowBluetoothDialogChanged:() => {
        if (BluetoothDialogContext.showBluetoothDialog) bluetoothDialogLoader.active = true;
        else Bluetooth.defaultAdapter.discovering = false;
    }
    Loader {
        id: bluetoothDialogLoader
        anchors.fill: parent

        active: BluetoothDialogContext.showBluetoothDialog || item.visible
        onActiveChanged: {
            if (active) {
                item.show = true;
                item.forceActiveFocus();
            }
        }

        sourceComponent: BluetoothDialog {
            onDismiss: {
                show = false
                BluetoothDialogContext.showBluetoothDialog = false
            }
            onVisibleChanged: {
                if (!visible && !BluetoothDialogContext.showBluetoothDialog) bluetoothDialogLoader.active = false;
            }
        }
    }
}
