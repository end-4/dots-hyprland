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

    readonly property var layoutParent: F.ObjectUtils.findParentWithProperty(root, "startSide")
    readonly property real layoutParentTopLeftRadius: layoutParent.topLeftRadius
    readonly property real layoutParentTopRightRadius: layoutParent.topRightRadius
    readonly property real layoutParentBottomLeftRadius: layoutParent.bottomLeftRadius
    readonly property real layoutParentBottomRightRadius: layoutParent.bottomRightRadius

    readonly property real barThickness: vertical ? C.Appearance.sizes.verticalBarWidth : C.Appearance.sizes.barHeight
    readonly property real barVisualThickness: vertical ? C.Appearance.sizes.baseVerticalBarWidth : C.Appearance.sizes.baseBarHeight
    readonly property real barGap: (barThickness - barVisualThickness) / 2
    required property real contentImplicitWidth
    required property real contentImplicitHeight
    property real parentRadiusToPaddingRatio: 0.3
    implicitWidth: {
        if (vertical) {
            return barThickness;
        } else {
            const roundingPadding = (layoutParentTopLeftRadius + layoutParentBottomRightRadius) * parentRadiusToPaddingRatio;
            return (contentImplicitWidth + roundingPadding + 4 * 2);
        }
    }
    implicitHeight: {
        if (!vertical) {
            return barThickness;
        } else {
            const roundingPadding = (layoutParentTopLeftRadius + layoutParentBottomRightRadius) * parentRadiusToPaddingRatio;
            return (contentImplicitHeight + roundingPadding + 4 * 2);
        }
    }
    Layout.alignment: vertical ? Qt.AlignHCenter : Qt.AlignVCenter
    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical

    property alias hover: hoverOverlay.hover
    property alias press: hoverOverlay.press

    W.StateOverlay {
        id: hoverOverlay
        anchors.fill: parent
        property real parentMargins: 4 + root.barGap
        property real ownMargins: 2
        property real edgeMargins: parentMargins + ownMargins
        property real sideMargins: 2
        anchors {
            leftMargin: (root.vertical ? edgeMargins : sideMargins) + parentMargins * (!root.vertical && root.layoutParent.startSide)
            rightMargin: (root.vertical ? edgeMargins : sideMargins) + parentMargins * (!root.vertical && root.layoutParent.endSide)
            topMargin: (root.vertical ? sideMargins : edgeMargins) + parentMargins * (root.vertical && root.layoutParent.startSide)
            bottomMargin: (root.vertical ? sideMargins : edgeMargins) + parentMargins * (root.vertical && root.layoutParent.endSide)
        }
        topLeftRadius: root.layoutParentTopLeftRadius - ownMargins
        topRightRadius: root.layoutParentTopRightRadius - ownMargins
        bottomLeftRadius: root.layoutParentBottomLeftRadius - ownMargins
        bottomRightRadius: root.layoutParentBottomRightRadius - ownMargins

        hover: root.containsMouse
        press: root.containsPress
    }
}
