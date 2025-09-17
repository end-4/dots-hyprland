import qs
import qs.services
import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import Quickshell.Io
import "../"

QuickToggle {
    id: nightLightButton
    toggled: Hyprsunset.active
    toggleText: "Night Light"
    buttonIcon: Config.options.light.night.automatic ? "night_sight_auto" : "bedtime"
    downAction: Hyprsunset.toggle

    altAction: () => {
        Config.options.light.night.automatic = !Config.options.light.night.automatic
    }

    Component.onCompleted: {
        Hyprsunset.fetchState()
    }


}
