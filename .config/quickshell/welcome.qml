//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

// Adjust this to make the app smaller or larger
//@ pragma Env QT_SCALE_FACTOR=1

import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "root:/services/"
import "root:/modules/common/"
import "root:/modules/common/widgets/"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import "root:/modules/common/functions/file_utils.js" as FileUtils
import "root:/modules/common/functions/string_utils.js" as StringUtils

ApplicationWindow {
    id: root
    property string firstRunFilePath: FileUtils.trimFileProtocol(`${Directories.state}/user/first_run.txt`)
    property string firstRunFileContent: "This file is just here to confirm you've been greeted :>"
    property real contentPadding: 8
    property bool showNextTime: false
    visible: true
    onClosing: Qt.quit()
    title: "illogical-impulse Welcome"

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        ConfigLoader.loadConfig()
    }

    minimumWidth: 600
    minimumHeight: 400
    width: 800
    height: 650
    color: Appearance.m3colors.m3background

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

    ColumnLayout {
        anchors {
            fill: parent
            margins: contentPadding
        }

        Item { // Titlebar
            visible: ConfigOptions?.windows.showTitlebar
            Layout.fillWidth: true
            implicitHeight: Math.max(welcomeText.implicitHeight, windowControlsRow.implicitHeight)
            StyledText {
                id: welcomeText
                anchors.centerIn: parent
                color: Appearance.colors.colOnLayer0
                text: "Yooooo hi there"
                font.pixelSize: Appearance.font.pixelSize.title
                font.family: Appearance.font.family.title
            }
            RowLayout { // Window controls row
                id: windowControlsRow
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    text: "Show next time"
                }
                StyledSwitch {
                    id: showNextTimeSwitch
                    checked: root.showNextTime
                    scale: 0.6
                    Layout.alignment: Qt.AlignVCenter
                    onCheckedChanged: {
                        if (checked) {
                            Hyprland.dispatch(`exec rm '${StringUtils.shellSingleQuoteEscape(root.firstRunFilePath)}'`)
                        } else {
                            console.log(`exec echo '${StringUtils.shellSingleQuoteEscape(root.firstRunFileContent)}' > '${StringUtils.shellSingleQuoteEscape(root.firstRunFilePath)}'`)
                            Hyprland.dispatch(`exec echo '${StringUtils.shellSingleQuoteEscape(root.firstRunFileContent)}' > '${StringUtils.shellSingleQuoteEscape(root.firstRunFilePath)}'`)
                        }
                    }
                }
                RippleButton {
                    buttonRadius: Appearance.rounding.full
                    implicitWidth: 35
                    implicitHeight: 35
                    onClicked: root.close()
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: "close"
                        iconSize: 20
                    }
                }
            }
        }
        Rectangle { // Content container
            color: Appearance.m3colors.m3surfaceContainerLow
            radius: Appearance.rounding.windowRounding - root.contentPadding
            implicitHeight: contentColumn.implicitHeight
            implicitWidth: contentColumn.implicitWidth
            Layout.fillWidth: true
            Layout.fillHeight: true
            

            ContentPage {
                id: contentColumn
                anchors.fill: parent
                ContentSection {
                    title: "Style & wallpaper"

                    ButtonGroup {
                        Layout.fillWidth: true
                        LightDarkPreferenceButton {
                            dark: false
                        }
                        LightDarkPreferenceButton {
                            dark: true
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        RippleButtonWithIcon {
                            id: rndWallBtn
                            Layout.alignment: Qt.AlignHCenter
                            buttonRadius: Appearance.rounding.small
                            iconText: "wallpaper"
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
                            iconText: "wallpaper"
                            StyledToolTip {
                                content: "Pick wallpaper image on your system"
                            }
                            onClicked: {
                                Hyprland.dispatch(`exec ${Directories.wallpaperSwitchScriptPath}`)
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
                    title: "Policies"

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 15
                        ColumnLayout { // Weeb policy
                            StyledText {
                                text: "Weeb"
                                color: Appearance.colors.colSubtext
                            }
                            ButtonGroup {
                                id: weebPolicyBtnGroup
                                property int selectedPolicy: ConfigOptions.policies.weeb
                                spacing: 2
                                SelectionGroupButton {
                                    property int value: 0
                                    leftmost: true
                                    buttonText: "No"
                                    toggled: (weebPolicyBtnGroup.selectedPolicy === value)
                                    onClicked: {
                                        ConfigLoader.setConfigValueAndSave("policies.weeb", value);
                                    }
                                }
                                SelectionGroupButton {
                                    property int value: 1
                                    buttonText: "Yes"
                                    toggled: (weebPolicyBtnGroup.selectedPolicy === value)
                                    onClicked: {
                                        ConfigLoader.setConfigValueAndSave("policies.weeb", value);
                                    }
                                }
                                SelectionGroupButton {
                                    property int value: 2
                                    rightmost: true
                                    buttonText: "Closet"
                                    toggled: (weebPolicyBtnGroup.selectedPolicy === value)
                                    onClicked: {
                                        ConfigLoader.setConfigValueAndSave("policies.weeb", value);
                                    }
                                    StyledToolTip {
                                        content: "The Anime tab on the left sidebar would still\nbe available, but its tab button won't show"
                                    }
                                }
                            }
                        }
                        ColumnLayout { // AI policy
                            StyledText {
                                text: "AI"
                                color: Appearance.colors.colSubtext
                            }
                            ButtonGroup {
                                id: aiPolicyBtnGroup
                                property int selectedPolicy: ConfigOptions.policies.ai
                                spacing: 2
                                SelectionGroupButton {
                                    property int value: 0
                                    leftmost: true
                                    buttonText: "No"
                                    toggled: (aiPolicyBtnGroup.selectedPolicy === value)
                                    onClicked: {
                                        ConfigLoader.setConfigValueAndSave("policies.ai", value);
                                    }
                                }
                                SelectionGroupButton {
                                    property int value: 1
                                    buttonText: "Yes"
                                    toggled: (aiPolicyBtnGroup.selectedPolicy === value)
                                    onClicked: {
                                        ConfigLoader.setConfigValueAndSave("policies.ai", value);
                                    }
                                }
                                SelectionGroupButton {
                                    property int value: 2
                                    rightmost: true
                                    buttonText: "Local only"
                                    toggled: (aiPolicyBtnGroup.selectedPolicy === value)
                                    onClicked: {
                                        ConfigLoader.setConfigValueAndSave("policies.ai", value);
                                    }
                                }
                            }
                        }
                    }
                }

                ContentSection {
                    title: "Info"

                    Flow {
                        Layout.fillWidth: true
                        spacing: 10

                        RippleButtonWithIcon {
                            iconText: "keyboard_alt"
                            onClicked: {
                                Hyprland.dispatch("global quickshell:cheatsheetOpen")
                            }
                            mainContentComponent: Component {
                                RowLayout {
                                    spacing: 10
                                    StyledText {
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        text: "Keybinds"
                                        color: Appearance.colors.colOnSecondaryContainer
                                    }
                                    RowLayout {
                                        spacing: 3
                                        KeyboardKey {
                                            key: "󰖳"
                                        }
                                        StyledText {
                                            Layout.alignment: Qt.AlignVCenter
                                            text: "+"
                                        }
                                        KeyboardKey {
                                            key: "/"
                                        }
                                    }
                                }
                            }
                        }

                        RippleButtonWithIcon {
                            iconText: "help"
                            mainText: "Usage"
                            onClicked: {
                                Qt.openUrlExternally("https://end-4.github.io/dots-hyprland-wiki/en/ii-qs/02usage/")
                            }
                        }
                        RippleButtonWithIcon {
                            iconText: "construction"
                            mainText: "Configuration"
                            onClicked: {
                                Qt.openUrlExternally("https://end-4.github.io/dots-hyprland-wiki/en/ii-qs/03config/")
                            }
                        }
                    }
                }

                ContentSection {
                    title: "Useless buttons"

                    Flow {
                        Layout.fillWidth: true
                        spacing: 10

                        RippleButtonWithIcon {
                            nerdIcon: "󰊤"
                            mainText: "GitHub"
                            onClicked: {
                                Qt.openUrlExternally("https://github.com/end-4/dots-hyprland")
                            }
                        }
                        RippleButtonWithIcon {
                            iconText: "favorite"
                            mainText: "Funny number"
                            onClicked: {
                                Qt.openUrlExternally("https://github.com/sponsors/end-4")
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}
