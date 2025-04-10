import "../"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Button {
    id: button
    implicitWidth: 26
    implicitHeight: 26

    required default property Item content
    property bool extraActiveCondition: false

    contentItem: content

    background: Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.full
        color: (button.down || extraActiveCondition) ? Appearance.colors.colLayer2Active : (button.hovered ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2)
    }

}
