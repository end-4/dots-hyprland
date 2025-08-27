import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: button

    property string day
    property int isToday
    property bool bold
    property var taskList

    Layout.fillWidth: false
    Layout.fillHeight: false
    implicitWidth: 38
    implicitHeight: 38
    toggled: (isToday == 1)
    buttonRadius: Appearance.rounding.small

    Rectangle {
        width: 6
        height: 6
        radius: 3
        color: (taskList.length > 0 && isToday !== -1 && !bold) ? Appearance.m3colors.m3error : "transparent"
        anchors.top: parent.top
        anchors.left: parent.left
    }

    contentItem: StyledText {
        anchors.fill: parent
        text: day
        horizontalAlignment: Text.AlignHCenter
        font.weight: bold ? Font.DemiBold : Font.Normal
        color: (isToday == 1) ? Appearance.m3colors.m3onPrimary : (isToday == 0) ? Appearance.colors.colOnLayer1 : Appearance.colors.colOutlineVariant

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

    }

}
