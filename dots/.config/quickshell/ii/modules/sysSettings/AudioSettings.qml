import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * Audio settings page using PipeWire via the existing Audio service.
 */
ContentPage {
    forceWidth: true

    ContentSection {
        icon: "volume_up"
        title: Translation.tr("Output")

        // Master volume slider
        ConfigSlider {
            text: Translation.tr("Volume")
            buttonIcon: "volume_up"
            value: Audio.value * 100
            from: 0; to: 100
            onValueChanged: {
                if (Audio.sink) Audio.sink.audio.volume = value / 100
            }
        }

        ConfigSwitch {
            buttonIcon: "volume_off"
            text: Translation.tr("Mute")
            checked: Audio.sink?.audio.muted ?? false
            onCheckedChanged: { if (Audio.sink) Audio.sink.audio.muted = checked }
        }

        ContentSubsection {
            title: Translation.tr("Output device")

            Repeater {
                model: Audio.outputDevices
                delegate: DeviceButton {
                    required property var modelData
                    Layout.fillWidth: true
                    deviceNode: modelData
                    isDefault: Pipewire.defaultAudioSink === modelData
                    onSetDefault: Audio.setDefaultSink(modelData)
                }
            }
        }
    }

    ContentSection {
        icon: "mic"
        title: Translation.tr("Input")

        ConfigSlider {
            text: Translation.tr("Microphone volume")
            buttonIcon: "mic"
            value: (Audio.source?.audio.volume ?? 0) * 100
            from: 0; to: 100
            onValueChanged: {
                if (Audio.source) Audio.source.audio.volume = value / 100
            }
        }

        ConfigSwitch {
            buttonIcon: "mic_off"
            text: Translation.tr("Mute microphone")
            checked: Audio.source?.audio.muted ?? false
            onCheckedChanged: { if (Audio.source) Audio.source.audio.muted = checked }
        }

        ContentSubsection {
            title: Translation.tr("Input device")

            Repeater {
                model: Audio.inputDevices
                delegate: DeviceButton {
                    required property var modelData
                    Layout.fillWidth: true
                    deviceNode: modelData
                    isDefault: Pipewire.defaultAudioSource === modelData
                    onSetDefault: Audio.setDefaultSource(modelData)
                }
            }
        }
    }

    ContentSection {
        icon: "settings"
        title: Translation.tr("Advanced")

        ConfigSwitch {
            buttonIcon: "hearing"
            text: Translation.tr("Earbang protection")
            checked: Config.options.audio.protection.enable
            onCheckedChanged: { Config.options.audio.protection.enable = checked }
            StyledToolTip { text: Translation.tr("Prevents abrupt volume increments and restricts max allowed volume") }
        }

        RippleButtonWithIcon {
            Layout.fillWidth: true
            materialIcon: "open_in_new"
            mainText: Translation.tr("Open PulseAudio volume mixer")
            buttonRadius: Appearance.rounding.small
            onClicked: Quickshell.execDetached(["bash", "-c", Config.options.apps.volumeMixer])
        }
    }

    component DeviceButton: RippleButton {
        required property var deviceNode
        required property bool isDefault
        signal setDefault()
        implicitHeight: 50
        buttonRadius: Appearance.rounding.normal
        colBackground: isDefault ? Appearance.colors.colPrimaryContainer : "transparent"
        colBackgroundHover: Appearance.colors.colLayer1Hover
        onClicked: setDefault()

        contentItem: RowLayout {
            anchors { fill: parent; margins: 10 }
            spacing: 10
            MaterialSymbol {
                text: isDefault ? "radio_button_checked" : "radio_button_unchecked"
                iconSize: 18
                color: isDefault ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
            }
            StyledText {
                Layout.fillWidth: true
                text: Audio.friendlyDeviceName(deviceNode)
                font.pixelSize: Appearance.font.pixelSize.small
                color: isDefault ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer0
                elide: Text.ElideRight
            }
        }
    }
}
