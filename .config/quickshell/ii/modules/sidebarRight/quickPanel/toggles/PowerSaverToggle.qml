

import qs
import qs.services
import "../"
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.UPower

QuickToggle {
    id: root
    visible: PowerProfiles.hasPerformanceProfile
    toggled: PowerProfiles.profile === PowerProfiles.PowerSaver
    toggleText : "Power Saving Mode"
    buttonIcon: "battery_saver"

    downAction:() => {
       PowerProfiles.profile = toggled ? PowerProfile.Balanced : PowerProfiles.PowerSaver
    }

    altAction: downAction


}
