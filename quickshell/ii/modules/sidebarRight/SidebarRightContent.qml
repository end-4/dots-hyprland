import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "./quickToggles/"
import "./quickPanel/"
import "./wifiNetworks/"
import "./bluetoothDevices/"
import "./quickPanel/"
import "./quickPanel/services/"
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

    property bool showWifiDialog: DialogContext.showWifiDialog
    property bool showBluetoothDialog: DialogContext.showBluetoothDialog // Bind to singleton


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
        // implicitHeight: parent.height - Appearance.sizes.hyprlandGapsOut * 2
        implicitHeight:parent.height
        // implicitWidth: sidebarWidth - Appearance.sizes.hyprlandGapsOut * 2
        implicitWidth:  sidebarWidth
        color: Appearance.colors.colLayer0
        // border.width: 1
        // border.color: Appearance.colors.colLayer0Border
        // radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1
        radius:0

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: sidebarPadding
            spacing: sidebarPadding

            RowLayout {
                Layout.fillHeight: false
                spacing: 10
                Layout.margins: 10
                Layout.topMargin: 5
                Layout.bottomMargin: 16

                CustomIcon {
                    id: distroIcon
                    width: 24
                    height: 24
                    source: SystemInfo.distroIcon
                    colorize: true
                    color: Appearance.m3colors.m3onSurface
                }
      ColumnLayout {
          Layout.topMargin:12
          spacing: -1
          StyledText {
              font.pixelSize: Appearance.font.pixelSize.large
              font.family: Appearance.font.family.expressive
              color: Appearance.colors.colOnLayer0
              text: Translation.tr("%1").arg(SystemInfo?.username ?? SystemInfo.distroName)
              textFormat: Text.MarkdownText
          }
          StyledText {
              font.pixelSize: Appearance.font.pixelSize.small
              font.family: Appearance.font.family.expressive
              color: Appearance.colors.colOutline
              text: Translation.tr("up %1").arg(DateTime.uptime)
              textFormat: Text.MarkdownText
          }

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
                source : Config?.options.quickToggle.style === 0 ? "AndroidPanel.qml" : "ClassicPanel.qml"
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

        // GlobalStates.showWifiDialog = root.showWifiDialog // Sync changes
        if (DialogContext.showWifiDialog) wifiDialogLoader.active = true;
    }
    Loader {
        id: wifiDialogLoader
        anchors.fill: parent

        active: DialogContext.showWifiDialog || item.visible
        onActiveChanged: {
            if (active) {
                item.show = true;
                item.forceActiveFocus();
            }
        }

        sourceComponent: WifiDialog {
            onDismiss: {
                show = false
                DialogContext.showWifiDialog = false
            }
            onVisibleChanged: {
                if (!visible && !DialogContext.showWifiDialog) wifiDialogLoader.active = false;
            }
        }
    }

    onShowBluetoothDialogChanged: {
        if (showBluetoothDialog) bluetoothDialogLoader.active = true;
        else Bluetooth.defaultAdapter.discovering = false;
    }
    Loader {
        id: bluetoothDialogLoader
        anchors.fill: parent

        active: DialogContext.showBluetoothDialog || item.visible
        onActiveChanged: {
            if (active) {
                item.show = true;
                item.forceActiveFocus();
            }
        }

        sourceComponent: BluetoothDialog {
            onDismiss: {
                show = false
                DialogContext.showBluetoothDialog = false
            }
            onVisibleChanged: {
                if (!visible && !DialogContext.showBluetoothDialog) bluetoothDialogLoader.active = false;
            }
        }
    }
}
