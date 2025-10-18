import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell

AndroidQuickToggleButton {
    id: root

    name: Translation.tr("Virtual Keyboard")
    toggled: GlobalStates.oskOpen
    buttonIcon: toggled ? "keyboard_hide" : "keyboard"
    onClicked: {
        GlobalStates.oskOpen = !GlobalStates.oskOpen
    }

    StyledToolTip {
        text: Translation.tr("On-screen keyboard")
    }
}
