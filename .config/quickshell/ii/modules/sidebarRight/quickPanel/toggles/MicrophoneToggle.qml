import qs
import qs.services
import Quickshell.Services.Pipewire
import Quickshell
import Quickshell.Io
import "../"

QuickToggle {
    isSupported: Pipewire?.defaultAudioSource !== undefined
    toggled: !Pipewire?.defaultAudioSource?.audio?.muted
    buttonIcon: toggled ? "mic" : "mic_off"
    downAction: () => {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_SOURCE@", "toggle"]);
    }
    toggleText: "Microphone"

}
