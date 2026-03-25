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
    readonly property list<var> appPwNodes: {
        const vm = Config.options.audio.volumeMixer
        const _dep = JSON.stringify(vm.hiddenMixerPlaybackStreamKeys ?? []) + "|" + JSON.stringify(vm.hiddenMixerRecordStreamKeys ?? [])
        void _dep
        return isSink ? Audio.mixerOutputAppNodes : Audio.mixerInputAppNodes
    }
    readonly property list<var> devices: {
        const vm = Config.options.audio.volumeMixer
        const _dep = JSON.stringify(vm.hiddenMixerOutputDeviceKeys ?? []) + "|" + JSON.stringify(vm.hiddenMixerInputDeviceKeys ?? [])
        void _dep
        const _pw = Pipewire.nodes?.values?.length ?? 0
        void _pw
        void Pipewire.defaultAudioSink
        void Pipewire.defaultAudioSource
        return isSink ? Audio.mixerOutputDevices : Audio.mixerInputDevices
    }
    readonly property var deviceComboLabels: devices.map(node => Audio.friendlyDeviceName(node))
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
        PagePlaceholder {
            icon: "widgets"
            title: Translation.tr("No applications")
            shown: !root.hasApps
            shape: MaterialShape.Shape.Cookie7Sided
        }
    }

    StyledComboBox {
        id: deviceSelector
        Layout.fillHeight: false
        Layout.fillWidth: true
        Layout.bottomMargin: 6
        model: root.deviceComboLabels
        currentIndex: root.devices.findIndex(item => {
            if (root.isSink) {
                return item.id === Pipewire.defaultAudioSink?.id
            } else {
                return item.id === Pipewire.defaultAudioSource?.id
            }
        })
        onActivated: (index) => {
            print(index)
            const item = root.devices[index]
            if (root.isSink) {
                Audio.setDefaultSink(item)
            } else {
                Audio.setDefaultSource(item)
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
