import "../common"
import "../common/widgets"
import QtQuick
import QtQuick.Controls

Button {
    id: button

    property bool toggled

    signal clicked()

    implicitWidth: 40
    implicitHeight: 40
    onClicked: {
    }

    background: Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.full
        color: toggled ? 
            (button.down ? Appearance.colors.colPrimaryActive : button.hovered ? Appearance.colors.colPrimaryHover : Appearance.m3colors.m3primary) :
            (button.down ? Appearance.colors.colLayer1Active : button.hovered ? Appearance.colors.colLayer1Hover : Appearance.transparentize(Appearance.colors.colLayer1Hover, 1))

        MaterialSymbol {
            anchors.centerIn: parent
            text: "coffee"
            color: toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
        }

    }

}
