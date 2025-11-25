import QtQuick
import QtQuick.Controls
import qs.modules.waffle.looks

StackView {
    id: root
    property real moveDistance: 30
    property int pushDuration: 200
    property int fadeDuration: 80
    property list<real> bezierCurve: Looks.transition.easing.bezierCurve.easeIn
    property list<real> fadeBezierCurve: Looks.transition.easing.bezierCurve.easeInOut
    clip: true

    background: null

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
            duration: root.fadeDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.fadeBezierCurve
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
            duration: root.fadeDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.fadeBezierCurve
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
            duration: root.fadeDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.fadeBezierCurve
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
            duration: root.fadeDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.fadeBezierCurve
        }
    }
}
