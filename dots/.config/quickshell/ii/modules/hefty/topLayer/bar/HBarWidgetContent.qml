pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.modules.common as C
import qs.modules.common.functions as F
import qs.modules.common.widgets as W
import ".."

W.ButtonMouseArea {
    id: root

    required property bool vertical
    required property bool atBottom
    required property bool showPopup

    property var layoutParent: F.ObjectUtils.findParentWithProperty(root, "startSide")
    property real layoutParentTopLeftRadius: layoutParent.topLeftRadius
    property real layoutParentTopRightRadius: layoutParent.topRightRadius
    property real layoutParentBottomLeftRadius: layoutParent.bottomLeftRadius
    property real layoutParentBottomRightRadius: layoutParent.bottomRightRadius

    readonly property real barThickness: vertical ? C.Appearance.sizes.verticalBarWidth : C.Appearance.sizes.barHeight
    required property real contentImplicitWidth
    required property real contentImplicitHeight
    property real parentRadiusToPaddingRatio: 0.3
    implicitWidth: vertical ? barThickness : (contentImplicitWidth + (layoutParentTopLeftRadius + layoutParentBottomRightRadius) * parentRadiusToPaddingRatio)
    implicitHeight: !vertical ? barThickness : (contentImplicitHeight + (layoutParentTopLeftRadius + layoutParentBottomRightRadius) * parentRadiusToPaddingRatio)
    Layout.alignment: vertical ? Qt.AlignHCenter : Qt.AlignVCenter
    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical

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
}
