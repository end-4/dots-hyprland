import QtQuick
import Quickshell
import qs.modules.waffle.looks

Item {
    id: root
    anchors.centerIn: parent
    required property Item realContentItem
    property alias radius: realContent.radius
    property real verticalPadding: 8
    property real horizontalPadding: 10
    implicitWidth: realContent.implicitWidth + 2 * 2
    implicitHeight: realContent.implicitHeight + 2 * 2

    WAmbientShadow {
        target: realContent
    }
    
    Rectangle {
        id: realContent
        z: 1
        anchors.centerIn: parent
        implicitWidth: root.realContentItem.implicitWidth + root.horizontalPadding * 2
        implicitHeight: root.realContentItem.implicitHeight + root.verticalPadding * 2
        color: Looks.colors.bg1Base
        radius: Looks.radius.medium

        children: [root.realContentItem]
    }
}
