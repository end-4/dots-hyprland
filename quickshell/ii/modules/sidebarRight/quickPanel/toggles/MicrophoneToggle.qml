

import qs
import qs.services
import Quickshell.Services.Pipewire
import Quickshell.Io
import "../"

QuickToggle  {
    toggled: Pipewire.defaultAudioSource?.audio?.muted
    buttonIcon: toggled ? "mic_off": "mic"
    downAction: () => Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_SOURCE@", "toggle"])
    toggleText:  "Microphone"

    altAction: downAction
}
