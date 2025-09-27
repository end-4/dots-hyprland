import QtQuick
import QtQuick.Shapes
import Quickshell

Item {
    id: root
    
    property int sides: 12
    property int implicitSize: 100
    property real amplitude: implicitSize / 50
    property int renderPoints: 360
    property color color: "#605790"
    property alias strokeWidth: shapePath.strokeWidth

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    Shape {
        id: shape
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: shapePath
            strokeWidth: 0
            fillColor: root.color
            pathHints: ShapePath.PathSolid & ShapePath.PathNonIntersecting

            PathPolyline {
                property var pointsList: {
                    var points = []
                    var cx = shape.width / 2   // center x
                    var cy = shape.height / 2  // center y
                    var steps = root.renderPoints
                    var radius = root.implicitSize / 2 - root.amplitude
                    for (var i = 0; i <= steps; i++) {
                        var angle = (i / steps) * 2 * Math.PI
                        var wave = Math.sin(angle * root.sides + Math.PI/2) * root.amplitude
                        var x = Math.cos(angle) * (radius + wave) + cx
                        var y = Math.sin(angle) * (radius + wave) + cy
                        points.push(Qt.point(x, y))
                    }
                    return points
                }

                path: pointsList
            }
        }
    }
}
