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

    function dismiss() {
        GlobalStates.regionSelectorOpen = false;
    }

    Loader {
        id: regionSelectorLoader
        active: GlobalStates.regionSelectorOpen

        sourceComponent: WRegionSelectionPanel {
            onClosed: root.dismiss()
        }
    }

    function screenshot() {
        GlobalStates.regionSelectorOpen = true;
    }

    function ocr() {
        GlobalStates.regionSelectorOpen = true;
        regionSelectorLoader.item.mediaType = WRegionSelectionPanel.MediaType.Image;
        regionSelectorLoader.item.imageAction = WRegionSelectionPanel.ImageAction.CharRecognition;
    }

    function record() {
        GlobalStates.regionSelectorOpen = true;
        regionSelectorLoader.item.mediaType = WRegionSelectionPanel.MediaType.Video;
        regionSelectorLoader.item.videoAction = WRegionSelectionPanel.VideoAction.Record;
    }

    function recordWithSound() {
        GlobalStates.regionSelectorOpen = true;
        regionSelectorLoader.item.mediaType = WRegionSelectionPanel.MediaType.Video;
        regionSelectorLoader.item.videoAction = WRegionSelectionPanel.VideoAction.RecordWithSound;
    }

    function search() {
        GlobalStates.regionSelectorOpen = true;
        regionSelectorLoader.item.mediaType = WRegionSelectionPanel.MediaType.Image;
        regionSelectorLoader.item.imageAction = WRegionSelectionPanel.ImageAction.Search;
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
