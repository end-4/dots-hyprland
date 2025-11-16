import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

ColumnLayout {
    id: root
    required property bool isSink
    function correctType(node) {
        return (node.isSink === root.isSink) && node.audio
    }
    readonly property list<var> appPwNodes: Pipewire.nodes.values.filter((node) => { // Should be list<PwNode> but it breaks ScriptModel
        return root.correctType(node) && node.isStream
    })
    readonly property list<var> devices: Pipewire.nodes.values.filter(node => {
        return root.correctType(node) && !node.isStream
    })
    readonly property bool hasApps: appPwNodes.length > 0
    spacing: 16

    DialogSectionListView {
        Layout.fillHeight: true
        topMargin: 14

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

    StyledComboBox {
        id: deviceSelector
        Layout.fillHeight: false
        Layout.fillWidth: true
        Layout.bottomMargin: 6
        model: root.devices.map(node => (node.nickname || node.description || Translation.tr("Unknown")))
        currentIndex: root.devices.findIndex(item => {
            if (root.isSink) {
                return item.id === Pipewire.preferredDefaultAudioSink?.id
            } else {
                return item.id === Pipewire.preferredDefaultAudioSource?.id
            }
        })
        onActivated: (index) => {
            print(index)
            const item = root.devices[index]
            if (root.isSink) {
                Pipewire.preferredDefaultAudioSink = item
            } else {
                Pipewire.preferredDefaultAudioSource = item
            }
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

    Component {
        id: listElementComp
        ListElement {}
    }
}
