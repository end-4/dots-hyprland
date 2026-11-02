import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    property string icon
    property string label
    signal clicked()

    implicitHeight: 64
    radius: Appearance.rounding.small
    color: !enabled ? Appearance.colors.colLayer1
        : area.containsMouse ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer2
    opacity: enabled ? 1 : 0.45
    Behavior on color { ColorAnimation { duration: 120 } }
    scale: area.pressed ? 0.95 : 1
    Behavior on scale { NumberAnimation { duration: 80 } }

    Column {
        anchors.centerIn: parent
        spacing: 2
        MaterialSymbol {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            iconSize: 22
            color: Appearance.m3colors.m3primary
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            color: Appearance.colors.colOnLayer1
            font.pixelSize: Appearance.font.pixelSize.smaller
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
