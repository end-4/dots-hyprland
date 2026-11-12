import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.island.monitor

// Bar button (where the AI sidebar button was) that opens the system monitor.
RippleButton {
    id: root
    property real buttonPadding: 5
    implicitWidth: icon.implicitWidth + buttonPadding * 2 + 2
    implicitHeight: icon.implicitHeight + buttonPadding * 2
    buttonRadius: Appearance.rounding.full
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active
    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.colors.colSecondaryContainerActive
    toggled: SystemMonitorService.open

    onPressed: SystemMonitorService.open = !SystemMonitorService.open

    MaterialSymbol {
        id: icon
        anchors.centerIn: parent
        text: "monitoring"
        iconSize: 21
        fill: SystemMonitorService.open ? 1 : 0
        color: SystemMonitorService.open ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0
    }
}
