pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * Bar toggle that keeps the system awake: blocks suspend, idle (lock / screen off / auto-suspend) and lid-close sleep.
 *
 * Left-click runs scripts/sleep-inhibit-toggle.sh, which holds a logind BLOCK inhibitor
 * (sleep + idle + handle-lid-switch) via a detached `systemd-inhibit` process. While it is
 * held: hypridle's listeners pause (no lock, no dpms off, no auto-suspend — hypridle honours
 * systemd idle inhibitors), manual/automatic suspend is refused, and closing the lid does
 * nothing. Killing that process releases everything; nothing is configured permanently, so a
 * crash or logout can never strand the machine with sleep disabled.
 *
 * State is NOT polled: the script writes "on"/"off" to $XDG_RUNTIME_DIR/sleep-inhibit.state
 * and the FileView below watches it, so the icon also follows changes made from a terminal.
 * `statusProc` is the authority at startup (it self-heals a stale PID file and creates the
 * state file, which is what gives the watcher something to attach to).
 */
MouseArea {
    id: root

    readonly property string scriptPath: Quickshell.shellPath("scripts/sleep-inhibit-toggle.sh")
    readonly property string statePath: `${Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"}/sleep-inhibit.state`

    property bool inhibited: false
    property color colNormal: Appearance.colors.colOnLayer0
    property color colActive: Appearance.colors.colPrimary

    function refresh() {
        statusProc.running = true;
    }

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton
    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    onPressed: event => {
        if (event.button === Qt.LeftButton) {
            Quickshell.execDetached(["bash", root.scriptPath, "toggle"]);
            // Optimistic flip so the icon reacts instantly; the script needs ~300 ms to verify
            // the lock, after which statusProc (and the file watcher) confirm the real state.
            root.inhibited = !root.inhibited;
            confirmTimer.restart();
        }
        event.accepted = true;
    }

    // Source of truth. Also rewrites the state file, so the FileView watcher always has a
    // file to attach to (first run after a boot creates it).
    Process {
        id: statusProc
        command: ["bash", root.scriptPath, "status"]
        stdout: StdioCollector {
            id: statusCollector
            onStreamFinished: {
                root.inhibited = statusCollector.text.trim() === "on";
                stateFile.reload();
            }
        }
    }

    Timer {
        id: confirmTimer
        interval: 600
        onTriggered: root.refresh()
    }

    // Instant updates when the state changes outside this widget (e.g. the script run from a
    // terminal). Missing file (fresh boot, never toggled) simply leaves the state at "off".
    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.inhibited = stateFile.text().trim() === "on"
    }

    Component.onCompleted: root.refresh()

    MaterialSymbol {
        id: icon
        anchors.centerIn: parent
        text: root.inhibited ? "bedtime_off" : "bedtime"
        iconSize: Appearance.font.pixelSize.larger
        fill: root.inhibited ? 1 : 0
        color: root.inhibited ? root.colActive : root.colNormal

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    PopupToolTip {
        id: tooltip
        text: root.inhibited ? Translation.tr("Staying awake: no screen off, no sleep (click to allow sleep)") : Translation.tr("Sleep allowed (click to stay awake)")
        extraVisibleCondition: root.containsMouse
        alternativeVisibleCondition: extraVisibleCondition
        anchorEdges: (!Config.options.bar.bottom && !Config.options.bar.vertical) ? Edges.Bottom : Edges.Top
    }
}
