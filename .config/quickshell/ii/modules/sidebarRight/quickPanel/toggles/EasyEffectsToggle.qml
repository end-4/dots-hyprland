import qs
import qs.services
import "../"
import Quickshell
import QtQuick

QuickToggle {
    id: root
    isSupported: EasyEffects.available
    toggled: EasyEffects.active
    halfToggled : false
    toggleText : "EasyEffects"
    stateText: EasyEffects.active ? "Active" : "Inactive"

    buttonIcon: "instant_mix"

    Component.onCompleted: {
        EasyEffects.fetchAvailability()
        EasyEffects.fetchActiveState()
    }

    downAction:() => {
        EasyEffects.toggle()
    }

    altAction: () => {
        Quickshell.execDetached(["easyeffects"])
        GlobalStates.sidebarRightOpen = false
    }


}
