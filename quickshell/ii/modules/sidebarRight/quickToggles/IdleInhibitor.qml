import qs.modules.common.widgets
import qs
import qs.services

QuickToggleButton {
    id: root
    toggled: Idle.inhibit
    buttonIcon: "coffee"
    onClicked: {
        Idle.toggleInhibit()
    }
    StyledToolTip {
        content: Translation.tr("Keep system awake")
    }

}
