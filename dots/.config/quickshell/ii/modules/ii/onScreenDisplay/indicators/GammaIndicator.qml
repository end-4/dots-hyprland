import qs.services
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.ii.onScreenDisplay

OsdValueIndicator {
    id: rotateIcon

    icon: "wb_twilight"
    name: Translation.tr("Gamma")
    value: Hyprsunset.gamma / 100 ?? 0.5
}
