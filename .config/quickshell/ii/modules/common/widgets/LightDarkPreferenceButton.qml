import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell

GroupButton {
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
        Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --mode ${dark ? "dark" : "light"} --noswitch`])
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
                text: dark ? Translation.tr("Dark") : Translation.tr("Light")
                color: lightDarkButtonRoot.toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer2
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
