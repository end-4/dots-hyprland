import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell

AndroidQuickToggleButton {
    id: root

    name: Translation.tr("Microphone")
    statusText: toggled ? Translation.tr("Enabled") : Translation.tr("Muted")
    toggled: !Audio.source?.audio?.muted
    buttonIcon: Audio.source?.audio?.muted ? "mic_off" : "mic"
    onClicked: {
        Audio.source.audio.muted = !Audio.source.audio.muted
    }

    StyledToolTip {
        text: Translation.tr("Microphone")
    }
}
