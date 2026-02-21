pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.modules.common as C
import qs.modules.common.functions as F
import qs.services as S
import qs.modules.common.widgets as W
import qs.modules.common.widgets.shapes as Shapes
import "../../../common/widgets/shapes/material-shapes.js" as MaterialShapes
import "../../../common/widgets/shapes/shapes/corner-rounding.js" as CornerRounding
import "../../../common/widgets/shapes/geometry/offset.js" as Offset

// TODO: generalize this shi for vertical
Shapes.ShapeCanvas {
    id: bgShape

    required property bool vertical
    required property bool atBottom
    required property bool showPopup
    required property real backgroundWidth
    required property real backgroundHeight
    property real popupWidth: 400
    property real popupHeight: 500
    required property real startRadius
    required property real endRadius
    property real baseMargin: (parent.height - containerShape.height) / 2 // TODO vertical

    property alias containerShape: containerShape
    property alias popupShape: popupShape

    // mapToGlobal is not reactive so we gotta hook manually
    property real xInGlobal
    function updateXInGlobal() {
        xInGlobal = mapToGlobal(0, 0).x + xOffset;
    }
    Component.onCompleted: updateXInGlobal();
    onXChanged: updateXInGlobal();
    readonly property real minPopupXOffset: -xInGlobal + baseMargin
    readonly property real maxPopupXOffset: {
        const maxPopupX = QsWindow.window.screen.width - popupWidth - baseMargin;
        const maxOffset = maxPopupX - xInGlobal;
        return maxOffset
    }
    readonly property real popupXOffset: Math.min(Math.max(-(popupWidth - containerShape.width) / 2, minPopupXOffset), maxPopupXOffset)

    anchors {
        left: parent.left
        leftMargin: -xOffset
        top: parent.top
        topMargin: {
            if (!bgShape.atBottom || !bgShape.showPopup)
                return baseMargin;
            else
                return baseMargin - popupShape.height - bgShape.spacing;
        }
    }
    width: bgShape.showPopup ? Math.max(backgroundWidth, popupWidth) : backgroundWidth
    height: bgShape.showPopup ? (containerShape.height + popupShape.height + bgShape.spacing) : containerShape.height
    color: bgShape.showPopup || progress < 1 ? C.Appearance.colors.colLayer3Base : C.Appearance.colors.colLayer1
    xOffset: showPopup ? -popupXOffset : 0
    yOffset: bgShape.atBottom ? (height - containerShape.height) : 0
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
    Behavior on xOffset {
        Anim {}
    }

    polygonIsNormalized: false
    property real spacing: baseMargin * 2
    W.AxisRectangularContainerShape {
        id: containerShape
        width: bgShape.backgroundWidth
        height: bgShape.backgroundHeight
        startRadius: bgShape.startRadius
        endRadius: bgShape.endRadius
    }
    W.RectangularContainerShape {
        id: popupShape
        width: bgShape.popupWidth
        height: bgShape.popupHeight
        radius: C.Appearance.rounding.large
        xOffset: bgShape.popupXOffset
        yOffset: bgShape.atBottom ? -(popupShape.height + bgShape.spacing) : (containerShape.height + bgShape.spacing)
    }

    roundedPolygon: {
        if (!bgShape.showPopup)
            return containerShape.getFullShape();
        // return popupShape.getFullShape(); // debug
        const points = [...(bgShape.atBottom ? containerShape.getFirstBottomPoints() : [...popupShape.getFirstBottomPoints(), popupShape.getBottomLeftPoint(), ...popupShape.leftPoints, popupShape.getTopLeftPoint(),]), containerShape.getBottomLeftPoint(0, bgShape.spacing * (!bgShape.atBottom ? 1 : 0), containerShape.radiusLimit),
            // ...containerShape.leftPoints,
            containerShape.getTopLeftPoint(0, bgShape.spacing * (bgShape.atBottom ? -1 : 0), containerShape.radiusLimit), ...(!bgShape.atBottom ? containerShape.topPoints : [popupShape.getBottomLeftPoint(), ...popupShape.leftPoints, popupShape.getTopLeftPoint(), ...popupShape.topPoints, popupShape.getTopRightPoint(), ...popupShape.rightPoints, popupShape.getBottomRightPoint(),]), containerShape.getTopRightPoint(0, bgShape.spacing * (bgShape.atBottom ? -1 : 0), containerShape.radiusLimit),
            // ...containerShape.rightPoints,
            containerShape.getBottomRightPoint(0, bgShape.spacing * (!bgShape.atBottom ? 1 : 0), containerShape.radiusLimit), ...(bgShape.atBottom ? containerShape.getLastBottomPoints() : [popupShape.getTopRightPoint(), ...popupShape.rightPoints, popupShape.getBottomRightPoint(), ...popupShape.getLastBottomPoints(),]),];
        return MaterialShapes.customPolygon(points);
    }

    component Anim: SpringAnimation {
        spring: 3.5
        damping: 0.35
    }
}
