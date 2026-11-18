pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import qs.services
import qs.modules.ii.island

// Game mode: a fullscreen game with focus shows a low-priority pill and sets
// IslandState.quiet, so notifications stay in history instead of dropping in.
// Driven by Hyprland events only, no polling.
Item {
    id: root

    property bool gameNow: false // a game is currently focused
    property bool pending: false // an event arrived while hyprctl was running

    function evaluate(output) {
        let game = false;
        try {
            const w = JSON.parse(output);
            const fullscreen = w.fullscreen ?? 0;
            const byClass = /^steam_app|\.exe$|gamescope/i.test(w.class ?? "");
            const byTitle = /\.exe$/i.test(w.title ?? "");
            game = fullscreen > 0 && (byClass || byTitle);
        } catch (e) {
            game = false; // no focused window prints nothing parseable
        }

        root.gameNow = game;
        if (game)
            IslandState.setActivity("game", { icon: "sports_esports", text: Translation.tr("Game mode"), priority: 30 });
        else
            IslandState.clearActivity("game");
        IslandState.quiet = ("game" in IslandState.activities) || ("streaming" in IslandState.activities);
    }

    // Never start hyprctl while it is running; queue one more run instead.
    function query() {
        if (activeProc.running) {
            root.pending = true;
            return;
        }
        activeProc.running = true;
    }

    Process {
        id: activeProc
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.evaluate(text)
        }
        onRunningChanged: {
            if (!running && root.pending) {
                root.pending = false;
                activeProc.running = true;
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activewindowv2" || event.name === "fullscreen")
                root.query();
        }
    }

    Component.onCompleted: root.query()
}
