import QtQuick
import qs.modules.common
import qs.modules.common.widgets

// Tarjeta compacta (cabe 4 en una fila del sidebar).
DashCard {
    id: root
    property string title
    property string icon
    property string value
    property var history: []
    property real histMax: 100
    property color accent: Appearance.m3colors.m3primary

    Row {
        id: head
        anchors { left: parent.left; top: parent.top; leftMargin: 10; topMargin: 9 }
        spacing: 4
        MaterialSymbol {
            text: root.icon
            iconSize: 14
            color: root.accent
            anchors.verticalCenter: parent.verticalCenter
        }
        StyledText {
            text: root.title
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.smaller
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    StyledText {
        anchors { left: parent.left; top: head.bottom; leftMargin: 10; topMargin: 2 }
        text: root.value
        color: Appearance.colors.colOnLayer1
        font.pixelSize: Appearance.font.pixelSize.larger
    }
    Sparkline {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 26
        lineWidth: 1.5
        values: root.history
        maxValue: root.histMax
        lineColor: root.accent
    }
}
