import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

Button {
    id: button

    property bool toggled
    property string buttonIcon
    property string buttonText

    Layout.alignment: Qt.AlignHCenter
    implicitHeight: columnLayout.implicitHeight
    implicitWidth: columnLayout.implicitWidth

    background: Item{} // No ugly bg

    // Real stuff
    ColumnLayout {
        id: columnLayout
        spacing: 5
        Rectangle {
            width: 62
            implicitHeight: navRailButtonIcon.height + 2*2
            Layout.alignment: Qt.AlignHCenter
            radius: Appearance.rounding.full
            color: toggled ? 
                (button.down ? Appearance.colors.colSecondaryContainerActive : button.hovered ? Appearance.colors.colSecondaryContainerHover : Appearance.m3colors.m3secondaryContainer) :
                (button.down ? Appearance.colors.colLayer1Active : button.hovered ? Appearance.colors.colLayer1Hover : Appearance.transparentize(Appearance.colors.colLayer1Hover, 1))

            Behavior on color {
                ColorAnimation {
                    duration: Appearance.animation.elementDecel.duration
                    easing.type: Appearance.animation.elementDecel.type
                }
            }
            MaterialSymbol {
                id: navRailButtonIcon
                anchors.centerIn: parent
                font.pixelSize: Appearance.font.pixelSize.hugeass
                text: buttonIcon
                color: toggled ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer1

                Behavior on color {
                    ColorAnimation {
                        duration: Appearance.animation.elementDecel.duration
                        easing.type: Appearance.animation.elementDecel.type
                    }
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: buttonText
            color: Appearance.colors.colOnLayer1
        }
    }

}
