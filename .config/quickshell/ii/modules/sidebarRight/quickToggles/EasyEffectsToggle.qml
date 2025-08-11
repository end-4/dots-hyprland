import qs.modules.common.widgets
import qs
import qs.services
import QtQuick
import Quickshell.Io
import Quickshell
import Quickshell.Hyprland

QuickToggleButton {
    id: root
    toggled: EasyEffects.active
    visible: EasyEffects.available
    buttonIcon: "instant_mix"

    Component.onCompleted: {
        EasyEffects.fetchActiveState()
    }

    onClicked: {
        EasyEffects.toggle()
    }

    altAction: () => {
        Quickshell.execDetached(["easyeffects"])
        GlobalStates.sidebarRightOpen = false
    }

    StyledToolTip {
        content: Translation.tr("EasyEffects | Right-click to configure")
    }
}
