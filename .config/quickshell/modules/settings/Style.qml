import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "root:/services/"
import "root:/modules/common/"
import "root:/modules/common/widgets/"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import "root:/modules/common/functions/file_utils.js" as FileUtils

ContentPage {
    baseWidth: lightDarkButtonGroup.implicitWidth
    forceWidth: true

    Process {
        id: konachanWallProc
        property string status: ""
        command: ["bash", "-c", FileUtils.trimFileProtocol(`${Directories.config}/quickshell/scripts/colors/random_konachan_wall.sh`)]
        stdout: SplitParser {
            onRead: data => {
                console.log(`Konachan wall proc output: ${data}`);
                konachanWallProc.status = data.trim();
            }
        }
    }

    ContentSection {
        title: "Colors & Wallpaper"

        // Light/Dark mode preference
        ButtonGroup {
            id: lightDarkButtonGroup
            Layout.fillWidth: true
            LightDarkPreferenceButton {
                dark: false
            }
            LightDarkPreferenceButton {
                dark: true
            }
        }

        // Material palette selection
        StyledText {
            text: "Material palette"
            color: Appearance.colors.colSubtext
        }

        ConfigSelectionArray {
            currentValue: ConfigOptions.appearance.palette.type
            configOptionName: "appearance.palette.type"
            onSelected: (newValue) => {
                ConfigLoader.setConfigValueAndSave("appearance.palette.type", newValue);
            }
            options: [
                {"value": "auto", "displayName": "Auto"},
                {"value": "scheme-content", "displayName": "Content"},
                {"value": "scheme-expressive", "displayName": "Expressive"},
                {"value": "scheme-fidelity", "displayName": "Fidelity"},
                {"value": "scheme-fruit-salad", "displayName": "Fruit Salad"},
                {"value": "scheme-monochrome", "displayName": "Monochrome"},
                {"value": "scheme-neutral", "displayName": "Neutral"},
                {"value": "scheme-rainbow", "displayName": "Rainbow"},
                {"value": "scheme-tonal-spot", "displayName": "Tonal Spot"}
            ]
        }

        // Wallpaper selection
        StyledText {
            text: "Wallpaper"
            color: Appearance.colors.colSubtext
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            RippleButtonWithIcon {
                id: rndWallBtn
                Layout.alignment: Qt.AlignHCenter
                buttonRadius: Appearance.rounding.small
                materialIcon: "wallpaper"
                mainText: konachanWallProc.running ? "Be patient..." : "Random: Konachan"
                onClicked: {
                    console.log(konachanWallProc.command.join(" "))
                    konachanWallProc.running = true;
                }
                StyledToolTip {
                    content: "Random SFW Anime wallpaper from Konachan\nImage is saved to ~/Pictures/Wallpapers"
                }
            }
            RippleButtonWithIcon {
                materialIcon: "wallpaper"
                StyledToolTip {
                    content: "Pick wallpaper image on your system"
                }
                onClicked: {
                    Quickshell.execDetached(`${Directories.wallpaperSwitchScriptPath}`)
                }
                mainContentComponent: Component {
                    RowLayout {
                        spacing: 10
                        StyledText {
                            font.pixelSize: Appearance.font.pixelSize.small
                            text: "Choose file"
                            color: Appearance.colors.colOnSecondaryContainer
                        }
                        RowLayout {
                            spacing: 3
                            KeyboardKey {
                                key: "Ctrl"
                            }
                            KeyboardKey {
                                key: "󰖳"
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignVCenter
                                text: "+"
                            }
                            KeyboardKey {
                                key: "T"
                            }
                        }
                    }
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "Change any time later with /dark, /light, /img in the launcher"
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
        }
    
    }

    ContentSection {
        title: "Shell style"

        ColumnLayout { // Fake screen rounding
            StyledText {
                text: "Fake screen rounding"
                color: Appearance.colors.colSubtext
            }
            ButtonGroup {
                id: fakeScreenRoundingButtonGroup
                property int selectedPolicy: ConfigOptions.appearance.fakeScreenRounding
                spacing: 2
                SelectionGroupButton {
                    property int value: 0
                    leftmost: true
                    buttonText: "No"
                    toggled: (fakeScreenRoundingButtonGroup.selectedPolicy === value)
                    onClicked: {
                        ConfigLoader.setConfigValueAndSave("appearance.fakeScreenRounding", value);
                    }
                }
                SelectionGroupButton {
                    property int value: 1
                    buttonText: "Yes"
                    toggled: (fakeScreenRoundingButtonGroup.selectedPolicy === value)
                    onClicked: {
                        ConfigLoader.setConfigValueAndSave("appearance.fakeScreenRounding", value);
                    }
                }
                SelectionGroupButton {
                    property int value: 2
                    rightmost: true
                    buttonText: "When not fullscreen"
                    toggled: (fakeScreenRoundingButtonGroup.selectedPolicy === value)
                    onClicked: {
                        ConfigLoader.setConfigValueAndSave("appearance.fakeScreenRounding", value);
                    }
                }
            }
        }

        ConfigRow {
            ConfigSwitch {
                text: "Transparency"
                checked: ConfigOptions.appearance.transparency
                onCheckedChanged: {
                    ConfigLoader.setConfigValueAndSave("appearance.transparency", checked);
                }
                StyledToolTip {
                    content: "Might look ass. Unsupported."
                }
            }
        }

        StyledText {
            text: "Bar"
            color: Appearance.colors.colSubtext
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                text: 'Borderless'
                checked: ConfigOptions.bar.borderless
                onCheckedChanged: {
                    ConfigLoader.setConfigValueAndSave("bar.borderless", checked);
                }
            }
            ConfigSwitch {
                text: 'Show background'
                checked: ConfigOptions.bar.showBackground
                onCheckedChanged: {
                    ConfigLoader.setConfigValueAndSave("bar.showBackground", checked);
                }
                StyledToolTip {
                    content: "Note: turning off can hurt readability"
                }
            }
        }
    }

    ContentSection {
        title: "Shell windows"
        spacing: 4

        ConfigRow {
            uniform: true
            ConfigSwitch {
                text: "Title bar"
                checked: ConfigOptions.windows.showTitlebar
                onCheckedChanged: {
                    ConfigLoader.setConfigValueAndSave("windows.showTitlebar", checked);
                }
            }
            ConfigSwitch {
                text: "Center title"
                checked: ConfigOptions.windows.centerTitle
                onCheckedChanged: {
                    ConfigLoader.setConfigValueAndSave("windows.centerTitle", checked);
                }
            }
        }
    }
}