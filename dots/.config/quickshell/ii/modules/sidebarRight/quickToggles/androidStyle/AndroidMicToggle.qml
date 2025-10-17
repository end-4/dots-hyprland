import qs
import qs.modules.common.widgets
import qs.modules.common
import qs.services
import Quickshell
import Quickshell.Services.Pipewire

import "../"

AndroidQuickToggleButton {
    id: root
    toggled: !Pipewire.defaultAudioSource?.audio?.muted
    buttonIcon: Pipewire.defaultAudioSource?.audio?.muted ? "mic_off" : "mic"
    titleText: Translation.tr("Toggle Microphone")
    onClicked: {
        if (Config.options.quickToggles.android.inEditMode) return;
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_SOURCE@", "toggle"])
    }
    StyledToolTip {
        text: titleText
    }
}