import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * Display & Monitor settings.
 * Uses hyprctl for monitor info and wlr-randr for resolution/refresh.
 */
ContentPage {
    forceWidth: true

    Process {
        id: monitorsProc
        command: ["hyprctl", "-j", "monitors"]
        running: true
        property var monitorData: []
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    monitorsProc.monitorData = JSON.parse(text)
                } catch(e) {
                    monitorsProc.monitorData = []
                }
            }
        }
    }

    ContentSection {
        icon: "monitor"
        title: Translation.tr("Monitors")

        Repeater {
            model: monitorsProc.monitorData
            delegate: Item {
                required property var modelData
                implicitHeight: monitorCol.implicitHeight + 16
                Layout.fillWidth: true

                ColumnLayout {
                    id: monitorCol
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 8 }
                    spacing: 6

                    RowLayout {
                        MaterialSymbol { text: "monitor"; iconSize: 18; color: Appearance.colors.colPrimary }
                        StyledText {
                            text: modelData.name + " — " + modelData.currentFormat
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer0
                            Layout.fillWidth: true
                        }
                        Rectangle {
                            radius: Appearance.rounding.full
                            color: modelData.focused ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2
                            implicitWidth: activeLabel.implicitWidth + 14; implicitHeight: 22
                            StyledText {
                                id: activeLabel
                                anchors.centerIn: parent
                                text: modelData.focused ? Translation.tr("Focused") : Translation.tr("Active")
                                font.pixelSize: Appearance.font.pixelSize.smallie
                                color: modelData.focused ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                            }
                        }
                    }

                    ConfigRow {
                        uniform: true
                        ConfigSpinBox {
                            icon: "refresh"
                            text: Translation.tr("Scale (%)")
                            value: Math.round(modelData.scale * 100)
                            from: 50; to: 300; stepSize: 25
                            onValueChanged: {
                                Quickshell.execDetached(["hyprctl", "keyword", "monitor",
                                    modelData.name + ",preferred,auto," + (value / 100).toFixed(2)])
                            }
                        }
                        ConfigSpinBox {
                            icon: "brightness_6"
                            text: Translation.tr("Brightness (%)")
                            value: {
                                const mon = Brightness.monitors.find(m => m.screen.name === modelData.name)
                                return mon ? Math.round(mon.brightness * 100) : 100
                            }
                            from: 1; to: 100; stepSize: 5
                            onValueChanged: {
                                const mon = Brightness.monitors.find(m => m.screen.name === modelData.name)
                                if (mon) mon.setBrightness(value / 100)
                            }
                        }
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "wallpaper_slideshow"
        title: Translation.tr("Compositor")

        ConfigSwitch {
            buttonIcon: "motion_blur"
            text: Translation.tr("Enable animations")
            checked: true
            onCheckedChanged: {
                Quickshell.execDetached(["hyprctl", "keyword", "animations:enabled", checked ? "yes" : "no"])
            }
            StyledToolTip { text: Translation.tr("Toggle Hyprland window animations") }
        }
        ConfigSwitch {
            buttonIcon: "blur_on"
            text: Translation.tr("Enable blur")
            checked: true
            onCheckedChanged: {
                Quickshell.execDetached(["hyprctl", "keyword", "decoration:blur:enabled", checked ? "yes" : "no"])
            }
        }
        ConfigSwitch {
            buttonIcon: "shadow"
            text: Translation.tr("Enable shadows")
            checked: true
            onCheckedChanged: {
                Quickshell.execDetached(["hyprctl", "keyword", "decoration:shadow:enabled", checked ? "yes" : "no"])
            }
        }
    }

    ContentSection {
        icon: "nights_stay"
        title: Translation.tr("Night Light")

        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Automatic (sunset/sunrise)")
            checked: Config.options.light.night.automatic
            onCheckedChanged: { Config.options.light.night.automatic = checked }
        }

        ConfigRow {
            enabled: Config.options.light.night.automatic
            uniform: true
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("From (HH:MM)")
                text: Config.options.light.night.from
                onTextChanged: { Qt.callLater(() => { Config.options.light.night.from = text }) }
            }
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("To (HH:MM)")
                text: Config.options.light.night.to
                onTextChanged: { Qt.callLater(() => { Config.options.light.night.to = text }) }
            }
        }

        ConfigSpinBox {
            icon: "thermostat"
            text: Translation.tr("Color temperature (K)")
            value: Config.options.light.night.colorTemperature
            from: 1000; to: 6500; stepSize: 100
            onValueChanged: { Config.options.light.night.colorTemperature = value }
        }
    }
}
