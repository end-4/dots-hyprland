pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Applies Config.options.language.keyboard (an XKB layout code, "" = keep the Hyprland config) to Hyprland,
// at startup, when the setting changes, and again after a Hyprland config reload (which resets it).
Scope {
    id: root

    readonly property string layout: Config.options?.language?.keyboard ?? ""
    readonly property bool valid: /^[a-z0-9_,]+$/.test(layout)

    function apply() {
        if (!Config.ready || layout === "" || !valid)
            return;
        Quickshell.execDetached(["hyprctl", "eval", `hl.config({input={kb_layout="${layout}"}})`]);
    }

    onLayoutChanged: apply()

    Connections {
        target: Config
        function onReadyChanged() {
            root.apply();
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded")
                root.apply();
        }
    }

    Component.onCompleted: apply()
}
