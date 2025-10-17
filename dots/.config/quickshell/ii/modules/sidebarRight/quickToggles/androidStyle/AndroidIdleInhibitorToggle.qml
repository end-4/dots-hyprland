import qs
import qs.modules.common.widgets
import qs.modules.common
import qs.services

AndroidQuickToggleButton {
    id: root
    toggled: Idle.inhibit
    buttonIcon: toggled ? "kettle" : "coffee"
    titleText: "Idle Inhibitor"
    descText: toggled ? "On" : "Off"
    onClicked: {
        if (Config.options.quickToggles.android.inEditMode) return;
        Idle.toggleInhibit()
    }
    StyledToolTip {
        text: Translation.tr("Keep system awake")
    }

}
