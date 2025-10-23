import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

WindowDialog {
    id: root
    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)

    WindowDialogTitle {
        text: Translation.tr("Eye protection")
    }
    
    WindowDialogSectionHeader {
        text: Translation.tr("Night Light")
    }

    WindowDialogSeparator {
        Layout.topMargin: -22
        Layout.leftMargin: 0
        Layout.rightMargin: 0
    }

    Column {
        id: nightLightColumn
        Layout.topMargin: -16
        Layout.fillWidth: true

        ConfigSwitch {
            anchors {
                left: parent.left
                right: parent.right
            }
            iconSize: Appearance.font.pixelSize.larger
            buttonIcon: "lightbulb"
            text: Translation.tr("Enable now")
            checked: Hyprsunset.active
            onCheckedChanged: {
                Hyprsunset.toggle(checked)
            }
        }

        ConfigSwitch {
            anchors {
                left: parent.left
                right: parent.right
            }
            iconSize: Appearance.font.pixelSize.larger
            buttonIcon: "night_sight_auto"
            text: Translation.tr("Automatic")
            checked: Config.options.light.night.automatic
            onCheckedChanged: {
                Config.options.light.night.automatic = checked;
            }
        }

        WindowDialogSlider {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: 4
                rightMargin: 4
            }
            text: Translation.tr("Intensity")
            from: 6500
            to: 1200
            stopIndicatorValues: [5000, to]
            value: Config.options.light.night.colorTemperature
            onMoved: Config.options.light.night.colorTemperature = value
            tooltipContent: `${Math.round(value)}K`
        }
    }

    WindowDialogSectionHeader {
        text: Translation.tr("Anti-flashbang (experimental)")
    }

    WindowDialogSeparator {
        Layout.topMargin: -22
        Layout.leftMargin: 0
        Layout.rightMargin: 0
    }

    Column {
        id: antiFlashbangColumn
        Layout.topMargin: -16
        Layout.fillWidth: true

        ConfigSwitch {
            anchors {
                left: parent.left
                right: parent.right
            }
            iconSize: Appearance.font.pixelSize.larger
            buttonIcon: "destruction"
            text: Translation.tr("Enable")
            checked: Config.options.light.antiFlashbang.enable
            onCheckedChanged: {
                Config.options.light.antiFlashbang.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Example use case: eroge on one workspace, dark Discord window on another")
            }
        }
    }

    WindowDialogSectionHeader {
        text: Translation.tr("Brightness")
    }

    WindowDialogSeparator {
        Layout.topMargin: -22
        Layout.leftMargin: 0
        Layout.rightMargin: 0
    }

    Column {
        id: brightnessColumn
        Layout.topMargin: -16
        Layout.fillWidth: true
        Layout.fillHeight: true

        WindowDialogSlider {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: 4
                rightMargin: 4
            }
            // text: Translation.tr("Brightness")
            value: root.brightnessMonitor.brightness
            onMoved: root.brightnessMonitor.setBrightness(value)
        }
    }
    
    WindowDialogButtonRow {
        Layout.fillWidth: true

        Item {
            Layout.fillWidth: true
        }

        DialogButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
}
