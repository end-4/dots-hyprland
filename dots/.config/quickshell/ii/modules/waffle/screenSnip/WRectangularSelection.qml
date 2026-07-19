import QtQuick
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

Item {
    id: root

    required property int regionX
    required property int regionY
    required property int regionWidth
    required property int regionHeight

    property bool dashed: true
    property color borderColor: "#ffffff"
    property color overlayColor: ColorUtils.transparentize("#000000", 1)
    Component.onCompleted: overlayColor = ColorUtils.transparentize("#000000", 0.4)
    Behavior on overlayColor {
        ColorAnimation {
            duration: 150
            easing.type: Easing.InOutQuad
        }
    }

    // Overlay to darken screen
    // Base dark overlay around region
    Rectangle {
        id: darkenOverlay
        z: 1
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: root.regionX - darkenOverlay.border.width
            topMargin: root.regionY - darkenOverlay.border.width
        }
        width: root.regionWidth + darkenOverlay.border.width * 2
        height: root.regionHeight + darkenOverlay.border.width * 2
        color: "transparent"
        border.color: root.overlayColor
        border.width: Math.max(root.width, root.height)
    }

    // Selection border
    DashedBorder {
        id: border
        z: 2
        visible: root.regionWidth > 0 && root.regionHeight > 0
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: Math.round(root.regionX - borderWidth)
            topMargin: Math.round(root.regionY - borderWidth)
        }
        width: Math.round(root.regionWidth + borderWidth * 2)
        height: Math.round(root.regionHeight + borderWidth * 2)
        color: root.borderColor
        dashLength: 4
        gapLength: root.dashed ? 3 : 0
        borderWidth: 1
    }
}
