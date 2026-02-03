import QtQuick
import Quickshell
import qs.modules.common

Item {
    id: root

    property alias load: loader.activeAsync
    property bool shown: true // By default show immediately when loaded
    property alias component: loader.component

    property alias fade: opacityBehavior.enabled
    property alias animation: opacityBehavior.animation

    opacity: loader.active && shown ? 1 : 0
    visible: opacity > 0
    Behavior on opacity {
        id: opacityBehavior
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    LazyLoader {
        id: loader
    }
}
