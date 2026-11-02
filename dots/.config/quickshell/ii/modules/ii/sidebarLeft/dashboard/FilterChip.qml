import QtQuick
import qs.modules.common
import qs.modules.common.widgets

// Pestaña / filtro en forma de pastilla.
Rectangle {
    id: root
    property string label
    property bool selected: false
    signal clicked()

    implicitWidth: txt.implicitWidth + 24
    implicitHeight: 32
    radius: 16
    color: selected ? Appearance.m3colors.m3primary
        : area.containsMouse ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1
    scale: area.pressed ? 0.95 : 1
    Behavior on scale { NumberAnimation { duration: 80 } }

    StyledText {
        id: txt
        anchors.centerIn: parent
        text: root.label
        color: root.selected ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
        font.pixelSize: Appearance.font.pixelSize.smaller
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
