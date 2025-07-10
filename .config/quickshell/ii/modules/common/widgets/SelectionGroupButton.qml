import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "root:/services/"
import "root:/modules/common/"
import "root:/modules/common/widgets/"

GroupButton {
    id: root
    horizontalPadding: 12
    verticalPadding: 8
    bounce: false
    property bool leftmost: false
    property bool rightmost: false
    leftRadius: (toggled || leftmost) ? (height / 2) : Appearance.rounding.unsharpenmore
    rightRadius: (toggled || rightmost) ? (height / 2) : Appearance.rounding.unsharpenmore
    colBackground: Appearance.colors.colSecondaryContainer
    contentItem: StyledText {
        color: parent.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
        text: root.buttonText
    }
}
