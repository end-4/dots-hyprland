import qs.services
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.onScreenDisplay

OsdValueIndicator {
    id: root
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
    property var brightnessMonitor: Brightness.getMonitorForScreen(focusedScreen)

    value: root.brightnessMonitor?.brightness ?? 50
    icon: "light_mode"
    rotateIcon: true
    scaleIcon: true
    name: Translation.tr("Brightness")
}
