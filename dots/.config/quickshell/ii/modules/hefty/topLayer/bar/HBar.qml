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

    // Config
    property bool vertical: Config.options.bar.vertical
    property bool atBottom: Config.options.bar.bottom
    property int cornerStyle: Config.options.bar.cornerStyle

    // Own props
    property int barHeight: Appearance.sizes.baseBarHeight
    property int barVerticalWidth: Appearance.sizes.baseVerticalBarWidth
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
    property int reservedArea: (vertical ? barVerticalWidth : barHeight) + getEdgeGap(cornerStyle)

    // Some info
    reservedTop: (!atBottom && !vertical) ? reservedArea : 0
    reservedBottom: (atBottom && !vertical) ? reservedArea : 0
    reservedLeft: (!atBottom && vertical) ? reservedArea : 0
    reservedRight: (atBottom && vertical) ? reservedArea : 0

    // Background
    function getBackgroundPolygon() {
        print("Generating background polygon for HBar")
        // It's certainly cleaner to have the below props declared outside, but we do this
        // to make sure a config change only makes this re-evaluate exactly once
        const bottom = root.atBottom
        const vertical = root.vertical
        const cornerStyle = root.cornerStyle
        const hug = root.getHug(cornerStyle)
        const edgeGap = root.getEdgeGap(cornerStyle)
        const edgeRounding = root.getEdgeRounding(cornerStyle)
        const rounding = root.getRounding(cornerStyle)

        const areaHeight = vertical ? root.screenHeight : (root.barHeight + edgeGap * 2)
        const areaWidth = vertical ? (root.barVerticalWidth + edgeGap * 2) : root.screenWidth
        const height = vertical ? (root.screenHeight - edgeGap * 2) : root.barHeight
        const width = vertical ? root.barVerticalWidth : (root.screenWidth - edgeGap * 2)
        
        const xLeft = (vertical && bottom) ? (root.screenWidth - edgeGap - width) : edgeGap
        const xRight = (vertical && !bottom) ? (areaWidth - edgeGap) : (root.screenWidth - edgeGap)
        const yTop = (!vertical && bottom) ? (root.screenHeight - edgeGap - height) : edgeGap
        const yBottom = (!vertical && !bottom) ? (areaHeight - edgeGap) : (root.screenHeight - edgeGap)

        const topLeftRounding = !bottom ? edgeRounding : rounding
        const topRightRounding = !(bottom^vertical) ? edgeRounding : rounding
        const bottomLeftRounding = !!(bottom^vertical) ? edgeRounding : rounding
        const bottomRightRounding = bottom ? edgeRounding : rounding

        var topCornerYDirection = 0, bottomCornerYDirection = 0, leftCornerXDirection = 0, rightCornerXDirection = 0;
        if (vertical) {
            topCornerYDirection = 1;
            bottomCornerYDirection = -1;
        } else if (cornerStyle === 2) { // Rect
            topCornerYDirection = 0;
            bottomCornerYDirection = 0;
        } else if (cornerStyle === 1) { // Rounded
            topCornerYDirection = 1;
            bottomCornerYDirection = -1;
        } else { // Hug
            topCornerYDirection = bottom ? -1 : 1;
            bottomCornerYDirection = bottom ? -1 : 1;
        }
        if (!vertical) {
            leftCornerXDirection = 1;
            rightCornerXDirection = -1
        } else if (cornerStyle === 2) { // Rect
            leftCornerXDirection = 0;
            rightCornerXDirection = 0;
        } else if (cornerStyle === 1) { // Rounded
            leftCornerXDirection = 1;
            rightCornerXDirection = -1;
        } else { // Hug
            leftCornerXDirection = bottom ? -1 : 1;
            rightCornerXDirection = bottom ? -1 : 1;
        }
        var points = [
            // bottom-middle
            new MaterialShapes.PointNRound(new Offset.Offset(xLeft + width * 1/2, yBottom), new CornerRounding.CornerRounding(0)),
            new MaterialShapes.PointNRound(new Offset.Offset(xLeft + width * 0.1, yBottom), new CornerRounding.CornerRounding(0)),

            // bottom-left
            new MaterialShapes.PointNRound(new Offset.Offset(xLeft + rounding * leftCornerXDirection, yBottom), new CornerRounding.CornerRounding(0)),
            new MaterialShapes.PointNRound(new Offset.Offset(xLeft, yBottom), new CornerRounding.CornerRounding(bottomLeftRounding)),
            new MaterialShapes.PointNRound(new Offset.Offset(xLeft, yBottom + rounding * bottomCornerYDirection), new CornerRounding.CornerRounding(edgeRounding)),

            // middle-left
            new MaterialShapes.PointNRound(new Offset.Offset(xLeft, yTop + height * 0.9), new CornerRounding.CornerRounding(0)),
            new MaterialShapes.PointNRound(new Offset.Offset(xLeft, yTop + height * 1/2), new CornerRounding.CornerRounding(0)),
            new MaterialShapes.PointNRound(new Offset.Offset(xLeft, yTop + height * 0.1), new CornerRounding.CornerRounding(0)),

            // top-left
            new MaterialShapes.PointNRound(new Offset.Offset(xLeft, yTop + rounding * topCornerYDirection), new CornerRounding.CornerRounding(0)),
            new MaterialShapes.PointNRound(new Offset.Offset(xLeft, yTop), new CornerRounding.CornerRounding(topLeftRounding)),
            new MaterialShapes.PointNRound(new Offset.Offset(xLeft + rounding * leftCornerXDirection, yTop), new CornerRounding.CornerRounding(0)),
            
            // top-middle
            new MaterialShapes.PointNRound(new Offset.Offset(xLeft + width * 0.1, yTop), new CornerRounding.CornerRounding(0)),
            new MaterialShapes.PointNRound(new Offset.Offset(xLeft + width * 1/2, yTop), new CornerRounding.CornerRounding(0)),
            new MaterialShapes.PointNRound(new Offset.Offset(xLeft + width * 0.9, yTop), new CornerRounding.CornerRounding(0)),

            // top-right
            new MaterialShapes.PointNRound(new Offset.Offset(xRight + rounding * rightCornerXDirection, yTop), new CornerRounding.CornerRounding(0)),
            new MaterialShapes.PointNRound(new Offset.Offset(xRight, yTop), new CornerRounding.CornerRounding(topRightRounding)),
            new MaterialShapes.PointNRound(new Offset.Offset(xRight, yTop + rounding * topCornerYDirection), new CornerRounding.CornerRounding(0)),

            // middle-right
            new MaterialShapes.PointNRound(new Offset.Offset(xRight, yTop + height * 0.1), new CornerRounding.CornerRounding(0)),
            new MaterialShapes.PointNRound(new Offset.Offset(xRight, yTop + height * 1/2), new CornerRounding.CornerRounding(0)),
            new MaterialShapes.PointNRound(new Offset.Offset(xRight, yTop + height * 0.9), new CornerRounding.CornerRounding(0)),

            // bottom-right
            new MaterialShapes.PointNRound(new Offset.Offset(xRight, yBottom + rounding * bottomCornerYDirection), new CornerRounding.CornerRounding(edgeRounding)),
            new MaterialShapes.PointNRound(new Offset.Offset(xRight, yBottom), new CornerRounding.CornerRounding(bottomRightRounding)),
            new MaterialShapes.PointNRound(new Offset.Offset(xRight + rounding * rightCornerXDirection, yBottom), new CornerRounding.CornerRounding(0)),

            // bottom-middle
            new MaterialShapes.PointNRound(new Offset.Offset(xLeft + width * 0.9, yBottom), new CornerRounding.CornerRounding(0)),
        ]
        return MaterialShapes.customPolygon(points, 1, new Offset.Offset(root.screenWidth / 2, edgeGap + barHeight / 2))
    }
    backgroundPolygon: getBackgroundPolygon()
    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready)
                root.backgroundPolygon = root.getBackgroundPolygon()
        }
        function onReloaded() {
            root.extraLoadCondition = false
            root.backgroundPolygon = root.getBackgroundPolygon()
            root.extraLoadCondition = true
        }
    }

    // Content
    implicitHeight: vertical ? screenHeight : (barHeight + getEdgeGap(cornerStyle) * 2)
    implicitWidth: vertical ? (barVerticalWidth + getEdgeGap(cornerStyle) * 2) : screenWidth
    width: implicitWidth
    height: implicitHeight
    anchors {
        top: parent.top
        bottom: undefined
        left: undefined
        right: undefined
    }
    states: [
        State {
            name: "bottom"
            when: root.atBottom && !root.vertical
            AnchorChanges {
                target: root
                anchors.top: undefined
                anchors.bottom: parent.bottom
                anchors.left: undefined
                anchors.right: undefined
            }
        },
        State {
            name: "left"
            when: !root.atBottom && root.vertical
            AnchorChanges {
                target: root
                anchors.top: undefined
                anchors.bottom: undefined
                anchors.left: parent.left
                anchors.right: undefined
            }
        },
        State {
            name: "right"
            when: root.atBottom && root.vertical
            AnchorChanges {
                target: root
                anchors.top: undefined
                anchors.bottom: undefined
                anchors.left: undefined
                anchors.right: parent.right
            }
        }
    ]
    transitions: Transition {
        AnchorAnimation {
            duration: 500
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
        }
    }

    property bool extraLoadCondition: true
    FadeLazyLoader {
        id: contentLoader
        load: root.load && root.extraLoadCondition
        shown: root.shown && root.extraLoadCondition
        anchors.fill: parent
        component: HBarContent {
            parent: contentLoader
            anchors.fill: parent
        }
    }
}
