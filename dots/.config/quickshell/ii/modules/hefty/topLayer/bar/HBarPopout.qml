pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common as C   
import qs.modules.common.widgets as W

W.StyledRectangle {
    id: root
    contentLayer: W.StyledRectangle.ContentLayer.Pane

    color: C.Appearance.colors.colLayer2Base

    transitions: Transition {
        AnchorAnimation {
            duration: C.Appearance.animation.elementMove.duration
            easing.type: C.Appearance.animation.elementMove.type
            easing.bezierCurve: C.Appearance.animation.elementMove.bezierCurve
        }
        ColorAnimation {
            duration: C.Appearance.animation.elementMoveFast.duration
            easing.type: C.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: C.Appearance.animation.elementMoveFast.bezierCurve
        }
        PropertyAnimation {
            properties: "topLeftRadius,topRightRadius,bottomLeftRadius,bottomRightRadius,intendedWidth,intendedHeight"
            duration: C.Appearance.animation.elementMove.duration
            easing.type: C.Appearance.animation.elementMove.type
            easing.bezierCurve: C.Appearance.animation.elementMove.bezierCurve
        }
        PropertyAnimation {
            properties: "opacity"
            duration: C.Appearance.animation.elementMoveFast.duration
            easing.type: C.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: C.Appearance.animation.elementMoveFast.bezierCurve
        }
    }

    W.StyledRectangularShadow {
        target: root
        z: -1
        radius: root.topLeftRadius
    }
}
