import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter

Item {
    id: root
    implicitWidth: 360
    implicitHeight: 352

    PageColumn {
        anchors.fill: parent

        BodyRectangle {
            implicitHeight: 400
            implicitWidth: 50

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4

                HeaderRow {
                    Layout.fillWidth: true
                    title: qsTr("Sound output")
                }

                StyledFlickable {
                    id: flickable
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    contentHeight: contentLayout.implicitHeight
                    contentWidth: width
                    clip: true

                    AudioChoices {
                        id: contentLayout
                        width: flickable.width
                    }
                }
            }
        }

        Separator {}

        FooterRectangle {
            WButton {
                id: moreSettingsButton
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                }
                inset: 0
                implicitHeight: 40
                implicitWidth: contentItem.implicitWidth + 30
                color: "transparent"

                onClicked: {
                    Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "sidebarLeft", "toggle"]);
                    Quickshell.execDetached(["bash", "-c", Config.options.apps.volumeMixer]);
                }

                contentItem: Item {
                    anchors.centerIn: parent
                    implicitWidth: buttonText.implicitWidth
                    WText {
                        id: buttonText
                        anchors.centerIn: parent
                        text: qsTr("More volume settings")
                        color: moreSettingsButton.pressed ? Looks.colors.fg : Looks.colors.fg1
                    }
                }
            }
        }
    }

    component AudioChoices: ColumnLayout {
        spacing: 4

        SectionText {
            text: qsTr("Output device")
        }

        Repeater {
            model: ScriptModel {
                values: Audio.outputDevices
            }
            delegate: WChoiceButton {
                required property var modelData
                icon.name: WIcons.audioDeviceIcon(modelData)
                text: Audio.friendlyDeviceName(modelData)
                checked: Audio.sink === modelData
                onClicked: {
                    Audio.setDefaultSink(modelData);
                }
            }
        }

        Separator { 
            visible: EasyEffects.available
            color: Looks.colors.bg2Hover
        }
        
        ////////////////////////////////////////////////////////////

        SectionText {
            visible: EasyEffects.available
            text: qsTr("Sound effects")
        }

        WChoiceButton {
            visible: EasyEffects.available
            text: Translation.tr("Off")
            checked: !EasyEffects.active
            onClicked: EasyEffects.disable()
        }

        WChoiceButton {
            visible: EasyEffects.available
            text: "EasyEffects"
            checked: EasyEffects.active
            onClicked: EasyEffects.enable()
        }

        Separator {
            color: Looks.colors.bg2Hover
        }

        ////////////////////////////////////////////////////////////

        SectionText {
            visible: EasyEffects.available
            text: qsTr("Volume mixer")
        }

        VolumeEntry {
            node: Audio.sink
            icon: "speaker"
            monochrome: true
        }

        Repeater {
            model: ScriptModel {
                values: Audio.outputAppNodes
            }
            delegate: VolumeEntry {
                required property var modelData
                node: modelData
            }
        }
    }
}
