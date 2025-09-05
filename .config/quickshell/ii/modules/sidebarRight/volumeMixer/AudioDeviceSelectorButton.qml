import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

RippleButton {
    id: button
    required property bool input

    buttonRadius: Appearance.rounding.small
    colBackground: Appearance.colors.colLayer2
    colBackgroundHover: Appearance.colors.colLayer2Hover
    colRipple: Appearance.colors.colLayer2Active

    implicitHeight: contentItem.implicitHeight + 6 * 2
    implicitWidth: contentItem.implicitWidth + 6 * 2

    contentItem: RowLayout {
        anchors.fill: parent
        anchors.margins: 5
        spacing: 5

        MaterialSymbol {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: false
            Layout.leftMargin: 5
            color: Appearance.colors.colOnLayer2
            iconSize: Appearance.font.pixelSize.hugeass
            text: input ? "mic_external_on" : "media_output"
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.rightMargin: 5
            spacing: 0
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.normal
                text: input ? Translation.tr("Input") : Translation.tr("Output")
                color: Appearance.colors.colOnLayer2
            }
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                text: (input ? Pipewire.defaultAudioSource?.description : Pipewire.defaultAudioSink?.description) ?? Translation.tr("Unknown")
                color: Appearance.m3colors.m3outline
                animateChange: true
            }
        }
    }
}