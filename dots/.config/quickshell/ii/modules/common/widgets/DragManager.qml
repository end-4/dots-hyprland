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
    property bool axisLockEnabled: false
    property real axisLockThreshold: 8
    property string gestureAxis: ""
    preventStealing: axisLockEnabled && gestureAxis === "horizontal"
    readonly property real dragDiffX: _dragDiffX
    readonly property real dragDiffY: _dragDiffY
    property real startX: 0
    property real startY: 0
    property real regionTopLeftX: Math.min(startX, startX + _dragDiffX)
    property real regionTopLeftY: Math.min(startY, startY + _dragDiffY)
    property real regionWidth: Math.abs(_dragDiffX)
    property real regionHeight: Math.abs(_dragDiffY)

    signal dragPressed(diffX: real, diffY: real)
    signal dragReleased(diffX: real, diffY: real)
    
    property bool dragging: false
    property real _dragDiffX: 0
    property real _dragDiffY: 0

    function resetDrag() {
        dragging = false
        _dragDiffX = 0
        _dragDiffY = 0
        gestureAxis = ""
    }

    function finishDrag() {
        const hadDrag = dragging || gestureAxis !== "";
        dragging = false;
        if (hadDrag)
            root.dragReleased(_dragDiffX, _dragDiffY);
        if (root.automaticallyReset)
            root.resetDrag();
    }

    onPressed: (mouse) => {
        if (!root.interactive) {
            if (mouse.button === Qt.LeftButton) {
                mouse.accepted = false;
            }
            return;
        }
        if (mouse.button === Qt.LeftButton) {
            root.resetDrag()
            startX = mouse.x
            startY = mouse.y
        }
    }
    onReleased: root.finishDrag()
    onPositionChanged: (mouse) => {
        if (!root.interactive) {
            return;
        }
        if (mouse.buttons & Qt.LeftButton) {
            root._dragDiffX = mouse.x - startX
            root._dragDiffY = mouse.y - startY
            if (root.axisLockEnabled && root.gestureAxis === ""
                    && Math.max(Math.abs(root._dragDiffX), Math.abs(root._dragDiffY)) >= root.axisLockThreshold) {
                root.gestureAxis = Math.abs(root._dragDiffX) > Math.abs(root._dragDiffY)
                    ? "horizontal" : "vertical";
            }
            root.dragPressed(_dragDiffX, _dragDiffY);
            root.dragging = true;
        }
    }
    onCanceled: root.finishDrag()
}
