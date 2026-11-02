import QtQuick
import qs.modules.common
import qs.modules.common.widgets

// Boton en forma de pastilla (icono + texto).
Rectangle {
    id: root
    property string icon
    property string label
    property bool danger: false
    signal clicked()

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 30
    radius: 15
    color: area.containsMouse ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1
    opacity: enabled ? 1 : 0.45
    Behavior on color { ColorAnimation { duration: 100 } }
    scale: area.pressed ? 0.94 : 1
    Behavior on scale { NumberAnimation { duration: 80 } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5
        MaterialSymbol {
            text: root.icon
            iconSize: 16
            color: root.danger ? Appearance.m3colors.m3error : Appearance.m3colors.m3primary
            anchors.verticalCenter: parent.verticalCenter
        }
        StyledText {
            text: root.label
            color: Appearance.colors.colOnLayer1
            font.pixelSize: Appearance.font.pixelSize.smaller
            anchors.verticalCenter: parent.verticalCenter
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
