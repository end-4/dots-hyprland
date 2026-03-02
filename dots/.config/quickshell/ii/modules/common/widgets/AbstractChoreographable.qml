pragma ComponentBehavior: Bound
import QtQuick
import ".."

Item {
    id: root

    property real progress: 0
    default property Item child
    implicitWidth: child.implicitWidth
    implicitHeight: child.implicitHeight

    children: [child]

    property var animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
    Behavior on progress {
        animation: root.animation
    }
}
