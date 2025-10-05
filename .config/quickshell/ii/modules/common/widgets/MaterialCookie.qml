import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.modules.common


Item {
    id: root
    
    property int sides: 12
    property real animatedSides: 12     
    property int implicitSize: 100
    property real amplitude: implicitSize / 50
    property int renderPoints: 360
    property color color: "#605790"
    property alias strokeWidth: shapePath.strokeWidth
    property bool waveAnimation: false


    implicitWidth: implicitSize
    implicitHeight: implicitSize

    property real waveTime: 0
    Loader{
        active: waveAnimation
        sourceComponent: Timer{
            interval: 16  // Does it effect performance, probably, is it noticeable, not really
            running: true; repeat: true
            onTriggered: {
                root.waveTime += 0.05
            }
        }
    }

    onSidesChanged: NumberAnimation {
        target: root
        property: "animatedSides"
        to: root.sides
        duration: 100
        easing.type: Easing.InOutQuad
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
                        var wave = waveAnimation ? Math.sin(angle * root.animatedSides + Math.PI/2 - root.waveTime) * root.amplitude : Math.sin(angle * root.animatedSides + Math.PI/2) * root.amplitude
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
