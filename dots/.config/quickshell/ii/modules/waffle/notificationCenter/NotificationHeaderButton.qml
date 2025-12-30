import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.waffle.looks

WBorderlessButton {
    id: root
    Layout.fillWidth: false
    property real implicitSize: 16
    implicitWidth: implicitSize
    implicitHeight: implicitSize
    color: "transparent"
    colForeground: root.hovered && !root.pressed ? Looks.colors.fg : Looks.colors.fg1

    Behavior on colForeground {
        animation: Looks.transition.color.createObject(this)
    }

    contentItem: Item {
        FluentIcon {
            anchors.centerIn: parent
            implicitSize: root.implicitSize
            icon: root.icon.name
            color: root.colForeground
        }
    }
}
