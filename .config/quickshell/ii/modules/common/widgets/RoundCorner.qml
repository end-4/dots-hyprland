import QtQuick
import QtQuick.Shapes

Item {
    id: root

    enum CornerEnum { TopLeft, TopRight, BottomLeft, BottomRight }
    property var corner: RoundCorner.CornerEnum.TopLeft // Default to TopLeft

    property int implicitSize: 25
    property color color: "#000000"

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: shapePath
            strokeWidth: 0
            fillColor: root.color
            pathHints: ShapePath.PathSolid & ShapePath.PathNonIntersecting

            startX: switch (root.corner) {
                case RoundCorner.CornerEnum.TopLeft: return 0;
                case RoundCorner.CornerEnum.TopRight: return root.implicitSize;
                case RoundCorner.CornerEnum.BottomLeft: return 0;
                case RoundCorner.CornerEnum.BottomRight: return root.implicitSize;
            }
            startY: switch (root.corner) {
                case RoundCorner.CornerEnum.TopLeft: return 0;
                case RoundCorner.CornerEnum.TopRight: return 0;
                case RoundCorner.CornerEnum.BottomLeft: return root.implicitSize;
                case RoundCorner.CornerEnum.BottomRight: return root.implicitSize;
            }
            PathAngleArc {
                moveToStart: false
                centerX: root.implicitSize - shapePath.startX
                centerY: root.implicitSize - shapePath.startY
                radiusX: root.implicitSize
                radiusY: root.implicitSize
                startAngle: switch (root.corner) {
                    case RoundCorner.CornerEnum.TopLeft: return 180;
                    case RoundCorner.CornerEnum.TopRight: return -90;
                    case RoundCorner.CornerEnum.BottomLeft: return 90;
                    case RoundCorner.CornerEnum.BottomRight: return 0;
                }
                sweepAngle: 90
            }
            PathLine {
                x: shapePath.startX
                y: shapePath.startY
            }
        }
    }

    Behavior on implicitSize {
        animation: Appearance?.animation.elementMoveFast.numberAnimation.createObject(this)
    }

}
