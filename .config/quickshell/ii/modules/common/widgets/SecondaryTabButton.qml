import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Widgets

TabButton {
    id: root
    property string buttonText
    property string buttonIcon
    property bool selected: false
    property int rippleDuration: 1200
    height: buttonBackground.height
    property int tabContentWidth: buttonBackground.width - buttonBackground.radius*2

    property color colBackground: ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
    property color colBackgroundHover: Appearance.colors.colLayer1Hover
    property color colRipple: Appearance.colors.colLayer1Active

    PointingHandInteraction {}

    component RippleAnim: NumberAnimation {
        duration: rippleDuration
        easing.type: Appearance.animation.elementMoveEnter.type
        easing.bezierCurve: Appearance.animationCurves.standardDecel
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: (event) => { 
            const {x,y} = event
            const stateY = buttonBackground.y;
            rippleAnim.x = x;
            rippleAnim.y = y - stateY;

            const dist = (ox,oy) => ox*ox + oy*oy
            const stateEndY = stateY + buttonBackground.height
            rippleAnim.radius = Math.sqrt(Math.max(dist(0, stateY), dist(0, stateEndY), dist(width, stateY), dist(width, stateEndY)))

            rippleFadeAnim.complete();
            rippleAnim.restart();
        }
        onReleased: (event) => {
            root.click() // Because the MouseArea already consumed the event
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
        radius: Appearance?.rounding.small ?? 7
        implicitHeight: 37
        color: (root.hovered ? root.colBackgroundHover : root.colBackground)
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: buttonBackground.width
                height: buttonBackground.height
                radius: buttonBackground.radius
            }
        }
        
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        Rectangle {
            id: ripple

            radius: Appearance.rounding.full
            color: root.colRipple
            opacity: 0

            transform: Translate {
                x: -ripple.width / 2
                y: -ripple.height / 2
            }
        }
    }

    contentItem: Item {
        anchors.centerIn: buttonBackground
        RowLayout {
            anchors.centerIn: parent
            spacing: 0
            
            Loader {
                id: iconLoader
                active: buttonIcon?.length > 0
                sourceComponent: buttonIcon?.length > 0 ? materialSymbolComponent : null
                Layout.rightMargin: 5
            }

            Component {
                id: materialSymbolComponent
                MaterialSymbol {
                    verticalAlignment: Text.AlignVCenter
                    text: buttonIcon
                    iconSize: Appearance.font.pixelSize.huge
                    fill: selected ? 1 : 0
                    color: selected ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                }
            }
            StyledText {
                id: buttonTextWidget
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: Appearance.font.pixelSize.small
                color: selected ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                text: buttonText
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
            }
        }
    }
}