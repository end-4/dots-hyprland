pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import qs.services
import qs.modules.ii.island

// "What's playing?" from the island's long-press toggles. Listens to the system audio through
// end-4's SongRec service and pushes the match as a card. The SongRec process is only ever started here
// or by end-4's own toggle, never twice.
Item {
    id: root

    readonly property string activityId: "songrec"
    property bool installed: true  // refined by the one-shot check below; a request proceeds until then
    property bool pending: false   // a request is waiting for an answer

    // One-shot check at load, so a missing binary gets a clear flash instead of a silent no-op.
    Process {
        command: ["sh", "-c", "command -v songrec >/dev/null 2>&1"]
        running: true
        onExited: exitCode => {
            root.installed = exitCode === 0;
        }
    }

    // A match can arrive just after the process exits (stdout is read asynchronously),
    // so wait a moment before calling it a miss.
    Timer {
        id: noMatchTimer
        interval: 1500
        onTriggered: {
            if (!root.pending || SongRec.running)
                return;
            root.pending = false;
            IslandState.clearActivity(root.activityId);
            IslandState.flash("music_off", Translation.tr("No match"), { ms: 1600 });
        }
    }

    function startListening() {
        if (!root.installed) {
            IslandState.flash("music_off", Translation.tr("songrec not installed"), { ms: 2000 });
            return;
        }
        root.pending = true;
        IslandState.setActivity(root.activityId, { icon: "graphic_eq", text: Translation.tr("Listening…"), priority: 65 });
        // Already running (started from end-4's own UI): just wait for its result.
        if (SongRec.running)
            return;
        SongRec.monitorSource = SongRec.MonitorSource.Monitor;
        SongRec.toggleRunning(true);
    }

    Connections {
        target: IslandState
        function onSongRecognitionRequested() {
            root.startListening();
        }
    }

    Connections {
        target: SongRec
        function onRecognizedTrackChanged() {
            const track = SongRec.recognizedTrack;
            if (!track || !track.title)
                return;
            noMatchTimer.stop();
            root.pending = false;
            IslandState.clearActivity(root.activityId);
            IslandState.pushCard("songrec", {
                icon: "music_note",
                title: track.title,
                body: track.subtitle ?? "",
                ttl: 9000,
                actions: track.url ? [{ text: Translation.tr("Open"), command: ["xdg-open", track.url] }] : []
            });
        }
        function onRunningChanged() {
            if (!SongRec.running && root.pending)
                noMatchTimer.restart();
        }
    }
}
