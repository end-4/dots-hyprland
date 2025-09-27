import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs
import qs.services
import Quickshell.Io

QuickToggleButton {
    id: nightLightButton

    property int nightLightState: 0 // Start with "off" state

    toggled: nightLightState > 0
    buttonIcon: {
        switch (nightLightState) {
            case 0: return "bedtime"; // Off
            case 1: return "bedtime"; // On
            case 2: return "night_sight_auto"; // Auto
        }
    }

    onClicked: {
        // Cycle through states: 0 (off) -> 1 (on) -> 2 (auto) -> 0 (off)
        nightLightState = (nightLightState + 1) % 3;

        switch (nightLightState) {
            case 0: // Set to Off
                Config.options.light.night.automatic = false;
                if (Hyprsunset.active) {
                    Hyprsunset.toggle();
                }
                break;
            case 1: // Set to On
                Config.options.light.night.automatic = false;
                if (!Hyprsunset.active) {
                    Hyprsunset.toggle();
                }
                break;
            case 2: // Set to Auto
                Config.options.light.night.automatic = true;
                break;
        }
    }
}
