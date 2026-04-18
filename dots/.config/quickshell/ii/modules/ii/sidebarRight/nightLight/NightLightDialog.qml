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
    backgroundHeight: 700

    component MaterialSectionHeader: WindowDialogSectionHeader {
        color: Appearance.colors.colPrimary
        font.pixelSize: Appearance.font.pixelSize.smaller
    }

    component Section: Rectangle {
        id: root
        default property alias content: inner.data

        color: Appearance.colors.colSurfaceContainerHighest
        implicitHeight: inner.implicitHeight + inner.anchors.margins * 2
        width: parent.width
        radius: 12

        Column {
            id: inner
            Layout.fillWidth: true
            anchors.fill: parent
            anchors.margins: 8
        }
    }


    WindowDialogTitle {
        text: Translation.tr("Eye protection")
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Column {
        spacing: 8
        Layout.fillWidth: true
        Layout.fillHeight: true

        MaterialSectionHeader {
            text: Translation.tr("Night Light")
        }

        Section {
            ConfigSwitch {
                anchors {
                    left: parent.left
                    right: parent.right
                }
                iconSize: Appearance.font.pixelSize.larger
                buttonIcon: "lightbulb"
                text: Translation.tr("Enable now")
                checked: Hyprsunset.temperatureActive
                onCheckedChanged: {
                    Hyprsunset.toggleTemperature(checked)
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

        MaterialSectionHeader {
            text: Translation.tr("Anti-flashbang (experimental)")
        }

        Section {
            ConfigSwitch {
                anchors {
                    left: parent.left
                    right: parent.right
                }
                iconSize: Appearance.font.pixelSize.larger
                buttonIcon: "filter"
                text: Translation.tr("Content adjustment")
                checked: HyprlandAntiFlashbangShader.enabled
                onCheckedChanged: {
                    if (checked) HyprlandAntiFlashbangShader.enable()
                    else HyprlandAntiFlashbangShader.disable()
                }
                StyledToolTip {
                    text: Translation.tr("<b>Dims screen content</b> as needed.<br><br>Pros: Immediately responsive<br>Cons: Expensive and can hurt color accuracy<br><br><i>Uses a Hyprland screen shader</i>")
                }
            }

            ConfigSwitch {
                anchors {
                    left: parent.left
                    right: parent.right
                }
                iconSize: Appearance.font.pixelSize.larger
                buttonIcon: "light_mode"
                text: Translation.tr("Brightness adjustment")
                checked: Config.options.light.antiFlashbang.enable
                onCheckedChanged: {
                    Config.options.light.antiFlashbang.enable = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Adapts the <b>display (physical screen) brightness</b><br><br>Pros: Less expensive, retains colors<br>Cons: Not immediately responsive<br><br><i>Adjusts display brightness after each Hyprland IPC event</i>")
                }
            }
        }

        MaterialSectionHeader {
            text: Translation.tr("Brightness")
        }

        Section {
            WindowDialogSlider {
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: 4
                    rightMargin: 4
                }
                value: root.brightnessMonitor.brightness
                onMoved: root.brightnessMonitor.setBrightness(value)
            }
        }

        MaterialSectionHeader {
            text: Translation.tr("Gamma")
        }

        Section {
            WindowDialogSlider {
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: 4
                    rightMargin: 4
                }
                from: Hyprsunset.gammaLowerLimit / 100
                value: Hyprsunset.gamma / 100
                onMoved: Hyprsunset.setGamma(value * 100)
                tooltipContent: `${Math.round(value * 100)}%`
            }
        }
    }
    
    WindowDialogButtonRow {
        Layout.margins: 4
        Layout.fillWidth: true

        Item {
            Layout.fillWidth: true
        }

        DialogButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
            colBackground: Appearance.colors.colPrimary
            colText: Appearance.colors.colOnPrimary
            colBackgroundHover: Appearance.colors.colPrimaryHover
        }
    }
}

