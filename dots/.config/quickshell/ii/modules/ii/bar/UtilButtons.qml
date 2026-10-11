import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: rowLayout.implicitHeight

    RowLayout {
        id: rowLayout

        spacing: 4
        anchors.centerIn: parent

        Loader {
            active: Config.options.bar.utilButtons.showScreenSnip
            visible: Config.options.bar.utilButtons.showScreenSnip
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "screenshot"]);
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 1
                    text: "screenshot_region"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer2
                }
            }
        }

        Item {
            id: screenRecordContainer
            Layout.alignment: Qt.AlignVCenter
            visible: screenRecordLoader.active
            implicitWidth: screenRecordLoader.implicitWidth
            implicitHeight: screenRecordLoader.implicitHeight

            Loader {
                id: screenRecordLoader
                active: Config.options.bar.utilButtons.showScreenRecord
                visible: Config.options.bar.utilButtons.showScreenRecord
                sourceComponent: CircleUtilButton {
                    onClicked: Quickshell.execDetached([Directories.recordScriptPath])
                    MaterialSymbol {
                        horizontalAlignment: Qt.AlignHCenter
                        fill: 1
                        text: "videocam"
                        iconSize: Appearance.font.pixelSize.large
                        color: Appearance.colors.colOnLayer2
                    }
                }
            }

            Rectangle {
                id: recordBadge
                readonly property var iconItem: screenRecordLoader.item?.content ?? null
                visible: screenRecordLoader.active && Privacy.scriptScreenRecording && iconItem !== null
                x: iconItem ? iconItem.x + iconItem.width / 2 + iconItem.contentWidth / 2 - width : 0
                y: iconItem ? iconItem.y + iconItem.height / 2 + iconItem.contentHeight / 2 - height : 0
                radius: Appearance.rounding.full
                color: Appearance.colors.colError
                z: 1
                implicitWidth: 8
                implicitHeight: 8
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showColorPicker
            visible: Config.options.bar.utilButtons.showColorPicker
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: {
                    Privacy.holdShellCapture(1500);
                    Quickshell.execDetached(["hyprpicker", "-a"]);
                }
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 1
                    text: "colorize"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer2
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showKeyboardToggle
            visible: Config.options.bar.utilButtons.showKeyboardToggle
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: GlobalStates.oskOpen = !GlobalStates.oskOpen
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 0
                    text: "keyboard"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer2
                }
            }
        }

        Item {
            id: micContainer
            Layout.alignment: Qt.AlignVCenter
            visible: micLoader.active
            implicitWidth: micLoader.implicitWidth
            implicitHeight: micLoader.implicitHeight

            Loader {
                id: micLoader
                active: Config.options.bar.utilButtons.showMicToggle
                visible: Config.options.bar.utilButtons.showMicToggle
                sourceComponent: CircleUtilButton {
                    onClicked: Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_SOURCE@", "toggle"])
                    MaterialSymbol {
                        horizontalAlignment: Qt.AlignHCenter
                        fill: 0
                        text: Pipewire.defaultAudioSource?.audio?.muted ? "mic_off" : "mic"
                        iconSize: Appearance.font.pixelSize.large
                        color: Appearance.colors.colOnLayer2
                    }
                }
            }

            Rectangle {
                id: micBadge
                readonly property var iconItem: micLoader.item?.content ?? null
                visible: micLoader.active && Privacy.micIndicatorVisible && iconItem !== null
                x: iconItem ? iconItem.x + iconItem.width / 2 + iconItem.contentWidth / 2 - width : 0
                y: iconItem ? iconItem.y + iconItem.height / 2 + iconItem.contentHeight / 2 - height : 0
                radius: Appearance.rounding.full
                color: Appearance.colors.colError
                z: 1
                implicitWidth: 8
                implicitHeight: 8
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showDarkModeToggle
            visible: Config.options.bar.utilButtons.showDarkModeToggle
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: event => {
                    if (Appearance.m3colors.darkmode) {
                        Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --mode light --noswitch`])
                    } else {
                        Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --mode dark --noswitch`])
                    }
                }
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 0
                    text: Appearance.m3colors.darkmode ? "light_mode" : "dark_mode"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer2
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showPerformanceProfileToggle
            visible: Config.options.bar.utilButtons.showPerformanceProfileToggle
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: event => {
                    if (PowerProfiles.hasPerformanceProfile) {
                        switch(PowerProfiles.profile) {
                            case PowerProfile.PowerSaver: PowerProfiles.profile = PowerProfile.Balanced
                            break;
                            case PowerProfile.Balanced: PowerProfiles.profile = PowerProfile.Performance
                            break;
                            case PowerProfile.Performance: PowerProfiles.profile = PowerProfile.PowerSaver
                            break;
                        }
                    } else {
                        PowerProfiles.profile = PowerProfiles.profile == PowerProfile.Balanced ? PowerProfile.PowerSaver : PowerProfile.Balanced
                    }
                }
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 0
                    text: switch(PowerProfiles.profile) {
                        case PowerProfile.PowerSaver: return "energy_savings_leaf"
                        case PowerProfile.Balanced: return "airwave"
                        case PowerProfile.Performance: return "local_fire_department"
                    }
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer2
                }
            }
        }
    }
}
