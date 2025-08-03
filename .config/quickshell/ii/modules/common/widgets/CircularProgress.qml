// From https://github.com/rafzby/circular-progressbar with modifications
// License: LGPL-3.0 - A copy can be found in `licenses` folder of repo

import QtQuick
import QtQuick.Shapes
import qs.modules.common

/**
 * Material 3 circular progress. See https://m3.material.io/components/progress-indicators/specs
 */
Item {
    id: root

    property int size: 30
    property int lineWidth: 2
    property real value: 0
    property color primaryColor: Appearance.m3colors.m3onSecondaryContainer
    property color secondaryColor: Appearance.colors.colSecondaryContainer
    property real gapAngle: 180 / 9
    property bool fill: false
    property int fillOverflow: 2
    property bool enableAnimation: true
    property int animationDuration: 1000
    property var easingType: Easing.OutCubic

    width: size
    height: size

    property real degree: value * 360
    property real centerX: root.width / 2
    property real centerY: root.height / 2
    property real arcRadius: root.size / 2 - root.lineWidth
    property real startAngle: -90

    Behavior on degree {
        enabled: root.enableAnimation
        NumberAnimation {
            duration: root.animationDuration
            easing.type: root.easingType
        }

    }

    Loader {
        active: root.fill
        anchors.fill: parent
        
        sourceComponent: Rectangle {
            radius: 9999
            color: root.secondaryColor
        }
    }

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            id: secondaryPath
            strokeColor: root.secondaryColor
            strokeWidth: root.lineWidth
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            PathAngleArc {
                centerX: root.centerX
                centerY: root.centerY
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                startAngle: root.startAngle - root.gapAngle
                sweepAngle: -(360 - root.degree - 2 * root.gapAngle)
            }
        }
        ShapePath {
            id: primaryPath
            strokeColor: root.primaryColor
            strokeWidth: root.lineWidth
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            PathAngleArc {
                centerX: root.centerX
                centerY: root.centerY
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                startAngle: root.startAngle
                sweepAngle: root.degree
            }
        }
    }

}
