import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick

/**
 * Material 3 dialog button. See https://m3.material.io/components/dialogs/overview
 */
RippleButton {
    id: root

    property string buttonText
    padding: 14
    implicitHeight: 36
    implicitWidth: buttonTextWidget.implicitWidth + padding * 2
    buttonRadius: Appearance?.rounding.full ?? 9999

    property color colEnabled: Appearance?.colors.colPrimary ?? "#65558F"
    property color colDisabled: Appearance?.m3colors.m3outline ?? "#8D8C96"
    colBackground: ColorUtils.transparentize(Appearance.colors.colLayer3)
    colBackgroundHover: Appearance.colors.colLayer3Hover
    colRipple: Appearance.colors.colLayer3Active
    property alias colText: buttonTextWidget.color

    contentItem: StyledText {
        id: buttonTextWidget
        anchors.fill: parent
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        text: buttonText
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Appearance?.font.pixelSize.small ?? 12
        color: root.enabled ? root.colEnabled : root.colDisabled

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

}
