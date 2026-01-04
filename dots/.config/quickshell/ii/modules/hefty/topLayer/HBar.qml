import QtQuick
import qs.modules.common
import "../../common/widgets/shapes/material-shapes.js" as MaterialShapes
import "../../common/widgets/shapes/shapes/corner-rounding.js" as CornerRounding
import "../../common/widgets/shapes/geometry/offset.js" as Offset

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

    // Some info
    reservedTop: barHeight + getEdgeGap(Config.options.bar.cornerStyle)

    // Background
    backgroundPolygon: {
        // It's certainly cleaner to have the below props declared outside, but we do this
        // to make sure config change only makes this re-evaluate exactly once
        const cornerStyle = Config.options.bar.cornerStyle
        const rounding = root.getRounding(cornerStyle)
        const edgeGap = root.getEdgeGap(cornerStyle)
        const edgeRounding = root.getEdgeRounding(cornerStyle)
        const hug = root.getHug(cornerStyle)
        const points = [

            // bottom-middle
            new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth / 2, root.barHeight + edgeGap), new CornerRounding.CornerRounding(0)),

            // bottom-left /||
            new MaterialShapes.PointNRound(new Offset.Offset(edgeGap + rounding, edgeGap + barHeight), new CornerRounding.CornerRounding(0)),
            new MaterialShapes.PointNRound(new Offset.Offset(edgeGap, edgeGap + barHeight), new CornerRounding.CornerRounding(rounding)),
            new MaterialShapes.PointNRound(new Offset.Offset(edgeGap, edgeGap + barHeight + rounding * (hug ? 1 : -1)), new CornerRounding.CornerRounding(edgeRounding)),
            // top-left |/-
            new MaterialShapes.PointNRound(new Offset.Offset(edgeGap, edgeGap + rounding), new CornerRounding.CornerRounding(0)),
            new MaterialShapes.PointNRound(new Offset.Offset(edgeGap, edgeGap), new CornerRounding.CornerRounding(edgeRounding)),
            new MaterialShapes.PointNRound(new Offset.Offset(edgeGap + rounding, edgeGap), new CornerRounding.CornerRounding(0)),
            
            // top-middle
            new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth / 2, edgeGap), new CornerRounding.CornerRounding(0)),

            // top-right -\|
            new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth - edgeGap - rounding, edgeGap), new CornerRounding.CornerRounding(0)),
            new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth - edgeGap, edgeGap), new CornerRounding.CornerRounding(edgeRounding)),
            new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth - edgeGap, edgeGap + rounding), new CornerRounding.CornerRounding(0)),

            // bottom-right ||\
            new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth - edgeGap, root.barHeight + edgeGap + rounding * (hug ? 1 : -1)), new CornerRounding.CornerRounding(edgeRounding)),
            new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth - edgeGap, root.barHeight + edgeGap), new CornerRounding.CornerRounding(rounding)),
            new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth - edgeGap - rounding, root.barHeight + edgeGap), new CornerRounding.CornerRounding(0)),
        ]
        return MaterialShapes.customPolygon(points, 1, new Offset.Offset(root.screenWidth / 2, edgeGap + barHeight / 2))
    }

    // Content
    implicitHeight: barHeight + getEdgeGap(Config.options.bar.cornerStyle) * 2
    anchors {
        top: parent.top
        left: parent.left
        right: parent.right
    }
}
