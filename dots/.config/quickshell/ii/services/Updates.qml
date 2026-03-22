pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/*
 * System updates service. Currently only supports Arch.
 */
Singleton {
    id: root

    property bool available: false
    property alias checking: checkUpdatesProc.running
    property int count: 0
    property bool pendingBackgroundCheck: false
    property int pendingNotificationCount: 0
    
    readonly property bool updateAdvised: available && count > Config.options.updates.adviseUpdateThreshold
    readonly property bool updateStronglyAdvised: available && count > Config.options.updates.stronglyAdviseUpdateThreshold

    function load() {}
    function openSystemSettings() {
        Quickshell.execDetached([
            "env",
            "QS_SETTINGS_PAGE=system",
            "qs",
            "-p",
            Quickshell.shellPath("settings.qml")
        ]);
    }
    function runSystemUpdate() {
        Quickshell.execDetached(["bash", "-c", Config.options.apps.update]);
    }
    function openSystemSettingsAndRunUpdate() {
        openSystemSettings();
        runSystemUpdate();
    }
    function refresh(backgroundCheck = false) {
        if (!available) return;
        pendingBackgroundCheck = backgroundCheck;
        print("[Updates] Checking for system updates")
        checkUpdatesProc.running = true;
    }

    Timer {
        interval: Config.options.updates.checkInterval * 60 * 1000
        repeat: true
        running: Config.ready && Config.options.updates.enableCheck
        onTriggered: {
            print("[Updates] Periodic update check due")
            root.refresh(true);
        }
    }

    Process {
        id: checkAvailabilityProc
        running: Config.ready && Config.options.updates.enableCheck
        command: ["which", "checkupdates"]
        onExited: (exitCode, exitStatus) => {
            root.available = (exitCode === 0);
            root.refresh();
        }
    }

    Process {
        id: checkUpdatesProc
        command: ["bash", "-c", "checkupdates | wc -l"]
        stdout: StdioCollector {
            onStreamFinished: {
                const previousCount = root.count;
                const parsedCount = parseInt(text.trim());
                const nextCount = Number.isNaN(parsedCount) ? 0 : parsedCount;
                root.count = nextCount;

                const shouldNotify = root.pendingBackgroundCheck
                    && (Config.options.updates.notifyAvailableInBackground ?? false)
                    && nextCount > 0
                    && previousCount <= 0;

                if (shouldNotify) {
                    root.pendingNotificationCount = nextCount;
                    updateNotificationActionProc.running = true;
                }

                root.pendingBackgroundCheck = false;
            }
        }
    }

    Process {
        id: updateNotificationActionProc
        command: [
            "notify-send",
            Translation.tr("Updates are available"),
            Translation.tr("%1 package updates are available").arg(root.pendingNotificationCount),
            "--action=update-now=" + Translation.tr("Update now"),
            "--wait",
            "-a", "Shell",
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "update-now")
                    root.openSystemSettingsAndRunUpdate();
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                Quickshell.execDetached([
                    "notify-send",
                    Translation.tr("Updates are available"),
                    Translation.tr("%1 package updates are available").arg(root.pendingNotificationCount),
                    "-a",
                    "Shell",
                ]);
            }
        }
    }
}
