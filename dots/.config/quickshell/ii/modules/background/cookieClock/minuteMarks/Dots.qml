pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Item {
    id: root
    property real implicitSize: 12
    property real margins: 10
    property color color: Appearance.colors.colOnSecondaryContainer

    Repeater {
        model: 12

        Item {
            required property int index
            anchors.fill: parent // Ensures rotation works properly
            rotation: 360 / 12 * index

            Rectangle {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: root.margins
                }
                implicitWidth: root.implicitSize
                implicitHeight: implicitWidth
                radius: implicitWidth / 2
                color: root.color
            }
        }
    }
}
