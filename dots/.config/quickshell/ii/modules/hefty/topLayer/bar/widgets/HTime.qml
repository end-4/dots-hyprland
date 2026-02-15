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
                morphedPanelParent.addAttachedMaskItem(bgShape);
            } else {
                morphedPanelParent.removeAttachedMaskItem(bgShape);
            }
        }
    }
    Connections {
        target: morphedPanelParent
        function onFocusGrabDismissed() {
            root.showPopup = false;
        }
    }

    // Background container shape
    background: Shapes.ShapeCanvas {
        id: bgShape
        property real baseTopMargin: (parent.height - containerShape.height) / 2
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: {
                if (!root.atBottom || !root.showPopup) return baseTopMargin;
                else return baseTopMargin - popupShape.height - bgShape.spacing;
            }
        }
        width: root.showPopup ? Math.max(containerShape.width, popupShape.width) : containerShape.width
        height: root.showPopup ? (containerShape.height + popupShape.height + bgShape.spacing) : containerShape.height
        color: root.showPopup || progress < 1 ? C.Appearance.colors.colLayer3Base : C.Appearance.colors.colLayer1
        // color: "green"
        // debug: true
        xOffset: (width - containerShape.width) / 2
        yOffset: root.atBottom ? (height - containerShape.height) : 0
        animation: Anim {}

        Behavior on width {
            Anim {}
        }
        Behavior on height {
            Anim {}
        }
        Behavior on anchors.topMargin {
            Anim {}
        }

        // Rectangle {
        //     anchors.fill: parent
        // }

        polygonIsNormalized: false
        property real spacing: baseTopMargin * 2
        W.AxisRectangularContainerShape {
            id: containerShape
            width: containerRoot.backgroundWidth
            height: containerRoot.backgroundHeight
            startRadius: containerRoot.getBackgroundRadius(containerRoot.startSide)
            endRadius: containerRoot.getBackgroundRadius(containerRoot.endSide)
        }
        W.RectangularContainerShape {
            id: popupShape
            width: 400 // TODO
            height: 500 // TODO
            radius: C.Appearance.rounding.large
            xOffset: -(width - containerShape.width) / 2
            yOffset: root.atBottom ? -(popupShape.height + bgShape.spacing) : (containerShape.height + bgShape.spacing)
        }

        
        roundedPolygon: {
            if (!root.showPopup) return containerShape.getFullShape()
            // return popupShape.getFullShape(); // debug
            const points = [
                ...(root.atBottom ? containerShape.getFirstBottomPoints() : [
                    ...popupShape.getFirstBottomPoints(),
                    popupShape.getBottomLeftPoint(),
                    ...popupShape.leftPoints,
                    popupShape.getTopLeftPoint(),
                ]),
                containerShape.getBottomLeftPoint(0, bgShape.spacing * (!root.atBottom ? 1 : 0), containerShape.radiusLimit),
                // ...containerShape.leftPoints,
                containerShape.getTopLeftPoint(0, bgShape.spacing * (root.atBottom ? -1 : 0), containerShape.radiusLimit),
                ...(!root.atBottom ? containerShape.topPoints : [
                    popupShape.getBottomLeftPoint(),
                    ...popupShape.leftPoints,
                    popupShape.getTopLeftPoint(),
                    ...popupShape.topPoints,
                    popupShape.getTopRightPoint(),
                    ...popupShape.rightPoints,
                    popupShape.getBottomRightPoint(),
                ]),
                containerShape.getTopRightPoint(0, bgShape.spacing * (root.atBottom ? -1 : 0), containerShape.radiusLimit),
                // ...containerShape.rightPoints,
                containerShape.getBottomRightPoint(0, bgShape.spacing * (!root.atBottom ? 1 : 0), containerShape.radiusLimit),
                ...(root.atBottom ? containerShape.getLastBottomPoints() : [
                    popupShape.getTopRightPoint(),
                    ...popupShape.rightPoints,
                    popupShape.getBottomRightPoint(),
                    ...popupShape.getLastBottomPoints(),
                ]),
            ];
            return MaterialShapes.customPolygon(points);
        }

        component Anim: SpringAnimation {
            spring: 3.5
            damping: 0.35
        }
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
