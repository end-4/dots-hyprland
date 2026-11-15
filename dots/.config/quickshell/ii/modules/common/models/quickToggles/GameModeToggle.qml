import QtQuick
import qs.modules.common.models.hyprland
import qs.services

QuickToggleModel {
    id: root
    name: Translation.tr("Game mode")
    // Unknown/loading values must not be interpreted as an enabled game mode.
    available: typeof confOpt.value === "boolean" || typeof confOpt.value === "number"
    toggled: confOpt.value === false || confOpt.value === 0
    icon: "gamepad"

    mainAction: () => {
        if (!root.available) return;
        if (!root.toggled) {
            HyprlandConfig.setMany({
                "animations:enabled": false,
                "decoration:shadow:enabled": false,
                "decoration:blur:enabled": false,
                "general:gaps_in": 0,
                "general:gaps_out": 0,
                "general:border_size": 1,
                "decoration:rounding": 0,
                "general:allow_tearing": true
            });
        } else {
            HyprlandConfig.resetMany([ //
                "animations:enabled", //
                "decoration:shadow:enabled", //
                "decoration:blur:enabled", //
                "general:gaps_in", //
                "general:gaps_out", //
                "general:border_size", //
                "decoration:rounding", //
                "general:allow_tearing", //
            ]);
        }
    }

    HyprlandConfigOption {
        id: confOpt
        objectName: "gameModeAnimations"
        key: "animations:enabled"
    }

    tooltipText: Translation.tr("Game mode")
}
