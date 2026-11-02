import QtQuick
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    property string icon
    property string label
    property color tint: Appearance.colors.colOnLayer1

    implicitHeight: 26
    implicitWidth: row.implicitWidth + 16
    radius: height / 2
    color: Appearance.colors.colLayer2

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4
        MaterialSymbol {
            text: root.icon
            iconSize: 15
            color: root.tint
            anchors.verticalCenter: parent.verticalCenter
        }
        StyledText {
            text: root.label
            color: Appearance.colors.colOnLayer1
            font.pixelSize: Appearance.font.pixelSize.smaller
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
