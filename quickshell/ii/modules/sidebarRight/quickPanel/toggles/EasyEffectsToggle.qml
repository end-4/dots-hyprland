
import qs
import qs.services
import "../"
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick

QuickToggle {
    id: root
    toggled: EasyEffects.active
    halfToggled : false
    toggleText : "EasyEffects"
    stateText: EasyEffects.active ? "Active" : "Inactive"
    visible: EasyEffects.available
    buttonIcon: "instant_mix"

    Component.onCompleted: {
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
