pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Rectangle {
    z: 1
    color: root.colBackground
    radius: Appearance.rounding.small
    StyledText {
        opacity: root.style === "rect" ? 1.0 : 0
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        anchors.centerIn: parent
        color: Appearance.colors.colSecondaryHover
        text: DateTime.date.substring(5, 7)
        font {
            family: Appearance.font.family.expressive
            pixelSize: 20
            weight: 1000
        }
    }
}