import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: button
    property string buttonText: ""
    property string buttonIcon: ""

    // implicitHeight: 30
    implicitWidth: contentRowLayout.implicitWidth + 10 * 2
    Behavior on implicitWidth {
        SmoothedAnimation {
            velocity: Appearance.animation.elementMove.velocity
        }
    }

    PointingHandInteraction {}

    background: Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.full
        color: (button.down) ? Appearance.colors.colLayer2Active : (button.hovered ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2)

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

    }
    contentItem: RowLayout {
        id: contentRowLayout
        anchors.centerIn: parent
        spacing: 0
        MaterialSymbol {
            text: buttonIcon
            Layout.fillWidth: false
            iconSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colOnLayer1
        }
        StyledText {
            text: buttonText
            Layout.fillWidth: false
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
        }
    }

}