import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: button
    property string day
    property int isToday
    property bool bold
    property bool interactable: true

    Layout.fillWidth: false
    Layout.fillHeight: false
    implicitWidth: 38; 
    implicitHeight: 38;

    background: Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.full
        color: (isToday == 1) ? ((interactable && button.down) ? Appearance.colors.colPrimaryActive : 
            (interactable && button.hovered) ? Appearance.colors.colPrimaryHover : 
            Appearance.m3colors.m3primary) : 
            (interactable && button.down) ? Appearance.colors.colLayer1Active : 
            (interactable && button.hovered) ? Appearance.colors.colLayer1Hover : 
            Appearance.transparentize(Appearance.colors.colLayer1, 1)

        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementDecel.duration
                easing.type: Appearance.animation.elementDecel.type
            }

        }
    }
    
    contentItem: StyledText {
        anchors.fill: parent
        text: day
        horizontalAlignment: Text.AlignHCenter
        font.weight: bold ? Font.Bold : isToday == -1 ? Font.Normal : Font.DemiBold
        color: (isToday == 1) ? Appearance.m3colors.m3onPrimary : 
            (isToday == 0) ? Appearance.colors.colOnLayer1 : 
            Appearance.m3colors.m3outline

        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementDecel.duration
                easing.type: Appearance.animation.elementDecel.type
            }

        }
    }
}

