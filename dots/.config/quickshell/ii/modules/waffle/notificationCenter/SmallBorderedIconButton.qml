import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

WBorderedButton {
    id: root
    implicitWidth: 24
    implicitHeight: 24
    contentItem: Item {
        FluentIcon {
            anchors.centerIn: parent
            implicitSize: 12
            icon: root.icon.name
            color: root.fgColor
        }
    }
}
