import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Widgets

Button {
    id: root
    property bool toggled
    property string buttonText
    property real buttonRadius: Appearance?.rounding?.small ?? 4
    property real buttonRadiusPressed: buttonRadius
    property int rippleDuration: 1200

    property color colBackground: ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
    property color colBackgroundHover: Appearance.colors.colLayer1Hover
    property color colBackgroundToggled: Appearance.m3colors.m3primary
    property color colBackgroundToggledHover: Appearance.colors.colPrimaryHover
    property color colRipple: Appearance.colors.colLayer1Active
    property color colRippleToggled: Appearance.colors.colPrimaryActive

    property color buttonColor: root.enabled ? (root.toggled ? 
        (root.hovered ? colBackgroundToggledHover : 
            colBackgroundToggled) :
        (root.hovered ? colBackgroundHover : 
            colBackground)) : colBackground
    property color rippleColor: root.toggled ? colRippleToggled : colRipple

    function startRipple(x, y) {
        const stateY = buttonBackground.y;
        rippleAnim.x = x;
        rippleAnim.y = y - stateY;

        const dist = (ox,oy) => ox*ox + oy*oy
        const stateEndY = stateY + buttonBackground.height
        rippleAnim.radius = Math.sqrt(Math.max(dist(0, stateY), dist(0, stateEndY), dist(width, stateY), dist(width, stateEndY)))

        rippleFadeAnim.complete();
        rippleAnim.restart();
    }

    component RippleAnim: NumberAnimation {
        duration: rippleDuration
        easing.type: Appearance.animation.elementMoveEnter.type
        easing.bezierCurve: Appearance.animationCurves.standardDecel
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: (event) => { 
            root.down = true
            const {x,y} = event
            startRipple(x, y)
        }
        onReleased: (event) => {
            root.down = false
            root.click() // Because the MouseArea already consumed the event
            rippleFadeAnim.restart();
        }
        onCanceled: (event) => {
            root.down = false
            rippleFadeAnim.restart();
        }
    }

    RippleAnim {
        id: rippleFadeAnim
        target: ripple
        property: "opacity"
        to: 0
    }

    SequentialAnimation {
        id: rippleAnim

        property real x
        property real y
        property real radius

        PropertyAction {
            target: ripple
            property: "x"
            value: rippleAnim.x
        }
        PropertyAction {
            target: ripple
            property: "y"
            value: rippleAnim.y
        }
        PropertyAction {
            target: ripple
            property: "opacity"
            value: 1
        }
        ParallelAnimation {
            RippleAnim {
                target: ripple
                properties: "implicitWidth,implicitHeight"
                from: 0
                to: rippleAnim.radius * 2
            }
        }
    }

    background: Rectangle {
        id: buttonBackground
        radius: root.down ? root.buttonRadiusPressed : root.buttonRadius
        implicitHeight: 50

        color: root.buttonColor
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: buttonBackground.width
                height: buttonBackground.height
                radius: buttonBackground.radius
            }
        }

        Rectangle {
            id: ripple

            radius: Appearance.rounding.full
            opacity: 0
            color: root.rippleColor
            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }

            transform: Translate {
                x: -ripple.width / 2
                y: -ripple.height / 2
            }
        }
    }

    contentItem: StyledText {
        text: root.buttonText
    }
}