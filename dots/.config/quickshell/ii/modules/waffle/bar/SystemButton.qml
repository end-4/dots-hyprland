import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

BarButton {
    id: root

    // padding: 12

    contentItem: Item {
        anchors.centerIn: root.background
        implicitHeight: column.implicitHeight
        implicitWidth: column.implicitWidth
        Row {
            id: column
            anchors.centerIn: parent
            
            FluentIcon {
                icon: "speaker" // System icon
            }
        }
    }
}
