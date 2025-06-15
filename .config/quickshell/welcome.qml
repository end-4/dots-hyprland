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
    height: 600
    color: Appearance.m3colors.m3background

    component Section: ColumnLayout {
        id: sectionRoot
        property string title
        default property alias data: sectionContent.data

        Layout.fillWidth: true
        spacing: 10
        StyledText {
            text: sectionRoot.title
            font.pixelSize: Appearance.font.pixelSize.larger
        }
        ColumnLayout {
            id: sectionContent
            spacing: 5
        }
    }

    component LightDarkPrefButton: GroupButton {
        id: lightDarkButtonRoot
        required property bool dark
        property color previewBg: dark ? ColorUtils.colorWithHueOf("#3f3838", Appearance.m3colors.m3primary) : 
            ColorUtils.colorWithHueOf("#f8f8f8", Appearance.m3colors.m3primary)
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
            Layout.fillWidth: true
            implicitHeight: Math.max(welcomeText.implicitHeight, windowControlsRow.implicitHeight)
            StyledText {
                id: welcomeText
                anchors.centerIn: parent
                color: Appearance.colors.colOnLayer0
                text: "Welcome"
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
                    title: "Customize"

                    ButtonGroup {
                        Layout.fillWidth: true
                        LightDarkPrefButton {
                            dark: false
                        }
                        LightDarkPrefButton {
                            dark: true
                        }
                    }
                }

                Section {
                    title: "Info"

                    RippleButton {
                        implicitHeight: 35
                        horizontalPadding: 10
                        // buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.colors.colSecondaryContainer
                        colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                        colRipple: Appearance.colors.colSecondaryContainerActive

                        onClicked: {
                            Hyprland.dispatch("global quickshell:cheatsheetOpen")
                        }

                        contentItem: RowLayout {
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
                            StyledText {
                                text: "Open keybind cheatsheet"
                                color: Appearance.colors.colOnSecondaryContainer
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
