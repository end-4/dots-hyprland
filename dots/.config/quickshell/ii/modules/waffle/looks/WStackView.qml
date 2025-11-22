import QtQuick
import QtQuick.Controls
import qs.modules.waffle.looks

StackView {
    id: root
    property real moveDistance: 30
    property int pushDuration: 220
    property list<real> bezierCurve: Looks.transition.easing.bezierCurve.easeIn
    clip: true

    property alias color: background.color
    background: Rectangle {
        id: background
        color: Looks.colors.bgPanelFooterBase
    }

    pushEnter: Transition {
        XAnimator {
            from: -root.moveDistance
            to: 0
            duration: root.pushDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.bezierCurve
        }
        NumberAnimation {
            properties: "opacity"
            from: 0
            to: 1
            duration: root.pushDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.bezierCurve
        }
    }
    pushExit: Transition {
        XAnimator {
            from: 0
            to: root.moveDistance
            duration: root.pushDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.bezierCurve
        }
        NumberAnimation {
            properties: "opacity"
            from: 1
            to: 0
            duration: root.pushDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.bezierCurve
        }
    }
    popEnter: Transition {
        XAnimator {
            from: root.moveDistance
            to: 0
            duration: root.pushDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.bezierCurve
        }
        NumberAnimation {
            properties: "opacity"
            from: 0
            to: 1
            duration: root.pushDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.bezierCurve
        }
    }
    popExit: Transition {
        XAnimator {
            from: 0
            to: -root.moveDistance
            duration: root.pushDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.bezierCurve
        }
        NumberAnimation {
            properties: "opacity"
            from: 1
            to: 0
            duration: root.pushDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.bezierCurve
        }
    }
}
