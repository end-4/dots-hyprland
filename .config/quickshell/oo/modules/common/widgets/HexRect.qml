import QtQuick
import QtQuick.Shapes

/**
 * Draws a hexagon when width == height. 
 * Otherwise the hexagon is extended
 */
Item {
    id: root
    property real radius: Math.min(width, height) / 2
    property real cornerRounding: radius * 0.5
    property color color: "#b7eb34"
    property real borderWidth: cornerRounding
    property color borderColor: color

    Shape {
        id: hexShape
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        
        ShapePath {
            id: hexPath
            fillColor: root.color
            strokeColor: root.borderColor
            strokeWidth: root.borderWidth
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            
            property real r: root.radius
            property real r60: r * Math.sqrt(3) / 2
            property real r30: r / 2
            property real cr: root.cornerRounding
            property real cr60: cr * Math.sqrt(3) / 2
            property real cr30: cr / 2
            property real lineWidthAdjustment: strokeWidth / 2
            property real lineWidthAdjustment60: lineWidthAdjustment * Math.sqrt(3) / 2
            property real lineWidthAdjustment30: lineWidthAdjustment / 2

            startX: hexPath.r; startY: lineWidthAdjustment;
            PathLine { x: hexPath.r + hexPath.r60 - hexPath.lineWidthAdjustment60; y: hexShape.height / 2 - hexPath.r30 + hexPath.lineWidthAdjustment30 }
            PathLine { x: hexPath.r + hexPath.r60 - hexPath.lineWidthAdjustment60; y: hexShape.height / 2 + hexPath.r30 - hexPath.lineWidthAdjustment30 }
            PathLine { x: hexPath.r; y: hexShape.height - hexPath.lineWidthAdjustment }
            PathLine { x: hexPath.r - hexPath.r60 + hexPath.lineWidthAdjustment60; y: hexShape.height - hexPath.r30 - hexPath.lineWidthAdjustment30 }
            PathLine { x: hexPath.r - hexPath.r60 + hexPath.lineWidthAdjustment60; y: hexPath.r30 + hexPath.lineWidthAdjustment30 }
            // Close the path
            PathLine { x: hexPath.r; y: hexPath.lineWidthAdjustment }
        }
    }
}
