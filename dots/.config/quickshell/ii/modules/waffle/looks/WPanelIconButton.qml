import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.waffle.looks
import qs.modules.waffle.bar

WButton {
    id: root

    property alias iconName: iconContent.icon
    property alias monochrome: iconContent.monochrome
    inset: 0
    implicitWidth: 40
    implicitHeight: 40

    contentItem: FluentIcon {
        id: iconContent
        anchors.centerIn: parent
        implicitSize: 18
        icon: root.iconName
    }
}
