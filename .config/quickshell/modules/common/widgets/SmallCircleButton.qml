import "../"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Button {
    id: button

    required default property Item content
    property bool extraActiveCondition: false

    implicitWidth: 26
    implicitHeight: 26
    contentItem: content

    background: Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.full
        color: (button.down || extraActiveCondition) ? Appearance.colors.colLayer2Active : (button.hovered ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2)

        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementDecel.duration
                easing.type: Appearance.animation.elementDecel.type
                easing.bezierCurve: Appearance.animation.elementDecel.bezierCurve
            }

        }

    }

}
