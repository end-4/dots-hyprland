pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string killDialogQmlPath: FileUtils.trimFileProtocol(Quickshell.shellPath("killDialog.qml"))

    function load() {
        // dummy to force init
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready) checkConflictsProc.running = true
        }
    }

    Process {
        id: checkConflictsProc
        command: ["bash", "-c", `echo "$(pidof kded6);$(pidof mako dunst)"`]
        stdout: StdioCollector {
            onStreamFinished: {
                const output = this.text;
                const conflictingTrays = output.split(";")[0].trim().length > 0;
                const conflictingNotifications = output.split(";")[1].trim().length > 0;
                var openDialog = false;
                if (conflictingTrays) {
                    if (!Config.options.conflictKiller.autoKillTrays) openDialog = true;
                    else Quickshell.execDetached(["killall", "kded6"])
                }
                if (conflictingNotifications) {
                    if (!Config.options.conflictKiller.autoKillNotificationDaemons) openDialog = true;
                    else Quickshell.execDetached(["killall", "mako", "dunst"])
                }
                if (openDialog) {
                    Quickshell.execDetached(["qs", "-p", root.killDialogQmlPath])
                }
            }
        }
    }
}
