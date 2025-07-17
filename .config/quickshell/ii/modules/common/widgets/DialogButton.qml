import qs.modules.common
import QtQuick

/**
 * Material 3 dialog button. See https://m3.material.io/components/dialogs/overview
 */
RippleButton {
    id: button

    property string buttonText
    implicitHeight: 30
    implicitWidth: buttonTextWidget.implicitWidth + 15 * 2
    buttonRadius: Appearance?.rounding.full ?? 9999

    property color colEnabled: Appearance?.colors.colPrimary ?? "#65558F"
    property color colDisabled: Appearance?.m3colors.m3outline ?? "#8D8C96"

    contentItem: StyledText {
        id: buttonTextWidget
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15
        text: buttonText
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Appearance?.font.pixelSize.small ?? 12
        color: button.enabled ? button.colEnabled : button.colDisabled

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

}
