import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.modules.common

Item {
    id: root
    
    property real sides: 12  
    property int implicitSize: 100
    property real amplitude: implicitSize / 50
    property int renderPoints: 360
    property color color: "#605790"
    property alias strokeWidth: shapePath.strokeWidth
    property bool constantlyRotate: false

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    property real shapeRotation: 0

    Loader {
        active: constantlyRotate
        sourceComponent: FrameAnimation {
            running: true
            onTriggered: {
                shapeRotation += 0.05
            }
        }
    }

    Behavior on sides {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

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
                        var rotatedAngle = angle * root.sides + Math.PI/2 + (root.shapeRotation * root.constantlyRotate)
                        var wave = Math.sin(rotatedAngle) * root.amplitude
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
