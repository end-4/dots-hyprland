import QtQuick
import qs.modules.common
import qs.modules.common.widgets

// Small rounded text button used on island cards.
Rectangle {
    id: root
    property string text: ""
    property bool primary: false
    property color accent: Appearance.colors.colPrimary
    signal clicked()

    implicitWidth: label.implicitWidth + 22
    implicitHeight: 28
    radius: height / 2
    color: primary ? accent : (area.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2)

    StyledText {
        id: label
        anchors.centerIn: parent
        text: root.text
        font.pixelSize: Appearance.font.pixelSize.smaller
        font.weight: root.primary ? Font.DemiBold : Font.Normal
        color: root.primary ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
