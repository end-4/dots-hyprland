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
    height: buttonBackground.height
    property int tabContentWidth: buttonBackground.width - buttonBackground.radius*2

    PointingHandInteraction {}

    background: Rectangle {
        id: buttonBackground
        radius: Appearance.rounding.small
        implicitHeight: 37
        color: (button.down ? Appearance.colors.colLayer1Active : button.hovered ? Appearance.colors.colLayer1Hover : Appearance.transparentize(Appearance.colors.colLayer1Hover, 1))
        
        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
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
                    color: selected ? Appearance.m3colors.m3primary : Appearance.colors.colOnLayer1
                    Behavior on color {
                        ColorAnimation {
                            duration: Appearance.animation.elementMove.duration
                            easing.type: Appearance.animation.elementMove.type
                            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                        }
                    }
                }
            }
            StyledText {
                id: buttonTextWidget
                verticalAlignment: Text.AlignVCenter
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