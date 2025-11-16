import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

PopupToolTip {
    id: root

    property Item realContentItem
    realContentItem: WText {
        text: root.text
        anchors.centerIn: parent
    }

    property real visualMargin: 11
    verticalPadding: visualMargin
    horizontalPadding: visualMargin
    property real realContentVerticalPadding: 8
    property real realContentHorizontalPadding: 10

    contentItem: Item {
        anchors.centerIn: parent
        implicitWidth: realContent.implicitWidth + 2 * 2
        implicitHeight: realContent.implicitHeight + 2 * 2

        Rectangle {
            id: ambientShadow
            z: 0
            anchors {
                fill: realContent
                margins: -border.width
            }
            border.color: ColorUtils.transparentize(Looks.colors.ambientShadow, Looks.shadowTransparency)
            border.width: 1
            color: "transparent"
            radius: realContent.radius + border.width
        }
        
        Rectangle {
            id: realContent
            z: 1
            anchors.centerIn: parent
            implicitWidth: root.realContentItem.implicitWidth + root.realContentHorizontalPadding * 2
            implicitHeight: root.realContentItem.implicitHeight + root.realContentVerticalPadding * 2
            color: Looks.colors.bg1
            radius: Looks.radius.medium

            children: [root.realContentItem]
        }
    }
}
