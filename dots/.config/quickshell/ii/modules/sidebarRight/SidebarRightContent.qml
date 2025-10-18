import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland

import "./quickToggles/"
import "./quickToggles/classicStyle/"
import "./wifiNetworks/"
import "./bluetoothDevices/"

Item {
    id: root
    property int sidebarWidth: Appearance.sizes.sidebarWidth
    property int sidebarPadding: 12
    property string settingsQmlPath: Quickshell.shellPath("settings.qml")
    property bool showWifiDialog: false
    property bool showBluetoothDialog: false
    property bool editMode: false

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

            SystemButtonRow {
                Layout.fillHeight: false
                Layout.margins: 10
                Layout.topMargin: 5
                Layout.bottomMargin: 0
            }

            Loader {
                id: slidersLoader
                Layout.fillWidth: true
                visible: active
                active: {
                    const configQuickSliders = Config.options.sidebar.quickSliders
                    if (!configQuickSliders.enable) return false
                    if (!configQuickSliders.showMic && !configQuickSliders.showVolume && !configQuickSliders.showBrightness) return false;
                    return true;
                }
                sourceComponent: QuickSliders {}
            }

            LoaderedQuickPanelImplementation {
                styleName: "classic"
                sourceComponent: ClassicQuickPanel {}
            }

            LoaderedQuickPanelImplementation {
                styleName: "android"
                sourceComponent: AndroidQuickPanel {
                    editMode: root.editMode
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

    onShowWifiDialogChanged: if (showWifiDialog) wifiDialogLoader.active = true;
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

    component LoaderedQuickPanelImplementation: Loader {
        id: quickPanelImplLoader
        required property string styleName
        Layout.alignment: item?.Layout.alignment ?? Qt.AlignHCenter
        Layout.fillWidth: item?.Layout.fillWidth ?? false
        visible: active
        active: Config.options.sidebar.quickToggles.style === styleName
        Connections {
            target: quickPanelImplLoader.item
            function onOpenWifiDialog() {
                Network.enableWifi();
                Network.rescanWifi();
                root.showWifiDialog = true;
            }
            function onOpenBluetoothDialog() {
                Bluetooth.defaultAdapter.enabled = true;
                Bluetooth.defaultAdapter.discovering = true;
                root.showBluetoothDialog = true;
            }
        }
    }

    component SystemButtonRow: RowLayout {
        spacing: 10

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
                toggled: root.editMode
                visible: Config.options.sidebar.quickToggles.style === "android"
                buttonIcon: "edit"
                onClicked: root.editMode = !root.editMode
                StyledToolTip {
                    text: Translation.tr("Edit quick toggles") + (root.editMode ? Translation.tr("\nLMB to enable/disable\nRMB to toggle size\nScroll to swap position") : "")
                }
            }
            QuickToggleButton {
                toggled: false
                buttonIcon: "restart_alt"
                onClicked: {
                    Hyprland.dispatch("reload");
                    Quickshell.reload(true);
                }
                StyledToolTip {
                    text: Translation.tr("Reload Hyprland & Quickshell")
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
                    text: Translation.tr("Settings")
                }
            }
            QuickToggleButton {
                toggled: false
                buttonIcon: "power_settings_new"
                onClicked: {
                    GlobalStates.sessionOpen = true;
                }
                StyledToolTip {
                    text: Translation.tr("Session")
                }
            }
        }
    }
}
