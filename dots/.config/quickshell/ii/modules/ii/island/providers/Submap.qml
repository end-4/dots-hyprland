pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.modules.ii.island

// Shows the active Hyprland submap (e.g. the VM passthrough mode) in the pill.
Item {
    id: root

    function prettyName(name: string): string {
        return name.toLowerCase().includes("vm") ? Translation.tr("VM mode") : name;
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "submap")
                return;
            // event.data is the submap name, empty when leaving a submap.
            const name = (event.data ?? "").trim();
            if (name === "") {
                IslandState.clearActivity("submap");
                return;
            }
            IslandState.setActivity("submap", {
                icon: "keyboard_command_key",
                text: root.prettyName(name),
                priority: 70
            });
        }
    }
}
