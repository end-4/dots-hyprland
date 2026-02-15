import QtQuick
import qs.modules.common.models as M
import "shapes/material-shapes.js" as MaterialShapes
import "shapes/shapes/corner-rounding.js" as CornerRounding
import "shapes/geometry/offset.js" as Offset

// For returning the points 
M.NestableObject {
    id: root

    required property real width
    required property real height
    property real radius: 0
    property real topLeftRadius: radius
    property real topRightRadius: radius
    property real bottomLeftRadius: radius
    property real bottomRightRadius: radius
    property real xOffset: 0
    property real yOffset: 0

    readonly property real radiusLimit: Math.min(width, height) / 2
    readonly property real effectiveTopLeftRadius: Math.min(topLeftRadius, radiusLimit)
    readonly property real effectiveTopRightRadius: Math.min(topRightRadius, radiusLimit)
    readonly property real effectiveBottomLeftRadius: Math.min(bottomLeftRadius, radiusLimit)
    readonly property real effectiveBottomRightRadius: Math.min(bottomRightRadius, radiusLimit)

    // Clockwise starting from bottom
    property list<var> bottomPoints: [
        new MaterialShapes.PointNRound(new Offset.Offset(xOffset + width - effectiveBottomRightRadius, yOffset + height), new CornerRounding.CornerRounding(0)),
        new MaterialShapes.PointNRound(new Offset.Offset(xOffset + width / 2, yOffset + height), new CornerRounding.CornerRounding(0)),
        new MaterialShapes.PointNRound(new Offset.Offset(xOffset + effectiveBottomLeftRadius, yOffset + height), new CornerRounding.CornerRounding(0)),
    ]
    property list<var> leftPoints: [
        new MaterialShapes.PointNRound(new Offset.Offset(xOffset + 0, yOffset + height - effectiveBottomLeftRadius), new CornerRounding.CornerRounding(0)),
        new MaterialShapes.PointNRound(new Offset.Offset(xOffset + 0, yOffset + height / 2), new CornerRounding.CornerRounding(0)),
        new MaterialShapes.PointNRound(new Offset.Offset(xOffset + 0, yOffset + effectiveTopLeftRadius), new CornerRounding.CornerRounding(0)),
    ]
    property list<var> topPoints: [
        new MaterialShapes.PointNRound(new Offset.Offset(xOffset + effectiveTopLeftRadius, yOffset + 0), new CornerRounding.CornerRounding(0)),
        new MaterialShapes.PointNRound(new Offset.Offset(xOffset + width / 2, yOffset + 0), new CornerRounding.CornerRounding(0)),
        new MaterialShapes.PointNRound(new Offset.Offset(xOffset + width - effectiveTopRightRadius, yOffset + 0), new CornerRounding.CornerRounding(0)),
    ]
    property list<var> rightPoints: [
        new MaterialShapes.PointNRound(new Offset.Offset(xOffset + width, yOffset + effectiveTopRightRadius), new CornerRounding.CornerRounding(0)),
        new MaterialShapes.PointNRound(new Offset.Offset(xOffset + width, yOffset + height / 2), new CornerRounding.CornerRounding(0)),
        new MaterialShapes.PointNRound(new Offset.Offset(xOffset + width, yOffset + height - effectiveBottomRightRadius), new CornerRounding.CornerRounding(0)),
    ]

    function getFirstBottomPoints() {
        return bottomPoints.slice(Math.floor(bottomPoints.length / 2))
    }

    function getLastBottomPoints() {
        return bottomPoints.slice(0, Math.floor(bottomPoints.length / 2))
    }

    function getBottomLeftPoint(extraXOffset = 0, extraYOffset = 0, radius = undefined) {
        if (radius === undefined) radius = effectiveBottomLeftRadius;
        return new MaterialShapes.PointNRound(new Offset.Offset(xOffset + extraXOffset + 0, yOffset + extraYOffset + height), new CornerRounding.CornerRounding(radius))
    }

    function getTopLeftPoint(extraXOffset = 0, extraYOffset = 0, radius = undefined) {
        if (radius === undefined) radius = effectiveTopLeftRadius;
        return new MaterialShapes.PointNRound(new Offset.Offset(xOffset + extraXOffset + 0, yOffset + extraYOffset + 0), new CornerRounding.CornerRounding(radius))
    }

    function getTopRightPoint(extraXOffset = 0, extraYOffset = 0, radius = undefined) {
        if (radius === undefined) radius = effectiveTopRightRadius;
        return new MaterialShapes.PointNRound(new Offset.Offset(xOffset + extraXOffset + width, yOffset + extraYOffset + 0), new CornerRounding.CornerRounding(radius))
    }

    function getBottomRightPoint(extraXOffset = 0, extraYOffset = 0, radius = undefined) {
        if (radius === undefined) radius = effectiveBottomRightRadius;
        return new MaterialShapes.PointNRound(new Offset.Offset(xOffset + extraXOffset + width, yOffset + extraYOffset + height), new CornerRounding.CornerRounding(radius))
    }

    function getFullShape() {
        const points = [
            ...getFirstBottomPoints(),
            getBottomLeftPoint(),
            ...leftPoints,
            getTopLeftPoint(),
            ...topPoints,
            getTopRightPoint(),
            ...rightPoints,
            getBottomRightPoint(),
            ...getLastBottomPoints(),
        ]
        return MaterialShapes.customPolygon(points);
    }
}
