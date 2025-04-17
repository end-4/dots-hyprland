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

    PointingHandInteraction {}

    background: Rectangle {
        id: buttonBackground
        radius: Appearance.rounding.small
        implicitHeight: 37
        color: (button.down ? Appearance.colors.colLayer1Active : button.hovered ? Appearance.colors.colLayer1Hover : Appearance.transparentize(Appearance.colors.colLayer1Hover, 1))
        
        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementDecel.duration
                easing.type: Appearance.animation.elementDecel.type
            }
        }
    }
    contentItem: Item {
        anchors.centerIn: buttonBackground
        RowLayout {
            anchors.centerIn: parent
            spacing: 0
            MaterialSymbol {
                Layout.rightMargin: 5
                text: buttonIcon
                font.pixelSize: Appearance.font.pixelSize.larger
                color: selected ? Appearance.m3colors.m3primary : Appearance.colors.colOnLayer1
                Behavior on color {
                    ColorAnimation {
                        duration: Appearance.animation.elementDecel.duration
                        easing.type: Appearance.animation.elementDecel.type
                    }
                }
            }
            StyledText {
                id: buttonTextWidget
                horizontalAlignment: Text.AlignHCenter
                text: buttonText
                color: selected ? Appearance.m3colors.m3primary : Appearance.colors.colOnLayer1
                Behavior on color {
                    ColorAnimation {
                        duration: Appearance.animation.elementDecel.duration
                        easing.type: Appearance.animation.elementDecel.type
                    }
                }
            }
        }
    }
}