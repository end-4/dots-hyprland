import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

GroupButton {
    id: button
    property string buttonText

    horizontalPadding: 8
    verticalPadding: 6

    baseWidth: contentItem.implicitWidth + horizontalPadding * 2
    clickedWidth: baseWidth + 20
    baseHeight: contentItem.implicitHeight + verticalPadding * 2
    buttonRadius: down ? Appearance.rounding.small : baseHeight / 2

    colBackground: Appearance.colors.colLayer2
    colBackgroundHover: Appearance.colors.colLayer2Hover
    colBackgroundActive: Appearance.colors.colLayer2Active

    contentItem: StyledText {
        horizontalAlignment: Text.AlignHCenter
        text: buttonText
        color: Appearance.m3colors.m3onSurface
    }
}