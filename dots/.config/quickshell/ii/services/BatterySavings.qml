pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.UPower
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root
    property bool sessionActive: false
    property bool pending: false
    property bool stateInitialized: false
    property bool workerStarted: false
    property var state: ({})
    property string processError: ""
    readonly property var options: Config.options.battery.savings
    readonly property bool active: Config.ready && options.enable && Battery.available && UPower.onBattery
    readonly property bool needsRecovery: Object.keys(state.changes || {}).length > 0
    readonly property string statePath: FileUtils.trimFileProtocol(Directories.state) + "/user/battery-savings.json"
    readonly property string settings: JSON.stringify({
        active: root.active,
        limitBrightness: options.limitBrightness,
        brightnessPercent: options.brightnessPercent,
        disableBlur: options.disableBlur,
        disableAnimations: options.disableAnimations,
        setProfile: options.setProfile,
        profile: options.profile
    })
    readonly property string pythonPath: {
        const venv = Quickshell.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV")
            || (FileUtils.trimFileProtocol(Directories.state) + "/.venv");
        return venv.replace(/^~/, FileUtils.trimFileProtocol(Directories.home)) + "/bin/python";
    }

    function load() { sessionActive = true; requestApply(); }
    function requestApply() {
        if (!sessionActive || !Config.ready || (!active && !needsRecovery && !(state.errors || []).length)) return;
        if (worker.running) { pending = true; return; }
        debounce.restart();
    }
    onSettingsChanged: requestApply()

    Timer {
        id: debounce
        interval: 250
        repeat: false
        onTriggered: {
            root.processError = "";
            root.workerStarted = false;
            startGuard.restart();
            worker.exec([root.pythonPath, Quickshell.shellPath("scripts/power/battery-savings.py"), "--settings", root.settings]);
        }
    }
    Timer {
        id: startGuard
        interval: 1000
        repeat: false
        onTriggered: {
            if (!root.workerStarted)
                root.processError = "Unable to start the battery helper. Check the end-4 Python virtual environment.";
        }
    }
    Process {
        id: worker
        onStarted: root.workerStarted = true
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.processError = text.trim()
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && !root.processError) root.processError = "Unable to apply one or more battery options";
            stateFile.reload();
            if (root.pending) { root.pending = false; root.requestApply(); }
        }
    }
    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: error => {
            root.stateInitialized = true;
            if (error !== FileViewError.FileNotFound)
                root.processError = "Unable to read battery recovery state";
        }
        onLoaded: {
            try {
                root.state = JSON.parse(text());
                if (!root.stateInitialized) {
                    root.stateInitialized = true;
                    root.requestApply();
                }
            }
            catch (error) { root.processError = "Invalid battery recovery state: " + error; }
        }
    }
    Connections {
        target: Brightness
        function onBrightnessChanged() {
            if (root.active && root.options.limitBrightness) root.requestApply();
        }
    }
    Connections {
        target: PowerProfiles
        function onHoldsChanged() { root.requestApply(); }
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded") root.requestApply();
        }
    }
}
