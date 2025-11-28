import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.waffle.looks

WBorderlessButton {
    id: headerButton
    Layout.fillWidth: false
    implicitWidth: 16
    implicitHeight: 16
    color: "transparent"

    contentItem: Item {
        FluentIcon {
            anchors.centerIn: parent
            implicitSize: 16
            icon: headerButton.icon.name
            color: headerButton.hovered && !headerButton.pressed ? Looks.colors.fg : Looks.colors.fg1
        }
    }
}
