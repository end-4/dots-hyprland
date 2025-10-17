import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs
import qs.services
import Quickshell.Io

AndroidQuickToggleButton {
    id: root
    property bool enabled: Hyprsunset.active
    toggled: enabled
    buttonIcon: toggled ? Config.options.light.night.automatic ? "night_sight_auto" : "bedtime" : "bedtime_off"
    titleText: Translation.tr("Night Light")
    descText: toggled ? Config.options.light.night.automatic ? "Automatic" : "On" : "Off"
    onClicked: {
        if (Config.options.quickToggles.android.inEditMode) return;
        Hyprsunset.toggle()
    }

    altAction: () => {
        if (Config.options.quickToggles.android.inEditMode) return;
        Config.options.light.night.automatic = !Config.options.light.night.automatic
    }

    Component.onCompleted: {
        Hyprsunset.fetchState()
    }
    
    StyledToolTip {
        text: Translation.tr("Night Light | Right-click to toggle Auto mode")
    }
}
