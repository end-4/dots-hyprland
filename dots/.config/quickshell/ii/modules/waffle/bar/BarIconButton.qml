import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.waffle.looks
import qs.modules.waffle.bar

BarButton {
    id: root

    property alias iconName: iconContent.icon
    property alias iconSource: iconContent.source
    property alias iconSize: iconContent.implicitSize
    property alias iconRotation: iconContent.rotation
    property alias iconMonochrome: iconContent.monochrome
    property alias iconScale: iconContent.scale
    property alias tooltipText: tooltip.text
    property alias overlayingItems: iconContent.data

    implicitWidth: 32

    contentItem: Item {
        anchors.centerIn: parent
        implicitWidth: iconContent.implicitWidth
        implicitHeight: iconContent.implicitHeight

        FluentIcon {
            id: iconContent
            anchors.centerIn: parent
            implicitSize: 16
            icon: root.iconName
            monochrome: false
        }
    }

    BarToolTip {
        id: tooltip
        extraVisibleCondition: root.shouldShowTooltip && text !== ""
    }
}
