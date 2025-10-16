import qs.modules.common.widgets
import qs
import qs.services
import QtQuick
import Quickshell.Io
import Quickshell
import Quickshell.Hyprland

MaterialQuickToggleButton {
    id: root
    buttonSize: 1
    toggled: EasyEffects.active
    visible: EasyEffects.available
    buttonIcon: toggled ? "tune" : "instant_mix"
    titleText: "Easy Effects"
    descText: toggled ? "On" : "Off"
    Component.onCompleted: {
        EasyEffects.fetchActiveState()
    }

    onClicked: {
        if (Config.options.quickToggles.material.inEditMode) return;
        EasyEffects.toggle()
    }

    altAction: () => {
        if (Config.options.quickToggles.material.inEditMode) return;
        Quickshell.execDetached(["bash", "-c", "flatpak run com.github.wwmm.easyeffects || easyeffects"])
        GlobalStates.sidebarRightOpen = false
    }

    StyledToolTip {
        text: Translation.tr("EasyEffects | Right-click to configure")
    }
}
