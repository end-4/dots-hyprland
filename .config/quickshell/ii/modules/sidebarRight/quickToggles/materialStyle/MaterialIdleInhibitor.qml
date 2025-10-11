import qs
import qs.modules.common.widgets
import qs.modules.common
import qs.services

MaterialQuickToggleButton {
    id: root
    buttonSize: 2
    toggled: Idle.inhibit
    buttonIcon: "coffee"
    titleText: "Idle Inhibitor"
    altText: toggled ? "On" : "Off"
    onClicked: {
        Idle.toggleInhibit()
    }
    StyledToolTip {
        text: Translation.tr("Keep system awake")
    }

}
