pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.ii.island

// Dominant album colour for IslandState.accent (equaliser, progress).
Item {
    id: root

    property string artUrl: ""
    // file:// URL the ColorQuantizer reads. ColorQuantizer needs a local file, not http.
    property string localSource: ""
    property bool busy: false

    function applyAccent() {
        if (root.localSource === "" || quantizer.colors.length === 0)
            return;
        let c = ColorUtils.mix(quantizer.colors[0], Appearance.colors.colPrimary, 0.35);
        // Dark surface: lift colours that would be too dark to read.
        if (Qt.color(c).hslLightness < 0.55)
            c = Qt.lighter(c, 1.4);
        IslandState.accent = c;
    }

    function clearAccent() {
        root.localSource = "";
        IslandState.accent = "transparent";
    }

    function resolve() {
        const url = root.artUrl;
        if (url === "") {
            root.clearAccent();
        } else if (url.startsWith("file://")) {
            root.localSource = url;
        } else if (url.startsWith("http://") || url.startsWith("https://")) {
            root.downloadArt(url);
        } else {
            root.clearAccent();
        }
    }

    // Downloads art once per URL. The file name is a hash of the URL, so a file that already exists is reused.
    function downloadArt(url) {
        if (root.busy)
            return;  // onExited re-checks the URL when this download ends
        const path = (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/ii-island/art-" + Qt.md5(url) + ".jpg";
        // Download to .part and rename, so a killed curl never leaves a half-written file behind.
        fetcher.url = url;
        fetcher.path = path;
        fetcher.command = ["sh", "-c", "mkdir -p -m 700 \"${0%/*}\"; [ -s \"$0\" ] || { curl -sf --max-time 6 -o \"$0.part\" \"$1\" && mv -f \"$0.part\" \"$0\"; }", path, url];
        root.busy = true;
        fetcher.running = true;
    }

    function syncArt() {
        root.artUrl = MprisController.activeTrack?.artUrl ?? "";
        root.resolve();
    }

    Connections {
        target: MprisController
        function onActiveTrackChanged() {
            const url = MprisController.activeTrack?.artUrl ?? "";
            if (url === root.artUrl)
                return;
            root.artUrl = url;
            root.resolve();
        }
    }

    ColorQuantizer {
        id: quantizer
        source: root.localSource
        depth: 0  // 2^0 = 1 colour
        rescaleSize: 1  // 1x1 is enough for the dominant colour
    }

    Connections {
        target: quantizer
        function onColorsChanged() {
            root.applyAccent();
        }
    }

    Process {
        id: fetcher
        property string url: ""
        property string path: ""
        command: ["true"]
        onExited: (exitCode) => {
            root.busy = false;
            // The art changed while downloading: start over with the current URL.
            if (fetcher.url !== root.artUrl) {
                root.resolve();
                return;
            }
            if (exitCode === 0)
                root.localSource = "file://" + fetcher.path;
            else
                root.clearAccent();
        }
    }

    Component.onCompleted: root.syncArt()
}
