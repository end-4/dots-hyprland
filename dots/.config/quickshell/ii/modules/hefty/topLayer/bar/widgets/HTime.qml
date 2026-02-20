pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.modules.common as C
import qs.modules.common.functions as F
import qs.services as S
import qs.modules.common.widgets as W
import qs.modules.common.widgets.shapes as Shapes
import ".."
import "../../../../common/widgets/shapes/material-shapes.js" as MaterialShapes
import "../../../../common/widgets/shapes/shapes/corner-rounding.js" as CornerRounding
import "../../../../common/widgets/shapes/geometry/offset.js" as Offset

HBarWidgetContainer {
    id: containerRoot

    // Interactions
    property var morphedPanelParent: F.ObjectUtils.findParentWithProperty(root, "maskItems")
    Connections {
        target: root
        function onShowPopupChanged() {
            if (root.showPopup) {
                containerRoot.morphedPanelParent.addAttachedMaskItem(bgShape);
            } else {
                containerRoot.morphedPanelParent.removeAttachedMaskItem(bgShape);
            }
        }
    }
    Connections {
        target: containerRoot.morphedPanelParent
        function onFocusGrabDismissed() {
            root.showPopup = false;
        }
    }

    // Background container shape
    background: HBarWidgetShapeBackground {
        id: bgShape

        atBottom: root.atBottom
        showPopup: root.showPopup
        backgroundWidth: containerRoot.backgroundWidth
        backgroundHeight: containerRoot.backgroundHeight
        startRadius: containerRoot.getBackgroundRadius(containerRoot.startSide)
        endRadius: containerRoot.getBackgroundRadius(containerRoot.endSide)
        baseMargin: (parent.height - containerShape.height) / 2 // TODO vertical
    }

    // The button on the bar
    W.ButtonMouseArea {
        id: root

        property bool vertical: C.Config.options.bar.vertical
        property bool atBottom: C.Config.options.bar.bottom
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

            sourceComponent: Item {
                anchors.fill: parent
                implicitWidth: contentLayout.implicitWidth
                implicitHeight: contentLayout.implicitHeight

                RowLayout {
                    id: contentLayout
                    anchors.fill: parent

                    W.VisuallyCenteredStyledText {
                        Layout.leftMargin: root.layoutParentTopLeftRadius * root.parentRadiusToPaddingRatio
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        Layout.fillHeight: true
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
        }

        W.FadeLoader {
            id: verticalContent
            anchors.fill: parent
        }
    }
}
