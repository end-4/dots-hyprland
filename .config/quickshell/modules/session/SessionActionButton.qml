import "root:/modules/common"
import "root:/modules/common/widgets/"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

RippleButton {
    id: button

    property string buttonIcon
    property string buttonText
    property bool keyboardDown: false

    buttonRadius: button.focus ? Appearance.rounding.full : Appearance.rounding.verylarge
    colBackground: button.keyboardDown ? Appearance.colors.colSecondaryContainerActive : 
        button.focus ? Appearance.m3colors.m3tertiaryContainer : 
        Appearance.m3colors.m3secondaryContainer
    colBackgroundHover: Appearance.m3colors.m3tertiaryContainer
    colRipple: Appearance.colors.colSecondaryContainerActive

    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    background.implicitHeight: 120
    background.implicitWidth: 120

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            keyboardDown = true
            button.clicked()
            event.accepted = true;
        }
    }
    Keys.onReleased: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            keyboardDown = false
            event.accepted = true;
        }
    }

    contentItem: MaterialSymbol {
        id: icon
        anchors.fill: parent
        color: Appearance.colors.colOnLayer0
        horizontalAlignment: Text.AlignHCenter
        iconSize: 45
        text: buttonIcon
    }

    StyledToolTip {
        content: buttonText
    }

}
