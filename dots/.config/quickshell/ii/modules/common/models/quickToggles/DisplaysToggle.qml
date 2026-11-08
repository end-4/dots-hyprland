import QtQuick
import qs.modules.common
import qs.services

QuickToggleModel {
    name: Translation.tr("Displays")
    hasStatusText: false
    icon: "monitor"
    toggled: false
    mainAction: () => {
        if (!Config.options.sidebar.displays.enable) return;
        Displays.requestDialog();
    }
    tooltipText: Translation.tr("Displays")
}
