import QtQuick

import qs.modules.common
import qs.modules.common.widgets

Loader {
    id: root
    property bool shown: true
    property alias fade: opacityBehavior.enabled
    opacity: shown ? 1 : 0
    visible: opacity > 0
    active: opacity > 0

    Behavior on opacity {
        id: opacityBehavior
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
}
