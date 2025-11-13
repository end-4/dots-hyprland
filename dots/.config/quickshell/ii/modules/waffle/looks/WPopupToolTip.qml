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

    property real padding: 2
    verticalPadding: padding
    horizontalPadding: padding

    contentItem: Item {
        anchors.centerIn: parent
        implicitWidth: realContent.implicitWidth + root.verticalPadding * 2
        implicitHeight: realContent.implicitHeight + root.horizontalPadding * 2

        Rectangle {
            id: ambientShadow
            z: 0
            anchors {
                fill: realContent
                margins: -border.width
            }
            border.color: ColorUtils.transparentize(Looks.colors.bg0Border, Looks.shadowTransparency)
            border.width: 1
            color: "transparent"
            radius: realContent.radius + border.width
        }
        
        Rectangle {
            id: realContent
            z: 1
            anchors.centerIn: parent
            implicitWidth: tooltipText.implicitWidth + 10 * 2
            implicitHeight: tooltipText.implicitHeight + 8 * 2
            color: Looks.colors.bg1
            radius: Looks.radius.medium

            WText {
                id: tooltipText
                text: root.text
                anchors.centerIn: parent
            }
        }
    }
}
