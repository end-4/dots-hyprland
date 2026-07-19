pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

Rectangle {
    id: root

    property bool loading: true
    property double pullProgress: 0

    // Size, color
    property double implicitSize: 48
    implicitWidth: implicitSize
    implicitHeight: implicitSize
    radius: Math.min(width, height) / 2
    color: Appearance.colors.colPrimaryContainer
    property double baseShapeSize: root.implicitSize * 0.7
    property double leapZoomSize: root.baseShapeSize * 1.2
    property double leapZoomProgress: 0

    // Shape
    property list<var> shapes: [
        MaterialShape.Shape.SoftBurst,
        MaterialShape.Shape.Cookie9Sided,
        MaterialShape.Shape.Pentagon,
        MaterialShape.Shape.Pill,
        MaterialShape.Shape.Sunny,
        MaterialShape.Shape.Cookie4Sided,
        MaterialShape.Shape.Oval,
    ]
    property int shapeIndex: 0
    property double pullRotation: root.loading ? 0 : -(root.pullProgress * 360)
    property double continuousRotation: 0
    property double leapRotation: 0
    rotation: pullRotation + continuousRotation + leapRotation

    RotationAnimation on continuousRotation {
        running: root.loading
        duration: 12000
        easing.type: Easing.Linear
        loops: Animation.Infinite
        from: 0
        to: 360
    }
    Timer {
        interval: 800
        running: root.loading
        repeat: true
        onTriggered: leapAnimation.start()
    }
    ParallelAnimation {
        id: leapAnimation
        PropertyAction { target: root; property: "shapeIndex"; value: (root.shapeIndex + 1) % root.shapes.length }
        RotationAnimation {
            target: root
            direction: RotationAnimation.Shortest
            property: "leapRotation"
            to: (root.leapRotation + 90) % 360
            duration: 350
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: root
            property: "leapZoomProgress"
            from: 0
            to: 1
            duration: 750
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standard
        }
    }

    MaterialShape {
        id: shape
        anchors.centerIn: parent
        shape: root.shapes[root.shapeIndex]
        implicitSize: {
            const leapZoomDiff = root.leapZoomSize - root.baseShapeSize
            const progressFirstHalf = Math.min(root.leapZoomProgress, 0.5) * 2;
            const progressSecondHalf = Math.max(root.leapZoomProgress - 0.5, 0) * 2;
            return root.baseShapeSize + leapZoomDiff * progressFirstHalf - leapZoomDiff * progressSecondHalf;
        }
        color: Appearance.colors.colOnPrimaryContainer

        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
}
