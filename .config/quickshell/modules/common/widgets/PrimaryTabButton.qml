import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Widgets

TabButton {
    id: button
    property string buttonText
    property string buttonIcon
    property bool selected: false
    property int tabContentWidth: contentItem.children[0].implicitWidth
    property int rippleDuration: 1000
    height: buttonBackground.height

    PointingHandInteraction {}

    component RippleAnim: NumberAnimation {
        duration: rippleDuration
        easing.type: Appearance.animation.elementMoveEnter.type
        easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
    }

    MouseArea {
        anchors.fill: parent
        onPressed: (event) => {
    
            const {x,y} = event
            const stateY = buttonBackground.y;
            rippleAnim.x = x;
            rippleAnim.y = y - stateY;

            const dist = (ox,oy) => ox*ox + oy*oy
            const stateEndY = stateY + buttonBackground.height
            rippleAnim.radius = Math.sqrt(Math.max(dist(0, stateY), dist(0, stateEndY), dist(width, stateY), dist(width, stateEndY)))

            rippleAnim.restart();
            event.accepted = false
        }
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
            value: 0.1
        }
        ParallelAnimation {
            RippleAnim {
                target: ripple
                properties: "implicitWidth,implicitHeight"
                from: 0
                to: rippleAnim.radius * 2
            }
            RippleAnim {
                target: ripple
                property: "opacity"
                to: 0
            }
        }
    }

    background: ClippingRectangle {
        id: buttonBackground
        radius: Appearance.rounding.small
        implicitHeight: 50
        color: (button.down ? Appearance.colors.colLayer1Active : button.hovered ? Appearance.colors.colLayer1Hover : Appearance.transparentize(Appearance.colors.colLayer1Hover, 1))
        
        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
            }
        }

        Rectangle {
            id: ripple

            radius: Appearance.rounding.full
            color: button.current ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurface
            opacity: 0

            transform: Translate {
                x: -ripple.width / 2
                y: -ripple.height / 2
            }
        }
    }
    contentItem: Item {
        anchors.centerIn: buttonBackground
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0
            MaterialSymbol {
                visible: buttonIcon?.length > 0
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                text: buttonIcon
                iconSize: Appearance.font.pixelSize.hugeass
                fill: selected ? 1 : 0
                color: selected ? Appearance.m3colors.m3primary : Appearance.colors.colOnLayer1
                Behavior on color {
                    ColorAnimation {
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                }
            }
            StyledText {
                id: buttonTextWidget
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.small
                color: selected ? Appearance.m3colors.m3primary : Appearance.colors.colOnLayer1
                text: buttonText
                Behavior on color {
                    ColorAnimation {
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                }
            }
        }
    }
}