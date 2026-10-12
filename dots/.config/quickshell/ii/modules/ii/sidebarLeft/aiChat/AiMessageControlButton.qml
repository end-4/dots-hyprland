import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick

GroupButton {
    id: button
    property string buttonIcon
    property bool activated: false
    // For actions that report back by holding a confirmed icon; buttons whose activated
    // state means something lasting, like an open editor, just set it and leave it
    function confirm() {
        button.activated = true;
        confirmationTimer.restart();
    }
    Timer {
        id: confirmationTimer
        interval: 1500
        repeat: false
        onTriggered: button.activated = false
    }

    toggled: activated
    baseWidth: height
    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
    colBackgroundActive: Appearance.colors.colSecondaryContainerActive

    contentItem: MaterialSymbol {
        horizontalAlignment: Text.AlignHCenter
        iconSize: Appearance.font.pixelSize.larger
        text: buttonIcon
        color: button.activated ? Appearance.m3colors.m3onPrimary :
            button.enabled ? Appearance.m3colors.m3onSurface :
            Appearance.colors.colOnLayer1Inactive

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }
}
