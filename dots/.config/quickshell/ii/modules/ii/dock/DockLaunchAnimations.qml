import qs.modules.common
import QtQuick

Item {
    id: root

    property real scale: 1.0
    property real rot: 0.0

    function play(type) {
        if (type === DockLaunchAnims.AnimType.None) return;
        if (type === DockLaunchAnims.AnimType.Bounce) animBounce.restart();
        else if (type === DockLaunchAnims.AnimType.Pulse) animPulse.restart();
        else if (type === DockLaunchAnims.AnimType.Pop) animPop.restart();
        else if (type === DockLaunchAnims.AnimType.Wobble) animWobble.restart();
    }

    SequentialAnimation {
        id: animPop
        PropertyAction { target: root; property: "scale"; value: 0.0 }
        
        NumberAnimation {
            target: root
            property: "scale"
            from: 0.0
            to: 1.0
            duration: 350
            easing.type: Easing.OutBack 
        }
    }

    SequentialAnimation {
        id: animBounce
        
        NumberAnimation {
            target: root
            property: "scale"
            from: 1.0; to: 0.82
            duration: 100
            easing.type: Easing.InQuad
        }
        
        NumberAnimation {
            target: root
            property: "scale"
            from: 0.82; to: 1.0
            duration: 400
            easing.type: Easing.OutBounce 
        }
    }

    SequentialAnimation {
        id: animPulse
        NumberAnimation {
            target: root
            property: "scale"
            from: 1.0; to: 1.2
            duration: 120
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
        }
        NumberAnimation {
            target: root
            property: "scale"
            from: 1.2; to: 1.0
            duration: 350 // Regreso lento para suavidad
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveEffects
        }
    }

    SequentialAnimation {
        id: animWobble
        NumberAnimation {
            target: root
            property: "rot"
            from: 0; to: -10
            duration: 60
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
        }
        NumberAnimation {
            target: root
            property: "rot"
            from: -10; to: 10
            duration: 80
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveEffects
        }
        NumberAnimation {
            target: root
            property: "rot"
            from: 10; to: -5
            duration: 70
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveEffects
        }
        NumberAnimation {
            target: root
            property: "rot"
            from: -5; to: 5
            duration: 60
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveEffects
        }
        NumberAnimation {
            target: root
            property: "rot"
            from: 5; to: 0
            duration: 80
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
        }
    }
}
