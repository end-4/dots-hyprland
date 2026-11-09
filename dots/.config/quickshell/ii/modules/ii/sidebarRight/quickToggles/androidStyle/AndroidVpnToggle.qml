import qs.modules.common
import qs.modules.common.models.quickToggles
import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io

AndroidQuickToggleButton {
    id: root
    
    required property string connectionName
    toggleModel: VpnToggleModel {
        connectionName: root.connectionName
    }
    
    isDynamic: true

}
