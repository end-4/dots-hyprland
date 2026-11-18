import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: Translation.tr("Auto-Rotate")

    available: AutoRotate.available
    toggled: AutoRotate.active
    icon: "repeat"

    Component.onCompleted: {
        AutoRotate.fetchActiveState()
    }

    mainAction: () => {
        AutoRotate.toggle()
    }

    tooltipText: available ? Translation.tr("Auto-Rotate") : Translation.tr("Auto-Rotate | Requires iio-hyprland")
}
