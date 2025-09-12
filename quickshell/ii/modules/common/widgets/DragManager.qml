import qs.modules.common
import qs.services
import QtQuick

/**
 * A convenience MouseArea for handling drag events.
 */
MouseArea {
    id: root
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton

    property bool interactive: true
    property bool automaticallyReset: true
    readonly property real dragDiffX: _dragDiffX
    readonly property real dragDiffY: _dragDiffY

    signal dragPressed(diffX: real, diffY: real)
    signal dragReleased(diffX: real, diffY: real)
    
    property real startX: 0
    property real startY: 0
    property bool dragging: false
    property real _dragDiffX: 0
    property real _dragDiffY: 0

    function resetDrag() {
        _dragDiffX = 0
        _dragDiffY = 0
    }

    onPressed: (mouse) => {
        if (!root.interactive) {
            if (mouse.button === Qt.LeftButton) {
                mouse.accepted = false;
            }
            return;
        }
        if (mouse.button === Qt.LeftButton) {
            startX = mouse.x
            startY = mouse.y
        }
    }
    onReleased: (mouse) => {
        if (!root.interactive) {
            return;
        }
        dragging = false
        root.dragReleased(_dragDiffX, _dragDiffY);
        if (root.automaticallyReset) {
            root.resetDrag();
        }
    }
    onPositionChanged: (mouse) => {
        if (!root.interactive) {
            return;
        }
        if (mouse.buttons & Qt.LeftButton) {
            root._dragDiffX = mouse.x - startX
            root._dragDiffY = mouse.y - startY
            const dist = Math.sqrt(root._dragDiffX * root._dragDiffX + root._dragDiffY * root._dragDiffY);
            root.dragPressed(_dragDiffX, _dragDiffY);
            root.dragging = true;
        }
    }
    onCanceled: (mouse) => {
        if (!root.interactive) {
            return;
        }
        released(mouse);
    }
}
