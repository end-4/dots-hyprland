pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.ii.island

// Shows brightness, night light and gamma changes in the island instead of end-4's OSD popup.
// end-4's OSD still opens on the same signals, so each flash also hides that popup.
Item {
    id: root

    // Set after a short startup grace period; changes before that are startup state, not user actions.
    property bool armed: false

    // Hide end-4's OSD. Its handler may run before or after ours, so also clear the flag on the next tick.
    function hideOsd() {
        IslandState.suppressOsd(800);
        Qt.callLater(() => { GlobalStates.osdVolumeOpen = false; });
    }

    // The monitor end-4 would change with the brightness keys: the focused screen.
    function focusedMonitor() {
        const name = Hyprland.focusedMonitor?.name ?? "";
        return Brightness.monitors.find(m => m.screen.name === name) ?? null;
    }

    Timer {
        interval: 5000
        running: true
        onTriggered: root.armed = true
    }

    Connections {
        target: Brightness
        function onBrightnessChanged() {
            if (!root.armed)
                return;
            const monitor = root.focusedMonitor();
            if (!monitor)
                return;
            const level = Math.max(0, Math.min(1, monitor.brightness));
            const icon = level < 0.33 ? "brightness_low" : level < 0.66 ? "brightness_medium" : "brightness_high";
            IslandState.flash(icon, Math.round(level * 100) + "%", { progress: level, ms: 1200 });
            root.hideOsd();
        }
    }

    Connections {
        target: Hyprsunset
        function onTemperatureActiveChanged() {
            if (!root.armed)
                return;
            const on = Hyprsunset.temperatureActive;
            IslandState.flash(on ? "bedtime" : "light_mode", on ? Translation.tr("Night light on") : Translation.tr("Night light off"), { ms: 1500 });
        }
        // Gamma is the software dimming that takes over once the hardware brightness is at 0.
        function onGammaChangeAttempt() {
            if (!root.armed)
                return;
            const gamma = Math.round(Hyprsunset.gamma);
            IslandState.flash("contrast", gamma + "%", { progress: gamma / 100, ms: 1200 });
            root.hideOsd();
        }
    }
}
