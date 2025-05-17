import "root:/modules/common/"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Switch {
    id: root
    property real scale: 1
    implicitHeight: 32 * root.scale
    implicitWidth: 52 * root.scale

    PointingHandInteraction {}

    // Custom track styling
    background: Rectangle {
        width: parent.width
        height: parent.height
        radius: Appearance.rounding.full
        color: root.checked ? Appearance.m3colors.m3primary : Appearance.m3colors.m3surfaceContainerHighest
        border.width: 2 * root.scale
        border.color: root.checked ? Appearance.m3colors.m3primary : Appearance.m3colors.m3outline

        Behavior on color {
            animation: Appearance.animation.elementMove.colorAnimation.createObject(this)
        }
        Behavior on border.color {
            animation: Appearance.animation.elementMove.colorAnimation.createObject(this)
        }
    }

    // Custom thumb styling
    indicator: Rectangle {
        width: root.pressed ? (28 * root.scale) : root.checked ? (24 * root.scale) : (16 * root.scale)
        height: root.pressed ? (28 * root.scale) : root.checked ? (24 * root.scale) : (16 * root.scale)
        radius: Appearance.rounding.full
        color: root.checked ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3outline
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: root.checked ? (root.pressed ? (22 * root.scale) : 24 * root.scale) : (root.pressed ? (2 * root.scale) : 8 * root.scale)

        Behavior on anchors.leftMargin {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
        Behavior on width {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
        Behavior on height {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
        Behavior on color {
            animation: Appearance.animation.elementMove.colorAnimation.createObject(this)
        }
    }
}
