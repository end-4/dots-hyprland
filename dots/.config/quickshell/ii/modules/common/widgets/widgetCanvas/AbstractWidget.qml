import QtQuick
import Quickshell
import qs.modules.common

/*
 * Widget to be placed on a WidgetCanvas
 */
MouseArea {
    id: root

    property bool draggable: true
    drag.target: draggable ? root : undefined
    cursorShape: (draggable && containsPress) ? Qt.ClosedHandCursor : draggable ? Qt.OpenHandCursor : Qt.ArrowCursor

    function center() {
        root.x = (root.parent.width - root.width) / 2
        root.y = (root.parent.height - root.height) / 2
    }

    Behavior on x {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }
    Behavior on y {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }
}
