pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Item {
    property int bubbleIndex: 0
    property real targetSize: 0

    MaterialCookie {
        z: 5
        sides: bubbleIndex === 0 ? 4 : 1
        anchors.centerIn: parent
        color: bubbleIndex === 0.0 ? Appearance.colors.colPrimaryContainer : Appearance.colors.colTertiaryContainer
        implicitSize: targetSize
        constantlyRotate: Config.options.background.clock.cookie.constantlyRotate
    }
    StyledText {
        z: 6
        anchors.centerIn: parent
        text: bubbleIndex === 0.0 ? DateTime.date.substring(5, 7) : DateTime.date.substring(8, 10)
        color: bubbleIndex === 0.0 ? Appearance.colors.colPrimary : Appearance.colors.colTertiary
        opacity: root.style === "bubble" ? 1.0 : 0
        font {
            family: Appearance.font.family.expressive
            pixelSize: 30
            weight: 1000
        }
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }
}