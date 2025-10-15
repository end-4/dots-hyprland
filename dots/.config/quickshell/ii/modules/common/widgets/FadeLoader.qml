import QtQuick

import qs.modules.common
import qs.modules.common.widgets

Loader {
    id: root
    property bool shown: true
    opacity: shown ? 1 : 0
    visible: opacity > 0
    active: opacity > 0

    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
}
