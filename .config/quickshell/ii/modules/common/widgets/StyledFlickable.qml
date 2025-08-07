import QtQuick

Flickable {
    id: root
    maximumFlickVelocity: 3500
    boundsBehavior: Flickable.DragOverBounds

    property real touchpadScrollFactor: 100
    property real mouseScrollFactor: 50 

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function(wheelEvent) {
            var delta = wheelEvent.angleDelta.y / 120;
            // The angleDelta.y of a touchpad is usually small and continuous, 
            // while that of a mouse wheel is typically in multiples of ±120.
            var scrollFactor = Math.abs(wheelEvent.angleDelta.y) >= 120 ? root.mouseScrollFactor : root.touchpadScrollFactor;
            var targetY = root.contentY - delta * scrollFactor;
            targetY = Math.max(0, Math.min(targetY, root.contentHeight - root.height));
            root.contentY = targetY;
        }
    }
}
