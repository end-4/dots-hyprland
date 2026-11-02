import QtQuick
import qs.modules.common

// Tarjeta base: fondo redondeado + hover + clic. Los hijos van dentro de `holder`.
Rectangle {
    id: root
    property bool hoverable: true
    signal clicked()
    default property alias content: holder.data

    radius: Appearance.rounding.normal
    color: hoverable && mouse.containsMouse ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1
    Behavior on color { ColorAnimation { duration: 120 } }
    clip: true
    scale: mouse.pressed ? 0.985 : 1
    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

    Item { id: holder; anchors.fill: parent }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.hoverable
        cursorShape: root.hoverable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
