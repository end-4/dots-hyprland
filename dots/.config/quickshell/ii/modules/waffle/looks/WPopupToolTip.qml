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

    required property Item realContentItem
    realContentItem: WText {
        text: root.text
        anchors.centerIn: parent
    }

    property real visualMargin: 11
    verticalPadding: 8
    horizontalPadding: 10
    verticalMargin: visualMargin
    horizontalMargin: visualMargin

    contentItem: WToolTipContent {
        id: tooltipContent
        realContentItem: root.realContentItem
        horizontalPadding: root.horizontalPadding
        verticalPadding: root.verticalPadding
    }
}
