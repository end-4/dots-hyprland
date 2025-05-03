import "root:/modules/common"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Button {
    id: button

    property string buttonText
    implicitHeight: 30
    implicitWidth: buttonTextWidget.implicitWidth + 15 * 2

    PointingHandInteraction {}

    background: Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.full
        color: (button.down && button.enabled) ? Appearance.colors.colLayer1Active : ((button.hovered && button.enabled) ? Appearance.colors.colLayer1Hover : Appearance.transparentize(Appearance.m3colors.m3surfaceContainerHigh, 1))

        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
            }

        }

    }

    contentItem: StyledText {
        id: buttonTextWidget
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15
        text: buttonText
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Appearance.font.pixelSize.small
        color: button.enabled ? Appearance.m3colors.m3primary : Appearance.m3colors.m3outline

        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
            }
        }
    }

}
