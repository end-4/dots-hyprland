import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import Quickshell.Io

Button {
    id: button

    property bool toggled
    property string buttonIcon

    implicitWidth: 40
    implicitHeight: 40

    background: Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.full
        color: toggled ? 
            (button.down ? Appearance.colors.colPrimaryActive : button.hovered ? Appearance.colors.colPrimaryHover : Appearance.m3colors.m3primary) :
            (button.down ? Appearance.colors.colLayer1Active : button.hovered ? Appearance.colors.colLayer1Hover : Appearance.transparentize(Appearance.colors.colLayer1Hover, 1))

        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementDecel.duration
                easing.type: Appearance.animation.elementDecel.type
            }

        }
        
        MaterialSymbol {
            anchors.centerIn: parent
            font.pixelSize: Appearance.font.pixelSize.larger
            text: buttonIcon
            color: toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1

            Behavior on color {
                ColorAnimation {
                    duration: Appearance.animation.elementDecel.duration
                    easing.type: Appearance.animation.elementDecel.type
                }
            }
        }

    }

}
