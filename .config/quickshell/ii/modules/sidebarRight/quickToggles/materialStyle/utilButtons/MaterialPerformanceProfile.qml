import qs
import qs.modules.common.widgets
import qs.modules.common
import qs.services
import Quickshell
import Quickshell.Services.UPower
import "../"

MaterialQuickToggleButton {
    id: root
    buttonSize: 2
    toggled: true
    buttonIcon: switch(PowerProfiles.profile) {
                        case PowerProfile.PowerSaver: return "energy_savings_leaf"
                        case PowerProfile.Balanced: return "settings_slow_motion"
                        case PowerProfile.Performance: return "local_fire_department"
                    }
    titleText: "Profile"
    altText: switch(PowerProfiles.profile) {
                        case PowerProfile.PowerSaver: return "Power Saver"
                        case PowerProfile.Balanced: return "Balanced"
                        case PowerProfile.Performance: return "Performance"
                    }
    
    onClicked: event => {
        if (PowerProfiles.hasPerformanceProfile) {
            switch(PowerProfiles.profile) {
                case PowerProfile.PowerSaver: PowerProfiles.profile = PowerProfile.Balanced
                break;
                case PowerProfile.Balanced: PowerProfiles.profile = PowerProfile.Performance
                break;
                case PowerProfile.Performance: PowerProfiles.profile = PowerProfile.PowerSaver
                break;
            }
        } else {
            PowerProfiles.profile = PowerProfiles.profile == PowerProfile.Balanced ? PowerProfile.PowerSaver : PowerProfile.Balanced
        }
    }
    StyledToolTip {
        text: altText
    }
}