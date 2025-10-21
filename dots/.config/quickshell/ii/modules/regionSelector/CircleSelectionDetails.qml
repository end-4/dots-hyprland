import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Shapes
import Quickshell

Item {
    id: root
    required property color color
    required property color overlayColor
    required property list<point> points
    property int strokeWidth: Config.options.regionSelector.circle.strokeWidth

    function updatePoints() {
        if (!root.dragging) return;
        root.points.push({ x: root.mouseX, y: root.mouseY });
    }

    Rectangle {
        id: darkenOverlay
        z: 1
        anchors.fill: parent
        color: root.overlayColor
    }

    Shape {
        id: shape
        z: 2
        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: shapePath
            strokeWidth: root.strokeWidth
            pathHints: ShapePath.PathLinear
            fillColor: "transparent"
            strokeColor: root.color
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathPolyline {
                path: root.points
            }
        }
    }

}
