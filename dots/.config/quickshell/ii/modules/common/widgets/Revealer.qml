import qs.modules.common
import QtQuick

/**
 * Recreation of GTK revealer. Expects one single child.
 */
Item {
    id: root
    property bool reveal
    property bool vertical: false
    clip: true

    width: (reveal || vertical) ? childrenRect.width : 0
    height: childrenRect.height
    visible: reveal || (width > 0 && height > 0)

    Behavior on width {
        enabled: !vertical
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }
    Behavior on height {
        enabled: vertical
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }
}
