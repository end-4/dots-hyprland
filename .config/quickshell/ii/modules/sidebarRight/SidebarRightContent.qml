import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "./wifiNetworks/"
import "./bluetoothDevices/"
import "./quickPanel/"
import "./quickPanel/toggles"
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
    property bool showWifiDialog: false
    property bool showBluetoothDialog: false
    property string quickToggles: Config.options.quickToggles.androidStyle.enable ? "android" : "android"
    readonly property var panelUrlMap: ({
            "android": "./quickPanel/AndroidStylePanel.qml",
            "classic": "./quickPanel/ClassicStylePanel.qml"
        })

    Connections {
        target: GlobalStates
        function onSidebarRightOpenChanged() {
            if (!GlobalStates.sidebarRightOpen) {
                root.showWifiDialog = false;
                root.showBluetoothDialog = false;
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
                    QuickToggle {
                        toggleType: 0
                        toggled: false
                        buttonIcon: "restart_alt"
                        onClicked: {
                            Hyprland.dispatch("reload");
                            Quickshell.reload(true);
                        }
                        toolTipText: Translation.tr("Reload Hyprland & Quickshell")
                    }
                    QuickToggle {
                        toggleType: 0
                        toggled: false
                        buttonIcon: "settings"
                        onClicked: {
                            GlobalStates.sidebarRightOpen = false;
                            Quickshell.execDetached(["qs", "-p", root.settingsQmlPath]);
                        }
                        toolTipText: Translation.tr("Settings")
                    }
                    QuickToggle {
                        toggled: false
                        toggleType: 0
                        buttonIcon: "power_settings_new"
                        onClicked: {
                            GlobalStates.sessionOpen = true;
                        }
                        toolTipText: Translation.tr("Session")
                    }
                }
            }

            Loader {
                id: panelLoader
                Layout.alignment: Qt.AlignHCenter
                // Using source to avoid loading the panel in memory which is not used.
                source: panelUrlMap[Config.options.quickToggles.androidStyle.enable ? "android": "classic"]
                Connections {
                    target: panelLoader.item
                    function onShowWifiDialogChanged() {
                        root.showWifiDialog = panelLoader.item.showWifiDialog;
                    }
                    function onShowBluetoothDialogChanged() {
                        root.showBluetoothDialog = panelLoader.item.showBluetoothDialog;
                    }
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

    onShowWifiDialogChanged: {
        if (showWifiDialog) wifiDialogLoader.active = true;
        panelLoader.item.showWifiDialog = root.showWifiDialog;
    }
    Loader {
        id: wifiDialogLoader
        anchors.fill: parent

        active: root.showWifiDialog || item.visible
        onActiveChanged: {
            if (active) {
                item.show = true;
                item.forceActiveFocus();
            }
        }

        sourceComponent: WifiDialog {
            onDismiss: {
                show = false
                root.showWifiDialog = false
            }
            onVisibleChanged: {
                if (!visible && !root.showWifiDialog) wifiDialogLoader.active = false;
            }
        }
    }

    onShowBluetoothDialogChanged: {
        if (showBluetoothDialog) bluetoothDialogLoader.active = true;
        else Bluetooth.defaultAdapter.discovering = false;
        panelLoader.item.showBluetoothDialog = showBluetoothDialog;
    }
    Loader {
        id: bluetoothDialogLoader
        anchors.fill: parent

        active: root.showBluetoothDialog || item.visible
        onActiveChanged: {
            if (active) {
                item.show = true;
                item.forceActiveFocus();
            }
        }

        sourceComponent: BluetoothDialog {
            onDismiss: {
                show = false
                root.showBluetoothDialog = false
            }
            onVisibleChanged: {
                if (!visible && !root.showBluetoothDialog) bluetoothDialogLoader.active = false;
            }
        }
    }
}
