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
}