import qs.modules.common
import qs.modules.common.models.quickToggles
import qs.modules.common.widgets
import qs.services
import QtQuick

AndroidQuickToggleButton {
    id: root

    required property string vpnName

    toggleModel: VpnToggle {
        vpnName: root.vpnName
    }
}
