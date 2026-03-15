pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import qs.modules.common

AbstractCombinedProgressBar {
    id: root

    property int implicitSize: 30
    property int lineWidth: 2
    property real gapAngle: 360 / 18

    valueHighlights: [Appearance.colors.colPrimary, Appearance.colors.colTertiary]
    valueTroughs: [Appearance.colors.colSecondaryContainer, Appearance.colors.colTertiaryContainer]

    property bool enableAnimation: true
    property int animationDuration: 800
    property var easingType: Easing.OutCubic

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    readonly property real centerX: root.width / 2
    readonly property real centerY: root.height / 2
    readonly property real arcRadius: root.implicitSize / 2 - root.lineWidth
    readonly property real startAngle: -90

    background: Item {
        implicitWidth: root.implicitSize
        implicitHeight: root.implicitSize
    }

    function isNegligibleSegment(seg: var): bool {
        const range = seg[1] - seg[0];
        return range < 1 / 360; // TODO make this less arbitrary
    }

    Repeater {
        model: root.visualSegments
        delegate: Shape {
            id: segShape
            required property int index
            required property var modelData

            property bool negligible: root.isNegligibleSegment(modelData)
            property bool atStart: index == 0
            property bool atEnd: index == root.visualSegments.length - 1
            property real displaySegStart: {
                var i = index;
                while ((i > 0 && root.isNegligibleSegment(root.visualSegments[i - 1])))
                    i--;
                return root.visualSegments[i][0];
            }

            anchors.fill: parent
            layer.enabled: true
            layer.smooth: true
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: segShape.negligible ? "transparent" : root.segmentColors[segShape.index % root.segmentColors.length]
                strokeWidth: segShape.negligible ? 0 : root.lineWidth
                capStyle: ShapePath.RoundCap
                fillColor: "transparent"
                PathAngleArc {
                    centerX: root.centerX
                    centerY: root.centerY
                    radiusX: root.arcRadius
                    radiusY: root.arcRadius
                    startAngle: root.startAngle + 360 * segShape.displaySegStart + root.gapAngle / 2
                    sweepAngle: 360 * (segShape.modelData[1] - segShape.displaySegStart) - root.gapAngle
                }
            }
        }
    }
}
