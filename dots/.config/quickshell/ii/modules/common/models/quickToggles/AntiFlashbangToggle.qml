import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: Translation.tr("Anti-flashbang")
    tooltipText: Translation.tr("Anti-flashbang")
    icon: "flash_off"
    toggled: HyprlandAntiFlashbangShader.enabled

    mainAction: () => {
        HyprlandAntiFlashbangShader.toggle()
    }
    hasMenu: true
}
