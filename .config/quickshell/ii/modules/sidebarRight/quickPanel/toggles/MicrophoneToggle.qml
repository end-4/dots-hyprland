

import qs
import qs.services
import Quickshell.Services.Pipewire
import Quickshell.Io
import "../"

QuickToggle  {
    visible: Pipewire?.defaultAudioSource !== undefined
    toggled: Pipewire?.defaultAudioSource?.audio?.muted || false
    buttonIcon: toggled ? "mic_off": "mic"
    downAction: () => Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_SOURCE@", "toggle"])
    toggleText:  "Microphone"

    altAction: downAction
}
