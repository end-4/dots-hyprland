import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    toggled: Idle.inhibit
    property bool autoIdleInhibit: Idle.autoIdleInhibit

    name: Translation.tr("Keep awake")
    statusText: autoIdleInhibit ? Translation.tr("auto Idle: enabled") : Translation.tr("auto Idle: disabled")
    icon: autoIdleInhibit ? "emoji_food_beverage" : "coffee"

    tooltipText: Translation.tr("Keep system awake | Right click to toggle auto mode")

    mainAction: () => {
        Idle.toggleInhibit()
    }
    altAction: () => {
        Idle.toggleAutoInhibit()
    }
}
