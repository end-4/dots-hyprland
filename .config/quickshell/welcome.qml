//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

// Adjust this to make the app smaller or larger
//@ pragma Env QT_SCALE_FACTOR=1

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
            visible: Config.options?.windows.showTitlebar
            Layout.fillWidth: true
            implicitHeight: Math.max(welcomeText.implicitHeight, windowControlsRow.implicitHeight)
            StyledText {
                id: welcomeText
                anchors {
                    left: Config.options.windows.centerTitle ? undefined : parent.left
                    horizontalCenter: Config.options.windows.centerTitle ? parent.horizontalCenter : undefined
                    verticalCenter: parent.verticalCenter
                    leftMargin: 12
                }
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
                            Quickshell.execDetached(["rm", root.firstRunFilePath])
                        } else {
                            Quickshell.execDetached(["bash", "-c", `echo '${StringUtils.shellSingleQuoteEscape(root.firstRunFileContent)}' > '${StringUtils.shellSingleQuoteEscape(root.firstRunFilePath)}'`])
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
                    title: "Bar style"

                    ConfigSelectionArray {
                        currentValue: Config.options.bar.cornerStyle
                        configOptionName: "bar.cornerStyle"
                        onSelected: (newValue) => {
                            Config.options.bar.cornerStyle = newValue; // Update local copy
                        }
                        options: [
                            { displayName: "Hug", value: 0 },
                            { displayName: "Float", value: 1 },
                            { displayName: "Plain rectangle", value: 2 }
                        ]
                    }
                }

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
                                Quickshell.execDetached([`${Directories.wallpaperSwitchScriptPath}`])
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

                    ConfigRow {
                        ColumnLayout { // Weeb policy
                            ContentSubsectionLabel {
                                text: "Weeb"
                            }
                            ConfigSelectionArray {
                                currentValue: Config.options.policies.weeb
                                configOptionName: "policies.weeb"
                                onSelected: (newValue) => {
                                    Config.options.policies.weeb = newValue;
                                }
                                options: [
                                    { displayName: "No", value: 0 },
                                    { displayName: "Yes", value: 1 },
                                    { displayName: "Closet", value: 2 }
                                ]
                            }
                        }

                        ColumnLayout { // AI policy
                            ContentSubsectionLabel {
                                text: "AI"
                            }
                            ConfigSelectionArray {
                                currentValue: Config.options.policies.ai
                                configOptionName: "policies.ai"
                                onSelected: (newValue) => {
                                    Config.options.policies.ai = newValue;
                                }
                                options: [
                                    { displayName: "No", value: 0 },
                                    { displayName: "Yes", value: 1 },
                                    { displayName: "Local only", value: 2 }
                                ]
                            }
                        }
                    }
                }

                ContentSection {
                    title: "Info"

                    Flow {
                        Layout.fillWidth: true
                        spacing: 5

                        RippleButtonWithIcon {
                            materialIcon: "keyboard_alt"
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
                            materialIcon: "help"
                            mainText: "Usage"
                            onClicked: {
                                Qt.openUrlExternally("https://end-4.github.io/dots-hyprland-wiki/en/ii-qs/02usage/")
                            }
                        }
                        RippleButtonWithIcon {
                            materialIcon: "construction"
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
                        spacing: 5

                        RippleButtonWithIcon {
                            nerdIcon: "󰊤"
                            mainText: "GitHub"
                            onClicked: {
                                Qt.openUrlExternally("https://github.com/end-4/dots-hyprland")
                            }
                        }
                        RippleButtonWithIcon {
                            materialIcon: "favorite"
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
