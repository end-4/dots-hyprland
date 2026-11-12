pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.modules.common
import qs.modules.ii.island

// Flashes the keyboard layout (US / RU / AM) when the user switches it.
Item {
    id: root

    // Last layout we flashed (or seeded from), so repeated signals don't re-flash.
    property string lastKey: ""
    // The first fully-resolved layout is the startup value: remember it, don't flash.
    property bool seeded: false

    // Hyprland reports variants as one string (e.g. "ruphonetic_winkeys"); the
    // short code is the longest matching entry from the keyboard's layout list.
    function shortCode(code: string): string {
        let best = "";
        for (const c of HyprlandXkb.layoutCodes) {
            if ((code === c || code.startsWith(c)) && c.length > best.length)
                best = c;
        }
        return (best || code).toUpperCase();
    }

    // The name and code arrive in separate steps (code may need a file read),
    // so both signals funnel through here and act only once the pair is complete.
    function check(): void {
        const name = HyprlandXkb.currentLayoutName;
        const code = HyprlandXkb.currentLayoutCode;
        // A code that doesn't match the new name is still the previous layout's; wait for the real one.
        if (!name || !code || HyprlandXkb.cachedLayoutCodes[name] !== code)
            return;
        const key = name + "|" + code;
        if (!root.seeded) {
            root.seeded = true;
            root.lastKey = key;
            return;
        }
        if (key === root.lastKey)
            return;
        root.lastKey = key;
        IslandState.flash("keyboard", root.shortCode(code), { ms: 1200 });
    }

    Connections {
        target: HyprlandXkb
        function onCurrentLayoutNameChanged() { root.check(); }
        function onCurrentLayoutCodeChanged() { root.check(); }
    }
}
