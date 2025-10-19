import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell

AndroidQuickToggleButton {
    id: root

    name: Translation.tr("Audio output")
    statusText: toggled ? Translation.tr("Unmuted") : Translation.tr("Muted")
    toggled: !Audio.sink?.audio?.muted
    buttonIcon: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
    onClicked: {
        Audio.sink.audio.muted = !Audio.sink.audio.muted
    }

    altAction: () => {
        root.openMenu()
    }

    StyledToolTip {
        text: Translation.tr("Audio output | Right-click for volume mixer & device selector")
    }
}
