import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Pipewire


Item {
    id: root
    Flickable {
        id: flickable
        anchors.fill: parent
        contentHeight: volumeMixerColumnLayout.height

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: flickable.width
                height: flickable.height
                radius: Appearance.rounding.normal
            }
        }

        ColumnLayout {
            id: volumeMixerColumnLayout
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 10
            spacing: 10

            // get a list of nodes that output to the default sink
            PwNodeLinkTracker {
                id: linkTracker
                node: Pipewire.defaultAudioSink
            }

            Repeater {
                model: linkTracker.linkGroups

                VolumeMixerEntry {
                    required property PwLinkGroup modelData
                    node: modelData.source // target = default sink, source = what we need
                }
            }
        }
    }

    // Placeholder when list is empty
    Item {
        anchors.fill: flickable

        visible: opacity > 0
        opacity: (linkTracker.linkGroups.length === 0) ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animation.menuDecel.duration
                easing.type: Appearance.animation.menuDecel.type
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 5

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: 55
                color: Appearance.m3colors.m3outline
                text: "brand_awareness"
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.m3colors.m3outline
                horizontalAlignment: Text.AlignHCenter
                text: "No audio source"
            }
        }
    }
}