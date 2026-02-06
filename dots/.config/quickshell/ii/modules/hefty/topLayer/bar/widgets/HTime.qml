pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.modules.common as C
import qs.modules.common.functions as F
import qs.services as S
import qs.modules.common.widgets as W

W.ButtonMouseArea {
    id: root

    property bool vertical: C.Config.options.bar.vertical
    property bool showPopup: false

    property var layoutParent: F.ObjectUtils.findParentWithProperty(root, "startSide")
    property real layoutParentTopLeftRadius: layoutParent.topLeftRadius
    property real layoutParentTopRightRadius: layoutParent.topRightRadius
    property real layoutParentBottomLeftRadius: layoutParent.bottomLeftRadius
    property real layoutParentBottomRightRadius: layoutParent.bottomRightRadius

    readonly property real barThickness: vertical ? C.Appearance.sizes.verticalBarWidth : C.Appearance.sizes.barHeight
    property var activeContent: vertical ? verticalContent : horizontalContent
    property real parentRadiusToPaddingRatio: 0.3
    implicitWidth: vertical ? barThickness : (activeContent.implicitWidth + (layoutParentTopLeftRadius + layoutParentBottomRightRadius) * parentRadiusToPaddingRatio)
    implicitHeight: !vertical ? barThickness : (activeContent.implicitHeight + (layoutParentTopLeftRadius + layoutParentBottomRightRadius) * parentRadiusToPaddingRatio)
    Layout.alignment: vertical ? Qt.AlignHCenter : Qt.AlignVCenter
    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical

    onClicked: showPopup = !showPopup

    W.StateOverlay {
        id: hoverOverlay
        anchors.fill: parent
        property real parentMargins: 4
        property real ownMargins: 2
        property real edgeMargins: parentMargins + ownMargins
        property real sideMargins: -2
        anchors {
            leftMargin: root.vertical ? edgeMargins : sideMargins
            rightMargin: root.vertical ? edgeMargins : sideMargins
            topMargin: root.vertical ? sideMargins : edgeMargins
            bottomMargin: root.vertical ? sideMargins : edgeMargins
        }
        topLeftRadius: root.layoutParentTopLeftRadius - ownMargins
        topRightRadius: root.layoutParentTopRightRadius - ownMargins
        bottomLeftRadius: root.layoutParentBottomLeftRadius - ownMargins
        bottomRightRadius: root.layoutParentBottomRightRadius - ownMargins

        hover: root.containsMouse
        press: root.containsPress
    }

    W.FadeLoader {
        id: horizontalContent
        anchors.fill: parent
        shown: !root.vertical
        sourceComponent: RowLayout {
            anchors.fill: parent

            W.StyledText {
                Layout.leftMargin: root.layoutParentTopLeftRadius * root.parentRadiusToPaddingRatio
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: C.Appearance.font.pixelSize.large
                color: C.Appearance.colors.colOnLayer1
                text: S.DateTime.time
            }

            W.StyledText {
                Layout.alignment: Qt.AlignVCenter
                font.pixelSize: C.Appearance.font.pixelSize.small
                color: C.Appearance.colors.colOnLayer1
                text: "•"
            }

            W.StyledText {
                Layout.alignment: Qt.AlignVCenter
                font.pixelSize: C.Appearance.font.pixelSize.small
                color: C.Appearance.colors.colOnLayer1
                text: S.DateTime.longDate
            }
        }
    }

    W.FadeLoader {
        id: verticalContent
        anchors.fill: parent
    }
}
