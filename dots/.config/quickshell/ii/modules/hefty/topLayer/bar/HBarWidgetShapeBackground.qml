pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

import qs.modules.common as C
import qs.modules.common.widgets as W
import qs.modules.common.widgets.shapes as Shapes
import "../../../common/widgets/shapes/material-shapes.js" as MaterialShapes

// Notes
// vertical + atBottom = right side
// start radius = top or left, end radius = bottom or right
Shapes.ShapeCanvas {
    id: bgShape

    // Stuff fed from outside
    required property bool vertical
    required property bool atBottom
    required property bool showPopup
    required property real backgroundWidth
    required property real backgroundHeight
    property real popupContentWidth: 400
    property real popupContentHeight: 500
    property real popupPadding: 10
    property real popupWidth: popupContentWidth + popupPadding * 2
    property real popupHeight: popupContentHeight + popupPadding * 2
    required property real startRadius
    required property real endRadius
    property real baseMargin: {
        if (!vertical)
            return (parent.height - containerShape.height) / 2;
        else
            return (parent.width - containerShape.width) / 2;
    }

    property alias containerShape: containerShape
    property alias popupShape: popupShape

    // Popup constraints
    // mapToGlobal is not reactive so we gotta hook manually
    property real xInGlobal
    property real yInGlobal
    function updateXInGlobal() {
        xInGlobal = mapToGlobal(0, 0).x + xOffset;
    }
    function updateYInGlobal() {
        yInGlobal = mapToGlobal(0, 0).y + yOffset;
    }
    function updatePosInGlobal() {
        updateXInGlobal()
        updateYInGlobal()
    }
    Component.onCompleted: updatePosInGlobal()
    onXChanged: updatePosInGlobal()
    onYChanged: updatePosInGlobal()
    readonly property real minPopupXOffset: -xInGlobal + baseMargin
    readonly property real minPopupYOffset: -yInGlobal + baseMargin
    readonly property real maxPopupXOffset: {
        const maxPopupX = QsWindow.window.screen.width - popupWidth - baseMargin;
        const maxOffset = maxPopupX - xInGlobal;
        return maxOffset;
    }
    readonly property real maxPopupYOffset: {
        const maxPopupY = QsWindow.window.screen.height - popupHeight - baseMargin;
        const maxOffset = maxPopupY - yInGlobal;
        return maxOffset;
    }
    readonly property real popupXOffset: {
        if (!vertical) return Math.min(Math.max(-(popupWidth - containerShape.width) / 2, minPopupXOffset), maxPopupXOffset);
        else return atBottom ? -(popupShape.width + spacing) : (containerShape.width + spacing);
    }
    readonly property real popupYOffset: {
        if (!vertical) return atBottom ? -(popupShape.height + spacing) : (containerShape.height + spacing);
        else return Math.min(Math.max(-(popupHeight - containerShape.height) / 2, minPopupYOffset), maxPopupYOffset)
    }

    // Positioning
    readonly property real popupContentOffsetBase: -baseMargin + popupPadding
    readonly property real paddedContainerHeight: containerShape.height + baseMargin * 2
    readonly property real paddedContainerWidth: containerShape.width + baseMargin * 2
    readonly property real popupContentOffsetY: {
        if (!vertical) return paddedContainerHeight + spacing + popupContentOffsetBase + (atBottom ? -(popupHeight + backgroundHeight + spacing * 2) : 0)
        else return popupYOffset + popupContentOffsetBase;
    }
    readonly property real popupContentOffsetX: {
        if (!vertical) return popupXOffset + popupContentOffsetBase;
        else return paddedContainerWidth + spacing + popupContentOffsetBase + (atBottom ? -(popupWidth + backgroundWidth + spacing * 2) : 0);
    }

    anchors {
        left: parent.left
        leftMargin: {
            if (!vertical) return -xOffset;
            if (!bgShape.atBottom || !bgShape.showPopup) return baseMargin;
            return baseMargin - popupShape.width - bgShape.spacing;
        }
        top: parent.top
        topMargin: {
            if (vertical) return -yOffset;
            if (!bgShape.atBottom || !bgShape.showPopup) return baseMargin;
            return baseMargin - popupShape.height - bgShape.spacing;
        }
    }
    width: {
        if (!vertical) return bgShape.showPopup ? Math.max(backgroundWidth, popupWidth) : backgroundWidth;
        else return bgShape.showPopup ? (containerShape.width + popupShape.width + bgShape.spacing) : containerShape.width;
    }
    height: {
        if (!vertical) return bgShape.showPopup ? (containerShape.height + popupShape.height + bgShape.spacing) : containerShape.height;
        else return bgShape.showPopup ? Math.max(backgroundHeight, popupHeight) : backgroundHeight;
    }
    color: bgShape.showPopup || progress < 1 ? C.Appearance.colors.colLayer3Base : C.Appearance.colors.colLayer1
    xOffset: {
        if (!vertical) return showPopup ? -popupXOffset : 0;
        else return bgShape.atBottom ? (width - containerShape.width) : 0;
    }
    yOffset: {
        if (!vertical) return bgShape.atBottom ? (height - containerShape.height) : 0;
        else return showPopup ? -popupYOffset : 0;
    }
    animation: Anim {}

    Behavior on width {
        Anim {}
    }
    Behavior on height {
        Anim {}
    }
    Behavior on anchors.topMargin {
        animation: !bgShape.vertical ? animComp.createObject(this) : undefined
    }
    Behavior on anchors.leftMargin {
        animation: bgShape.vertical ? animComp.createObject(this) : undefined
    }
    Behavior on xOffset {
        animation: !bgShape.vertical ? animComp.createObject(this) : undefined
    }
    Behavior on yOffset {
        animation: bgShape.vertical ? animComp.createObject(this) : undefined
    }

    polygonIsNormalized: false
    property real spacing: baseMargin * 2
    W.AxisRectangularContainerShape {
        id: containerShape
        width: bgShape.backgroundWidth
        height: bgShape.backgroundHeight
        startRadius: bgShape.startRadius
        endRadius: bgShape.endRadius
        vertical: bgShape.vertical
    }
    W.RectangularContainerShape {
        id: popupShape
        width: bgShape.popupWidth
        height: bgShape.popupHeight
        radius: C.Appearance.rounding.large
        xOffset: bgShape.popupXOffset
        yOffset: bgShape.popupYOffset
    }

    roundedPolygon: {
        var points = [];
        if (!bgShape.showPopup) return containerShape.getFullShape();
        if (!bgShape.vertical) {    
            // Inline comment spam to mitigate qmlls' sabotaging of the (code) layout
            points = [
                ...(bgShape.atBottom ? containerShape.getFirstBottomPoints() : [ //
                    ...popupShape.getFirstBottomPoints(), popupShape.getBottomLeftPoint(),  //
                    ...popupShape.leftPoints,  //
                    popupShape.getTopLeftPoint(), //
                ]),  //
                containerShape.getBottomLeftPoint(0, bgShape.spacing * (!bgShape.atBottom ? 1 : 0), containerShape.radiusLimit), //
                containerShape.getTopLeftPoint(0, bgShape.spacing * (bgShape.atBottom ? -1 : 0), containerShape.radiusLimit),  //
                ...(!bgShape.atBottom ? containerShape.topPoints : [ //
                    popupShape.getBottomLeftPoint(), //
                    ...popupShape.leftPoints,  //
                    popupShape.getTopLeftPoint(),  //
                    ...popupShape.topPoints,  //
                    popupShape.getTopRightPoint(),  //
                    ...popupShape.rightPoints,  //
                    popupShape.getBottomRightPoint(), //
                ]),  //
                containerShape.getTopRightPoint(0, bgShape.spacing * (bgShape.atBottom ? -1 : 0), containerShape.radiusLimit), //
                containerShape.getBottomRightPoint(0, bgShape.spacing * (!bgShape.atBottom ? 1 : 0), containerShape.radiusLimit),  //
                ...(bgShape.atBottom ? containerShape.getLastBottomPoints() : [ //
                    popupShape.getTopRightPoint(),  //
                    ...popupShape.rightPoints,  //
                    popupShape.getBottomRightPoint(), //
                    ...popupShape.getLastBottomPoints(), //
                ]),
            ];
        } else {
            points = [ //
                ...containerShape.getFirstBottomPoints(), //
                containerShape.getBottomLeftPoint(), //
                ...(!bgShape.atBottom ? containerShape.leftPoints : [ //
                    containerShape.getBottomLeftPoint(-bgShape.spacing, 0, containerShape.radiusLimit), //
                    popupShape.getBottomRightPoint(), //
                    ...popupShape.bottomPoints, //
                    popupShape.getBottomLeftPoint(), //
                    ...popupShape.leftPoints, //
                    popupShape.getTopLeftPoint(), //
                    ...popupShape.topPoints, //
                    popupShape.getTopRightPoint(), //
                    containerShape.getTopLeftPoint(-bgShape.spacing, 0, containerShape.radiusLimit), //
                ]), //
                containerShape.getTopLeftPoint(), //
                ...containerShape.topPoints, //
                containerShape.getTopRightPoint(), //
                ...(bgShape.atBottom ? containerShape.rightPoints : [ //
                    containerShape.getTopRightPoint(bgShape.spacing, 0, containerShape.radiusLimit), //
                    popupShape.getTopLeftPoint(), //
                    ...popupShape.topPoints, //
                    popupShape.getTopRightPoint(), //
                    ...popupShape.rightPoints, //
                    popupShape.getBottomRightPoint(), //
                    ...popupShape.bottomPoints, //
                    popupShape.getBottomLeftPoint(), //
                    containerShape.getBottomRightPoint(bgShape.spacing, 0, containerShape.radiusLimit), //
                ]), //
                containerShape.getBottomRightPoint(), //
                ...containerShape.getLastBottomPoints(), //
            ];
        }
        return MaterialShapes.customPolygon(points);
    }

    component Anim: SpringAnimation {
        spring: 3.5
        damping: 0.3
    }

    Component {
        id: animComp
        Anim {}
    }
}
