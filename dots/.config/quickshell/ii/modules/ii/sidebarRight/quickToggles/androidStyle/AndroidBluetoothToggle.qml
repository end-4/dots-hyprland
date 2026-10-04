import qs.services
import qs.modules.common
import qs.modules.common.models.quickToggles
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Bluetooth

AndroidQuickToggleButton {
    id: root
    
    toggleModel: BluetoothToggle {}

    mainAction: () => {
        Quickshell.execDetached([
            "bash", "-lc",
            "rfkill list bluetooth | grep -q 'Soft blocked: yes' && rfkill unblock bluetooth || rfkill block bluetooth"
        ])
    }
}
