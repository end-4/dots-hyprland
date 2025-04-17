import "root:/modules/common"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Button {
    id: button

    required default property Item content
    property bool extraActiveCondition: false

    PointingHandInteraction{}

    implicitHeight: Math.max(content.implicitHeight, 26, content.implicitHeight)
    implicitWidth: Math.max(content.implicitHeight, 26, content.implicitWidth)
    contentItem: content

    background: Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.full
        color: (button.down || extraActiveCondition) ? Appearance.colors.colLayer2Active : (button.hovered ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2)

        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementDecel.duration
                easing.type: Appearance.animation.elementDecel.type
            }

        }

    }

}
