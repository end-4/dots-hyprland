import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

BarButton {
    id: root

    rightInset: 12 // For now this is the rightmost button. Desktop peek is useless. (for now)
    padding: 12

    contentItem: Item {
        anchors.centerIn: root.background
        implicitHeight: column.implicitHeight
        implicitWidth: column.implicitWidth
        Column {
            id: column
            anchors.centerIn: parent
            WText {
                anchors.right: parent.right
                text: DateTime.time
            }
            WText {
                anchors.right: parent.right
                text: DateTime.date
            }
        }
    }
}
