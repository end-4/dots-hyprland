pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

WindowDialog {
    id: root
    property bool isSink: true
    function correctType(node) {
        return (node.isSink === root.isSink) && node.audio
    }
    readonly property list<var> appPwNodes: Pipewire.nodes.values.filter((node) => { // Should be list<PwNode> but it breaks ScriptModel
        return root.correctType(node) && node.isStream
    })
    readonly property bool hasApps: appPwNodes.length > 0
    backgroundHeight: 700

    WindowDialogTitle {
        text: root.isSink ? Translation.tr("Audio output") : Translation.tr("Audio input")
    }

    WindowDialogSectionHeader {
        visible: root.hasApps
        text: Translation.tr("Applications")
    }

    WindowDialogSeparator {
        visible: root.hasApps
        Layout.topMargin: -22
        Layout.leftMargin: 0
        Layout.rightMargin: 0
    }
    
    DialogSectionListView {
        visible: root.hasApps
        Layout.fillHeight: true

        model: ScriptModel {
            values: root.appPwNodes
        }
        delegate: VolumeMixerEntry {
            anchors {
                left: parent?.left
                right: parent?.right
            }
            required property var modelData
            node: modelData
        }
    }

    WindowDialogSectionHeader {
        text: Translation.tr("Devices")
    }

    WindowDialogSeparator {
        Layout.topMargin: -22
        Layout.leftMargin: 0
        Layout.rightMargin: 0
    }

    DialogSectionListView {
        Layout.fillHeight: !root.hasApps
        Layout.preferredHeight: 180

        model: ScriptModel {
            values: Pipewire.nodes.values.filter(node => {
                return root.correctType(node) && !node.isStream
            })
        }
        delegate: StyledRadioButton {
            id: radioButton
            required property var modelData
            anchors {
                left: parent?.left
                right: parent?.right
            }

            description: modelData.description
            checked: modelData.id === (root.isSink ? Pipewire.preferredDefaultAudioSink?.id : Pipewire.preferredDefaultAudioSource?.id)

            onCheckedChanged: {
                if (!checked) return;
                if (root.isSink) {
                    Pipewire.preferredDefaultAudioSink = modelData
                } else {
                    Pipewire.preferredDefaultAudioSource = modelData
                }
            }
        }
    }

    WindowDialogSeparator {
        Layout.leftMargin: 0
        Layout.rightMargin: 0
    }

    WindowDialogButtonRow {
        DialogButton {
            buttonText: Translation.tr("Details")
            onClicked: {
                Quickshell.execDetached(["bash", "-c", `${Config.options.apps.volumeMixer}`]);
                GlobalStates.sidebarRightOpen = false;
            }
        }

        Item {
            Layout.fillWidth: true
        }

        DialogButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }

    component DialogSectionListView: StyledListView {
        Layout.fillWidth: true
        Layout.topMargin: -22
        Layout.bottomMargin: -16
        Layout.leftMargin: -Appearance.rounding.large
        Layout.rightMargin: -Appearance.rounding.large
        topMargin: 12
        bottomMargin: 12
        leftMargin: 20
        rightMargin: 20

        clip: true
        spacing: 4
        animateAppearance: false
    }
}
