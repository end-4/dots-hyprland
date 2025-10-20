import qs.modules.common.widgets
import QtQuick

Item {
    id: root
    required property real regionX
    required property real regionY
    required property real regionWidth
    required property real regionHeight
    required property real mouseX
    required property real mouseY
    required property color color
    required property color overlayColor

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
    Rectangle {
        id: selectionBorder
        z: 1
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: root.regionX
            topMargin: root.regionY
        }
        width: root.regionWidth
        height: root.regionHeight
        color: "transparent"
        border.color: root.color
        border.width: 2
        // radius: root.standardRounding
        radius: 0 // TODO: figure out how to make the overlay thing work with rounding
    }

    StyledText {
        z: 2
        anchors {
            top: selectionBorder.bottom
            right: selectionBorder.right
            margins: 8
        }
        color: root.color
        text: `${Math.round(root.regionWidth)} x ${Math.round(root.regionHeight)}`
    }

    // Coord lines
    Rectangle { // Vertical
        z: 2
        x: root.mouseX
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        width: 1
        color: root.color
    }
    Rectangle { // Horizontal
        z: 2
        y: root.mouseY
        anchors {
            left: parent.left
            right: parent.right
        }
        height: 1
        color: root.color
    }
}
