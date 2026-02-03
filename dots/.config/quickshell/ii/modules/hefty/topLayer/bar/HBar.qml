pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import "../../../common/widgets/shapes/material-shapes.js" as MaterialShapes
import "../../../common/widgets/shapes/shapes/corner-rounding.js" as CornerRounding
import "../../../common/widgets/shapes/geometry/offset.js" as Offset
import ".."

HAbstractMorphedPanel {
    id: root

    // Own props
    property int barHeight: Appearance.sizes.baseBarHeight
    function getRounding(cornerStyle) {
        switch(cornerStyle) {
            case 0: return Appearance.rounding.screenRounding;
            case 1: return Appearance.rounding.windowRounding;
            case 2: return 0;
            default: return Appearance.rounding.screenRounding;
        }
    }
    function getEdgeGap(cornerStyle) {
        switch(cornerStyle) {
            case 0: return 0;
            case 1: return Appearance.sizes.hyprlandGapsOut;
            case 2: return 0;
            default: return 0;
        }
    }
    function getEdgeRounding(cornerStyle) {
        switch(cornerStyle) {
            case 0: return 0;
            case 1: return Appearance.rounding.windowRounding;
            case 2: return 0;
            default: return Appearance.rounding.windowRounding;
        }
    }
    function getHug(cornerStyle) {
        return cornerStyle === 0;
    }
    property int reservedArea: barHeight + getEdgeGap(Config.options.bar.cornerStyle)

    // Some info
    reservedTop: Config.options.bar.bottom ? 0 : reservedArea
    reservedBottom: Config.options.bar.bottom ? reservedArea : 0

    // Background
    backgroundPolygon: {
        // It's certainly cleaner to have the below props declared outside, but we do this
        // to make sure a config change only makes this re-evaluate exactly once
        const bottom = Config.options.bar.bottom
        const cornerStyle = Config.options.bar.cornerStyle
        const rounding = root.getRounding(cornerStyle)
        const edgeGap = root.getEdgeGap(cornerStyle)
        const edgeRounding = root.getEdgeRounding(cornerStyle)
        const hug = root.getHug(cornerStyle)
        const xLeft = edgeGap
        const xRight = root.screenWidth - edgeGap
        const yTop = bottom ? (root.screenHeight - edgeGap - barHeight) : edgeGap
        const yBottom = bottom ? (root.screenHeight - edgeGap) : (edgeGap + barHeight)
        const topRounding = bottom ? rounding : edgeRounding
        const bottomRounding = bottom ? edgeRounding : rounding
        var topCornerDirection, bottomCornerDirection;
        if (cornerStyle === 2) { // Rect
            topCornerDirection = 0;
            bottomCornerDirection = 0;
        } else if (cornerStyle === 1) { // Rect
            topCornerDirection = 1;
            bottomCornerDirection = -1;
        } else { // Hug
            topCornerDirection = bottom ? -1 : 1;
            bottomCornerDirection = bottom ? -1 : 1;
        }

        const points = [
            // bottom-middle
            new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth * 1/2, yBottom), new CornerRounding.CornerRounding(0)),
            new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth * 0.1, yBottom), new CornerRounding.CornerRounding(0)),

            // bottom-left /||
            new MaterialShapes.PointNRound(new Offset.Offset(xLeft + rounding, yBottom), new CornerRounding.CornerRounding(0)),
            new MaterialShapes.PointNRound(new Offset.Offset(xLeft, yBottom), new CornerRounding.CornerRounding(bottomRounding)),
            new MaterialShapes.PointNRound(new Offset.Offset(xLeft, yBottom + rounding * bottomCornerDirection), new CornerRounding.CornerRounding(edgeRounding)),
            // top-left |/-
            new MaterialShapes.PointNRound(new Offset.Offset(xLeft, yTop + rounding * topCornerDirection), new CornerRounding.CornerRounding(0)),
            new MaterialShapes.PointNRound(new Offset.Offset(xLeft, yTop), new CornerRounding.CornerRounding(topRounding)),
            new MaterialShapes.PointNRound(new Offset.Offset(xLeft + rounding, yTop), new CornerRounding.CornerRounding(0)),
            
            // top-middle
            new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth * 0.1, yTop), new CornerRounding.CornerRounding(0)),
            new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth * 1/2, yTop), new CornerRounding.CornerRounding(0)),
            new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth * 0.9, yTop), new CornerRounding.CornerRounding(0)),

            // top-right -\|
            new MaterialShapes.PointNRound(new Offset.Offset(xRight - rounding, yTop), new CornerRounding.CornerRounding(0)),
            new MaterialShapes.PointNRound(new Offset.Offset(xRight, yTop), new CornerRounding.CornerRounding(topRounding)),
            new MaterialShapes.PointNRound(new Offset.Offset(xRight, yTop + rounding * topCornerDirection), new CornerRounding.CornerRounding(0)),

            // bottom-right ||\
            new MaterialShapes.PointNRound(new Offset.Offset(xRight, yBottom + rounding * bottomCornerDirection), new CornerRounding.CornerRounding(edgeRounding)),
            new MaterialShapes.PointNRound(new Offset.Offset(xRight, yBottom), new CornerRounding.CornerRounding(bottomRounding)),
            new MaterialShapes.PointNRound(new Offset.Offset(xRight - rounding, yBottom), new CornerRounding.CornerRounding(0)),

            // bottom-middle
            new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth * 0.9, yBottom), new CornerRounding.CornerRounding(0)),
        ]
        return MaterialShapes.customPolygon(points, 1, new Offset.Offset(root.screenWidth / 2, edgeGap + barHeight / 2))
    }

    // Content
    implicitHeight: barHeight + getEdgeGap(Config.options.bar.cornerStyle) * 2
    anchors {
        top: parent.top
        bottom: undefined
        left: parent.left
        right: parent.right
    }
    states: State {
        name: "bottom"
        when: Config.options.bar.bottom
        AnchorChanges {
            target: root
            anchors.top: undefined
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
        }
    }
    transitions: Transition {
        AnchorAnimation {
            duration: 500
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
        }
    }

    FadeLazyLoader {
        id: contentLoader
        load: root.load
        shown: root.shown
        anchors.fill: parent
        component: HBarContent {
            parent: contentLoader
            anchors.fill: parent
        }
    }
}
