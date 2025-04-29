import "root:/modules/common"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Button {
    id: button

    property string buttonText
    implicitHeight: 36
    implicitWidth: buttonTextWidget.implicitWidth + 14 * 2

    PointingHandInteraction {}

    background: Rectangle {
        anchors.fill: parent
        color: (button.down && button.enabled) ? Appearance.transparentize(Appearance.m3colors.m3onSurface, 0.84) : 
            ((button.hovered && button.enabled) ? Appearance.transparentize(Appearance.m3colors.m3onSurface, 0.92) : 
            Appearance.transparentize(Appearance.m3colors.m3onSurface, 1))

        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementDecel.duration
                easing.type: Appearance.animation.elementDecel.type
            }

        }

    }

    contentItem: StyledText {
        id: buttonTextWidget
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        text: buttonText
        horizontalAlignment: Text.AlignLeft
        font.pixelSize: Appearance.font.pixelSize.small
        color: button.enabled ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3outline

        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementDecel.duration
                easing.type: Appearance.animation.elementDecel.type
            }
        }
    }

}
