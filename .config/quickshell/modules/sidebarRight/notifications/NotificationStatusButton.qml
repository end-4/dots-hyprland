import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GroupButton {
    id: button
    property string buttonText: ""
    property string buttonIcon: ""

    baseWidth: contentRowLayout.implicitWidth + 10 * 2
    baseHeight: 30
    clickedWidth: baseWidth + 15

    buttonRadius: baseHeight / 2
    buttonRadiusPressed: Appearance.rounding.small
    colBackground: Appearance.colors.colLayer2
    colBackgroundHover: Appearance.colors.colLayer2Hover
    colBackgroundActive: Appearance.colors.colLayer2Active
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