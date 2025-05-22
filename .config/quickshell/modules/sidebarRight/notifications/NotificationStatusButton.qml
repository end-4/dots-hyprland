import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RippleButton {
    id: button
    property string buttonText: ""
    property string buttonIcon: ""

    implicitHeight: 30
    implicitWidth: contentRowLayout.implicitWidth + 10 * 2
    Behavior on implicitWidth {
        SmoothedAnimation {
            velocity: Appearance.animation.elementMove.velocity
        }
    }

    buttonRadius: Appearance.rounding.full
    colBackground: Appearance.colors.colLayer2
    colBackgroundHover: Appearance.colors.colLayer2Hover
    colRipple: Appearance.colors.colLayer2Active
    background.anchors.fill: button

    contentItem: Item {
        RowLayout {
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

}