pragma ComponentBehavior: Bound
import QtQuick

StyledButton {
    id: root

    property alias implicitSize: root.implicitHeight
    implicitWidth: implicitHeight
    property alias iconSize: icon.iconSize

    contentItem: Item {
        MaterialSymbol {
            id: icon
            anchors.centerIn: parent
            color: root.colForeground
            text: root.text
        }
    }
}
