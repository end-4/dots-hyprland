pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland

Scope {
    id: root

    // Initial state for region selector - set before opening, applied when loader creates item
    property int initialMediaType: WRegionSelectionPanel.MediaType.Image
    property int initialImageAction: WRegionSelectionPanel.ImageAction.Copy
    property string _pendingRecordAction: ""

    function dismiss() {
        GlobalStates.regionSelectorOpen = false;
    }

    function _doRecord() {
        root.initialMediaType = WRegionSelectionPanel.MediaType.Video;
        GlobalStates.regionSelectorOpen = true;
    }
    function _doRecordWithSound() {
        root.initialMediaType = WRegionSelectionPanel.MediaType.Video;
        GlobalStates.regionSelectorOpen = true;
    }

    Process {
        id: checkRecordingProc
        command: ["pgrep", "-f", "gpu-screen-recorder"]
        onExited: (exitCode) => {
            if (exitCode === 0) {
                Quickshell.execDetached([Directories.recordScriptPath, "--config", FileUtils.trimFileProtocol(Directories.shellConfigPath)]);
                root.dismiss();
            } else if (root._pendingRecordAction === "record") {
                root._doRecord();
            } else if (root._pendingRecordAction === "recordWithSound") {
                root._doRecordWithSound();
            }
            root._pendingRecordAction = "";
        }
    }

    Loader {
        id: regionSelectorLoader
        active: GlobalStates.regionSelectorOpen

        sourceComponent: WRegionSelectionPanel {
            onClosed: root.dismiss()

            Component.onCompleted: {
                mediaType = root.initialMediaType;
                imageAction = root.initialImageAction;
            }
        }
    }

    function screenshot() {
        root.initialMediaType = WRegionSelectionPanel.MediaType.Image;
        root.initialImageAction = WRegionSelectionPanel.ImageAction.Copy;
        GlobalStates.regionSelectorOpen = true;
    }

    function ocr() {
        root.initialMediaType = WRegionSelectionPanel.MediaType.Image;
        root.initialImageAction = WRegionSelectionPanel.ImageAction.CharRecognition;
        GlobalStates.regionSelectorOpen = true;
    }

    function record() {
        if (checkRecordingProc.running) return;
        root._pendingRecordAction = "record";
        checkRecordingProc.running = true;
    }

    function recordWithSound() {
        if (checkRecordingProc.running) return;
        root._pendingRecordAction = "recordWithSound";
        checkRecordingProc.running = true;
    }

    function search() {
        root.initialMediaType = WRegionSelectionPanel.MediaType.Image;
        root.initialImageAction = WRegionSelectionPanel.ImageAction.Search;
        GlobalStates.regionSelectorOpen = true;
    }

    IpcHandler {
        target: "region"

        function screenshot() {
            root.screenshot();
        }
        function ocr() {
            root.ocr();
        }
        function record() {
            root.record();
        }
        function recordWithSound() {
            root.recordWithSound();
        }
        function search() {
            root.search();
        }
    }

    GlobalShortcut {
        name: "regionScreenshot"
        description: "Takes a screenshot of the selected region"
        onPressed: root.screenshot()
    }
    GlobalShortcut {
        name: "regionSearch"
        description: "Searches the selected region"
        onPressed: root.search()
    }
    GlobalShortcut {
        name: "regionOcr"
        description: "Recognizes text in the selected region"
        onPressed: root.ocr()
    }
    GlobalShortcut {
        name: "regionRecord"
        description: "Records the selected region"
        onPressed: root.record()
    }
    GlobalShortcut {
        name: "regionRecordWithSound"
        description: "Records the selected region with sound"
        onPressed: root.recordWithSound()
    }
}
