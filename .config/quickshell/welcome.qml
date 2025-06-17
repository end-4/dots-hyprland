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
    property real contentPadding: 5
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

    component SelectionConnectedButton: GroupButton {
        id: selectionConnectedButtonRoot
        horizontalPadding: 12
        verticalPadding: 8
        bounce: false
        property bool leftmost: false
        property bool rightmost: false
        leftRadius: (toggled || leftmost) ? (height / 2) : Appearance.rounding.unsharpenmore
        rightRadius: (toggled || rightmost) ? (height / 2) : Appearance.rounding.unsharpenmore
        colBackground: Appearance.colors.colSecondaryContainer
        contentItem: StyledText {
            color: parent.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
            text: selectionConnectedButtonRoot.buttonText
        }
    }

    component Section: ColumnLayout {
        id: sectionRoot
        property string title
        default property alias data: sectionContent.data

        Layout.fillWidth: true
        spacing: 8
        StyledText {
            text: sectionRoot.title
            font.pixelSize: Appearance.font.pixelSize.larger
        }
        ColumnLayout {
            id: sectionContent
            spacing: 5
        }
    }

    component ButtonWithIcon: RippleButton {
        id: buttonWithIconRoot
        property string nerdIcon
        property string iconText
        property string mainText: "Button text"
        property Component mainContentComponent: Component {
            StyledText {
                text: buttonWithIconRoot.mainText
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnSecondaryContainer
            }
        }
        implicitHeight: 35
        horizontalPadding: 15
        buttonRadius: Appearance.rounding.small
        colBackground: Appearance.colors.colLayer2

        contentItem: RowLayout {
            Item {
                implicitWidth: Math.max(materialIconLoader.implicitWidth, nerdIconLoader.implicitWidth)
                Loader {
                    id: materialIconLoader
                    anchors.centerIn: parent
                    active: !nerdIcon
                    sourceComponent: MaterialSymbol {
                        text: buttonWithIconRoot.iconText
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnSecondaryContainer
                        fill: 1
                    }
                }
                Loader {
                    id: nerdIconLoader
                    anchors.centerIn: parent
                    active: nerdIcon
                    sourceComponent: StyledText {
                        text: buttonWithIconRoot.nerdIcon
                        font.pixelSize: Appearance.font.pixelSize.larger
                        font.family: Appearance.font.family.iconNerd
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                }
            }
            Loader {
                sourceComponent: buttonWithIconRoot.mainContentComponent
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    component LightDarkPrefButton: GroupButton {
        id: lightDarkButtonRoot
        required property bool dark
        property color previewBg: dark ? ColorUtils.colorWithHueOf("#3f3838", Appearance.m3colors.m3primary) : 
            ColorUtils.colorWithHueOf("#F7F9FF", Appearance.m3colors.m3primary)
        property color previewFg: dark ? Qt.lighter(previewBg, 2.2) : ColorUtils.mix(previewBg, "#292929", 0.85)
        padding: 5
        Layout.fillWidth: true
        colBackground: Appearance.colors.colLayer2
        toggled: Appearance.m3colors.darkmode === dark
        onClicked: {
            Hyprland.dispatch(`exec ${Directories.wallpaperSwitchScriptPath} --mode ${dark ? "dark" : "light"} --noswitch`)
        }
        contentItem: Item {
            anchors.centerIn: parent
            implicitWidth: buttonContentLayout.implicitWidth
            implicitHeight: buttonContentLayout.implicitHeight
            ColumnLayout {
                id: buttonContentLayout
                anchors.centerIn: parent
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 250
                    implicitHeight: skeletonColumnLayout.implicitHeight + 10 * 2
                    radius: lightDarkButtonRoot.buttonRadius - lightDarkButtonRoot.padding
                    color: lightDarkButtonRoot.previewBg
                    border {
                        width: 1
                        color: Appearance.m3colors.m3outlineVariant
                    }

                    // Some skeleton items
                    ColumnLayout {
                        id: skeletonColumnLayout
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10
                        RowLayout {
                            Rectangle {
                                radius: Appearance.rounding.full
                                color: lightDarkButtonRoot.previewFg
                                implicitWidth: 50
                                implicitHeight: 50
                            }
                            ColumnLayout {
                                spacing: 4
                                Rectangle {
                                    radius: Appearance.rounding.unsharpenmore
                                    color: lightDarkButtonRoot.previewFg
                                    Layout.fillWidth: true
                                    implicitHeight: 22
                                }
                                Rectangle {
                                    radius: Appearance.rounding.unsharpenmore
                                    color: lightDarkButtonRoot.previewFg
                                    Layout.fillWidth: true
                                    Layout.rightMargin: 45
                                    implicitHeight: 18
                                }
                            }
                        }
                        StyledProgressBar {
                            Layout.topMargin: 5
                            Layout.bottomMargin: 5
                            Layout.fillWidth: true
                            value: 0.7
                            sperm: true
                            animateSperm: lightDarkButtonRoot.toggled
                            highlightColor: lightDarkButtonRoot.toggled ? Appearance.m3colors.m3primary : lightDarkButtonRoot.previewFg
                            trackColor: ColorUtils.mix(lightDarkButtonRoot.previewBg, lightDarkButtonRoot.previewFg, 0.5)
                        }
                        RowLayout {
                            spacing: 2
                            Rectangle {
                                radius: Appearance.rounding.full
                                color: lightDarkButtonRoot.toggled ? Appearance.m3colors.m3primary : lightDarkButtonRoot.previewFg
                                Layout.fillWidth: true
                                implicitHeight: 30
                                MaterialSymbol {
                                    visible: lightDarkButtonRoot.toggled
                                    anchors.centerIn: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "check"
                                    iconSize: 20
                                    color: lightDarkButtonRoot.toggled ? Appearance.m3colors.m3onPrimary : lightDarkButtonRoot.previewBg
                                }
                            }
                            Rectangle {
                                radius: Appearance.rounding.unsharpenmore
                                color: lightDarkButtonRoot.toggled ? Appearance.m3colors.m3secondaryContainer : lightDarkButtonRoot.previewFg
                                Layout.fillWidth: true
                                implicitHeight: 30
                            }
                            Rectangle {
                                topLeftRadius: Appearance.rounding.unsharpenmore
                                bottomLeftRadius: Appearance.rounding.unsharpenmore
                                topRightRadius: Appearance.rounding.full
                                bottomRightRadius: Appearance.rounding.full
                                color: lightDarkButtonRoot.toggled ? Appearance.m3colors.m3secondaryContainer : lightDarkButtonRoot.previewFg
                                Layout.fillWidth: true
                                implicitHeight: 30
                            }
                        }
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    text: dark ? "Dark" : "Light"
                    color: lightDarkButtonRoot.toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer2
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: contentPadding
        }

        Item {
            visible: ConfigOptions?.windows.showTitlebar
            Layout.fillWidth: true
            implicitHeight: Math.max(welcomeText.implicitHeight, windowControlsRow.implicitHeight)
            StyledText {
                id: welcomeText
                anchors.centerIn: parent
                color: Appearance.colors.colOnLayer0
                text: "Yooooo hi there"
                font.pixelSize: Appearance.font.pixelSize.hugeass
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
        Rectangle {
            color: Appearance.m3colors.m3surfaceContainerLow
            implicitHeight: contentColumn.implicitHeight
            implicitWidth: contentColumn.implicitWidth
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Appearance.rounding.windowRounding - root.contentPadding
            Flickable {
                clip: true
                anchors.fill: parent
                contentHeight: contentColumn.implicitHeight
                implicitWidth: contentColumn.implicitWidth
                ColumnLayout {
                    id: contentColumn
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                        margins: 10
                    }
                    spacing: 20

                    Section {
                        title: "Style & wallpaper"

                        ButtonGroup {
                            Layout.fillWidth: true
                            LightDarkPrefButton {
                                dark: false
                            }
                            LightDarkPrefButton {
                                dark: true
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            ButtonWithIcon {
                                id: rndWallBtn
                                Layout.alignment: Qt.AlignHCenter
                                buttonRadius: Appearance.rounding.small
                                iconText: "wallpaper"
                                mainText: konachanWallProc.running ? "Be patient..." : "Random: Konachan"
                                onClicked: {
                                    console.log(konachanWallProc.command.join(" "))
                                    konachanWallProc.running = true;
                                }
                            }
                            ButtonWithIcon {
                                iconText: "wallpaper"
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

                    Section {
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
                                    SelectionConnectedButton {
                                        property int value: 0
                                        leftmost: true
                                        buttonText: "No"
                                        toggled: (weebPolicyBtnGroup.selectedPolicy === value)
                                        onClicked: {
                                            ConfigLoader.setConfigValueAndSave("policies.weeb", value);
                                        }
                                    }
                                    SelectionConnectedButton {
                                        property int value: 1
                                        buttonText: "Yes"
                                        toggled: (weebPolicyBtnGroup.selectedPolicy === value)
                                        onClicked: {
                                            ConfigLoader.setConfigValueAndSave("policies.weeb", value);
                                        }
                                    }
                                    SelectionConnectedButton {
                                        property int value: 2
                                        rightmost: true
                                        buttonText: "Closet"
                                        toggled: (weebPolicyBtnGroup.selectedPolicy === value)
                                        onClicked: {
                                            ConfigLoader.setConfigValueAndSave("policies.weeb", value);
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
                                    SelectionConnectedButton {
                                        property int value: 0
                                        leftmost: true
                                        buttonText: "No"
                                        toggled: (aiPolicyBtnGroup.selectedPolicy === value)
                                        onClicked: {
                                            ConfigLoader.setConfigValueAndSave("policies.ai", value);
                                        }
                                    }
                                    SelectionConnectedButton {
                                        property int value: 1
                                        buttonText: "Yes"
                                        toggled: (aiPolicyBtnGroup.selectedPolicy === value)
                                        onClicked: {
                                            ConfigLoader.setConfigValueAndSave("policies.ai", value);
                                        }
                                    }
                                    SelectionConnectedButton {
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

                    Section {
                        title: "Info"

                        Flow {
                            Layout.fillWidth: true
                            spacing: 10

                            ButtonWithIcon {
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

                            ButtonWithIcon {
                                iconText: "help"
                                mainText: "Usage"
                                onClicked: {
                                    Qt.openUrlExternally("https://end-4.github.io/dots-hyprland-wiki/en/ii-qs/02usage/")
                                }
                            }
                            ButtonWithIcon {
                                iconText: "construction"
                                mainText: "Configuration"
                                onClicked: {
                                    Qt.openUrlExternally("https://end-4.github.io/dots-hyprland-wiki/en/ii-qs/03config/")
                                }
                            }
                        }
                    }

                    Section {
                        title: "Useless buttons"

                        Flow {
                            Layout.fillWidth: true
                            spacing: 10

                            ButtonWithIcon {
                                nerdIcon: "󰊤"
                                mainText: "GitHub"
                                onClicked: {
                                    Qt.openUrlExternally("https://github.com/end-4/dots-hyprland")
                                }
                            }
                            ButtonWithIcon {
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
}
