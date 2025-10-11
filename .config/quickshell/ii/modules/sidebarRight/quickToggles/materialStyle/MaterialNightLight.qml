import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs
import qs.services
import Quickshell.Io

MaterialQuickToggleButton {
    id: root
    buttonSize: 2
    property bool enabled: Hyprsunset.active
    toggled: enabled
    buttonIcon: Config.options.light.night.automatic ? "night_sight_auto" : "bedtime"
    titleText: "Night Light"
    altText: toggled ? Config.options.light.night.automatic ? "Automatic" : "On" : "Off"
    onClicked: {
        Hyprsunset.toggle()
    }

    altAction: () => {
        Config.options.light.night.automatic = !Config.options.light.night.automatic
    }

    Component.onCompleted: {
        Hyprsunset.fetchState()
    }
    
    StyledToolTip {
        text: Translation.tr("Night Light | Right-click to toggle Auto mode")
    }
}
