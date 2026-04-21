import QtQuick
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.functions

TabBar {
    id: root
    implicitHeight: 32

    background: Rectangle {
        radius: Looks.radius.medium
        color: Looks.colors.bgPanelFooter
        border.color: ColorUtils.transparentize(Looks.colors.bg0Border, 0.7)
        border.width: 1

        // Indicator
        Rectangle {
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                leftMargin: root.currentIndex * (root.width / root.count)
                Behavior on leftMargin {
                    animation: Looks.transition.resize.createObject(this)
                }
            }
            radius: Looks.radius.medium
            color: Looks.colors.bg2Base
            border.color: Looks.colors.bg0Border
            border.width: 1
            width: root.width / root.count

            Rectangle {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: 1
                }
                implicitWidth: pressDetector.containsPress ? 16 : 12
                implicitHeight: 3
                radius: height / 2
                color: Looks.colors.accent
            }
        }
    }

    MouseArea {
        id: pressDetector
        z: 9999
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
    }
}
