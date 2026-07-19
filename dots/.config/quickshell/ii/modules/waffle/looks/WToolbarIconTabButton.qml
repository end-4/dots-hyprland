import QtQuick
import QtQuick.Controls
import qs.modules.common

TabButton {
    id: root

    implicitWidth: 38
    implicitHeight: 32
    padding: 0

    background: null
    contentItem: Item {
        FluentIcon {
            anchors.centerIn: parent
            icon: root.icon.name
            color: root.icon.color
            implicitSize: 18
        }
    }
}
