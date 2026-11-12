import QtQuick
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.widgets

// Album art with a theme-coloured placeholder when there's no art.
Rectangle {
    id: root
    property string source: ""
    property real size: 18
    width: size
    height: size
    radius: size / 2 // round, like the rest of the shell
    color: Appearance.colors.colSecondaryContainer

    // clip is rectangular in Qt; mask to the rounded shape instead.
    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.width
            height: root.height
            radius: root.radius
        }
    }

    MaterialSymbol {
        anchors.centerIn: parent
        visible: img.status !== Image.Ready
        text: "music_note"
        iconSize: root.size * 0.6
        color: Appearance.colors.colOnSecondaryContainer
    }
    Image {
        id: img
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: root.size * 2
        sourceSize.height: root.size * 2
    }
}
