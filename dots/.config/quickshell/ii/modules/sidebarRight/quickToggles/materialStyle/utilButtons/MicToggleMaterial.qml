import qs
import qs.modules.common.widgets
import qs.modules.common
import qs.services
import Quickshell
import Quickshell.Services.Pipewire

import "../"

MaterialQuickToggleButton {
    id: root
    buttonSize: 2
    toggled: !Pipewire.defaultAudioSource?.audio?.muted
    buttonIcon: Pipewire.defaultAudioSource?.audio?.muted ? "mic_off" : "mic"
    titleText: "Toggle Mic"
    descText: toggled? "Mic On" : "Mic Off"
    onClicked: {
        if (GlobalStates.quickTogglesEditMode) return;
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_SOURCE@", "toggle"])
    }
    StyledToolTip {
        text: titleText
    }
}