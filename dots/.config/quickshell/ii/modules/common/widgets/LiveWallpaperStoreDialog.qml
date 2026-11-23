import QtQuick
import QtMultimedia
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Popup {
    id: storePopup

    property string targetMonitor: ""
    property var items: []
    property bool loading: false
    property string downloadingId: ""
    property string previewingId: ""
    property int currentPage: 1
    property string searchQuery: ""
    property bool historyMode: false

    // Our own paging: sources are merged into one stream (allItems), shown 20 per page. More is fetched from the
    // sites only when the user gets close to the end of what is loaded.
    readonly property int pageSize: 20
    property var allItems: []
    property int sitePage: 0
    property bool exhausted: false
    property bool fetching: false
    property int pendingPage: 0
    readonly property int loadedPages: Math.max(1, Math.ceil(allItems.length / pageSize))
    readonly property int knownPages: exhausted ? loadedPages : loadedPages + 1
    readonly property var pageNumbers: {
        const cur = currentPage, total = Math.max(1, knownPages);
        let end = Math.min(total, Math.max(1, cur - 4) + 9);
        let start = Math.max(1, end - 9);
        const out = [];
        if (start > 1) {
            out.push(1);
            if (start > 2) out.push(-1);
        }
        for (let i = start; i <= end; i++) out.push(i);
        return out;
    }

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    anchors.centerIn: Overlay.overlay
    width: Math.min(860, (Overlay.overlay?.width ?? 940) - 40)
    height: Math.min(680, (Overlay.overlay?.height ?? 740) - 40)
    padding: 0

    // A new search / category: start over from the first page of every source
    function loadStore(page, query) {
        storePopup.historyMode = false;
        storePopup.previewingId = "";
        storePopup.searchQuery = query;
        storePopup.allItems = [];
        storePopup.items = [];
        storePopup.sitePage = 0;
        storePopup.exhausted = false;
        storePopup.fetching = false;
        storePopup.currentPage = 1;
        storePopup.pendingPage = 1;
        storePopup.loading = true;
        fetchNext();
    }

    function fetchNext() {
        if (storePopup.fetching || storePopup.exhausted) return;
        storePopup.fetching = true;
        storePopup.sitePage += 1;
        listProc.command = [
            "python3",
            Quickshell.shellPath("scripts/colors/live-wallpaper-store.py"),
            "list",
            String(storePopup.sitePage),
            storePopup.searchQuery
        ];
        listProc.running = false;
        listProc.running = true;
    }

    function showPage(n) {
        storePopup.previewingId = "";
        storePopup.currentPage = n;
        storePopup.items = storePopup.allItems.slice((n - 1) * storePopup.pageSize, n * storePopup.pageSize);
        // Near the end of what is loaded: fetch the next chunk in the background
        if (!storePopup.exhausted && !storePopup.fetching && n >= storePopup.loadedPages - 1)
            fetchNext();
    }

    function goToPage(n) {
        if (n < 1 || storePopup.loading) return;
        if (n <= storePopup.loadedPages && (n * storePopup.pageSize <= storePopup.allItems.length || storePopup.exhausted)) {
            showPage(n);
        } else if (!storePopup.exhausted) {
            storePopup.pendingPage = n;
            storePopup.loading = true;
            fetchNext();
        }
    }

    function onChunk(parsed) {
        const seen = {};
        for (const it of storePopup.allItems) seen[it.id] = true;
        const fresh = (parsed.items ?? []).filter(it => !seen[it.id]);
        if (fresh.length > 0) storePopup.allItems = storePopup.allItems.concat(fresh);
        storePopup.fetching = false;
        if ((parsed.items ?? []).length === 0 || storePopup.sitePage >= (parsed.pages ?? 1))
            storePopup.exhausted = true;
        if (storePopup.pendingPage > 0) {
            const want = storePopup.pendingPage;
            if (storePopup.allItems.length >= want * storePopup.pageSize || storePopup.exhausted) {
                storePopup.pendingPage = 0;
                storePopup.loading = false;
                showPage(Math.min(want, storePopup.loadedPages));
            } else {
                fetchNext();   // not enough yet (duplicates were dropped): keep loading
            }
        } else {
            storePopup.loading = false;
        }
    }

    function loadHistory() {
        storePopup.historyMode = true;
        storePopup.previewingId = "";
        storePopup.loading = true;
        storePopup.searchQuery = "__history__";
        listProc.command = [
            "python3",
            Quickshell.shellPath("scripts/colors/live-wallpaper-store.py"),
            "history"
        ];
        listProc.running = false;
        listProc.running = true;
    }

    onClosed: storePopup.previewingId = ""

    onOpened: {
        if (items.length === 0) {
            loadStore(1, "");
        }
    }

    Process {
        id: listProc
        stdout: StdioCollector {
            onStreamFinished: {
                let parsed = null;
                try {
                    parsed = JSON.parse(text.trim() || "[]");
                } catch (e) {
                    parsed = null;
                }
                if (storePopup.historyMode) {
                    storePopup.loading = false;
                    storePopup.previewingId = "";
                    storePopup.items = Array.isArray(parsed) ? parsed : [];
                    return;
                }
                if (parsed === null || Array.isArray(parsed)) {
                    // the request failed: stop here so the user sees "No wallpapers found" instead of a spinner
                    storePopup.fetching = false;
                    storePopup.exhausted = true;
                    storePopup.pendingPage = 0;
                    storePopup.loading = false;
                    if (storePopup.allItems.length === 0) storePopup.items = [];
                    return;
                }
                storePopup.onChunk(parsed);
            }
        }
    }

    Process {
        id: downloadProc
        onExited: (code, status) => {
            storePopup.downloadingId = "";
            if (code === 0) {
                storePopup.close();
            }
        }
    }

    background: Rectangle {
        radius: Appearance.rounding.large
        color: Appearance.m3colors.m3surfaceContainer
        border.width: 1
        border.color: Appearance.colors.colOutlineVariant
    }

    Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.58)
    }

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            MaterialSymbol {
                text: "storefront"
                iconSize: 22
                color: Appearance.colors.colPrimary
            }
            StyledText {
                Layout.fillWidth: true
                text: storePopup.targetMonitor !== ""
                    ? `${Translation.tr("Live Wallpaper Store")} · ${storePopup.targetMonitor}`
                    : Translation.tr("Live Wallpaper Store")
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.m3colors.m3onSurface
            }
            Rectangle {
                width: 34
                height: 34
                radius: 17
                color: Appearance.colors.colLayer2
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "close"
                    iconSize: 18
                    color: Appearance.m3colors.m3onSurface
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: storePopup.close()
                }
            }
        }

        // Search + category chips
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: Appearance.rounding.full
                color: Appearance.colors.colLayer2
                border.width: 1
                border.color: searchField.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8
                    MaterialSymbol {
                        text: "search"
                        iconSize: 18
                        color: Appearance.colors.colSubtext
                    }
                    TextInput {
                        id: searchField
                        Layout.fillWidth: true
                        color: Appearance.m3colors.m3onSurface
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.family: Appearance.font.family.main
                        clip: true
                        onAccepted: storePopup.loadStore(1, text)
                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: Translation.tr("Search live wallpapers (e.g. anime, cyberpunk, space)...")
                            color: Appearance.colors.colSubtext
                            font: parent.font
                            visible: parent.text === "" && !parent.activeFocus
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: searchBtnTxt.implicitWidth + 28
                Layout.preferredHeight: 38
                radius: 19
                color: Appearance.colors.colPrimary
                StyledText {
                    id: searchBtnTxt
                    anchors.centerIn: parent
                    text: Translation.tr("Search")
                    color: Appearance.m3colors.m3onPrimary
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: storePopup.loadStore(1, searchField.text)
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: ["", "__history__", "anime", "cyberpunk", "sci-fi", "fantasy", "nature", "abstract", "space", "gaming", "car", "pixel", "minimalist", "dark"]
                delegate: Rectangle {
                    required property string modelData
                    readonly property bool activeChip: modelData === "__history__"
                        ? storePopup.historyMode
                        : (!storePopup.historyMode && storePopup.searchQuery.toLowerCase() === modelData)
                    implicitWidth: chipTxt.implicitWidth + 20
                    implicitHeight: 28
                    radius: Appearance.rounding.full
                    color: activeChip ? Appearance.colors.colPrimary : Appearance.colors.colLayer2

                    StyledText {
                        id: chipTxt
                        anchors.centerIn: parent
                        text: modelData === "" ? Translation.tr("Featured")
                            : modelData === "__history__" ? Translation.tr("History")
                            : modelData.charAt(0).toUpperCase() + modelData.slice(1)
                        color: activeChip ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurface
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData === "__history__") {
                                storePopup.loadHistory();
                            } else {
                                searchField.text = modelData;
                                storePopup.loadStore(1, modelData);
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            CircularProgress {
                anchors.centerIn: parent
                visible: storePopup.loading
                implicitSize: 38
                lineWidth: 3
                value: 0.72
                enableAnimation: false
                colPrimary: Appearance.colors.colPrimary
                colSecondary: Qt.rgba(1, 1, 1, 0.14)
                RotationAnimator on rotation {
                    running: storePopup.loading && storePopup.visible
                    from: 0; to: 360
                    duration: 900
                    loops: Animation.Infinite
                }
            }

            StyledText {
                anchors.centerIn: parent
                visible: !storePopup.loading && storePopup.items.length === 0
                text: Translation.tr("No wallpapers found")
                color: Appearance.colors.colSubtext
            }

            GridView {
                id: storeGrid
                anchors.fill: parent
                visible: !storePopup.loading && storePopup.items.length > 0
                clip: true
                cellWidth: Math.floor(width / 2)
                cellHeight: 196
                model: storePopup.items

                delegate: Item {
                    required property var modelData
                    width: storeGrid.cellWidth
                    height: storeGrid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 6
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colLayer2
                        border.width: 1
                        border.color: Appearance.colors.colOutlineVariant

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                readonly property bool isPreviewing: storePopup.previewingId === modelData.id
                                readonly property bool previewReady: isPreviewing && (cardVidLoader.item?.ready ?? false)

                                Image {
                                    anchors.fill: parent
                                    visible: !parent.previewReady
                                    source: modelData.thumb
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    layer.enabled: true
                                    layer.effect: OpacityMask {
                                        maskSource: Rectangle {
                                            width: storeGrid.cellWidth - 28
                                            height: storeGrid.cellHeight - 62
                                            radius: Appearance.rounding.small
                                        }
                                    }
                                }

                                Component.onDestruction: cardVidLoader?.item?.shutdown()

                                Loader {
                                    id: cardVidLoader
                                    anchors.fill: parent
                                    // Two-phase teardown (see Background.qml): stop + detach the player,
                                    // then destroy the item after a short delay.
                                    readonly property bool wanted: parent.isPreviewing && storePopup.visible
                                    property bool gate: false
                                    active: gate
                                    visible: parent.previewReady
                                    onWantedChanged: {
                                        if (wanted) {
                                            cardGateTimer.stop();
                                            gate = true;
                                            if (item) item.resume();
                                        } else {
                                            if (item) item.shutdown();
                                            cardGateTimer.restart();
                                        }
                                    }
                                    Timer {
                                        id: cardGateTimer
                                        interval: 300
                                        onTriggered: cardVidLoader.gate = cardVidLoader.wanted
                                    }
                                    sourceComponent: Item {
                                        id: cardRoot
                                        anchors.fill: parent
                                        property bool shut: false
                                        function shutdown() { shut = true; cardPrevPlayer.stop(); }
                                        function resume() { shut = false; cardPrevPlayer.play(); }
                                        readonly property bool ready: !shut && cardPrevPlayer.hasVideo
                                            && cardPrevPlayer.mediaStatus !== MediaPlayer.LoadingMedia
                                            && cardPrevPlayer.mediaStatus !== MediaPlayer.NoMedia
                                        MediaPlayer {
                                            id: cardPrevPlayer
                                            source: cardRoot.shut ? "" : modelData.previewMp4
                                            loops: MediaPlayer.Infinite
                                            audioOutput: AudioOutput { muted: true }
                                            videoOutput: cardRoot.shut ? null : cardPrevOut
                                            Component.onCompleted: if (!cardRoot.shut) play()
                                            // Network stall / bad stream: drop the preview instead of spinning forever
                                            onErrorOccurred: (error, errorString) => {
                                                console.warn("[LiveStore] preview error:", errorString);
                                                if (storePopup.previewingId === modelData.id) storePopup.previewingId = "";
                                            }
                                        }
                                        Timer {
                                            running: !cardRoot.shut && !cardRoot.ready
                                            interval: 15000
                                            onTriggered: if (storePopup.previewingId === modelData.id) storePopup.previewingId = ""
                                        }
                                        VideoOutput {
                                            id: cardPrevOut
                                            anchors.fill: parent
                                            fillMode: VideoOutput.PreserveAspectCrop
                                        }
                                    }
                                }

                                // Loading spinner over thumbnail while preview video buffers
                                Rectangle {
                                    id: previewLoadingOverlay
                                    anchors.fill: parent
                                    visible: parent.isPreviewing && !parent.previewReady
                                    radius: Appearance.rounding.small
                                    color: Qt.rgba(0, 0, 0, 0.38)
                                    CircularProgress {
                                        anchors.centerIn: parent
                                        implicitSize: 32
                                        lineWidth: 3
                                        value: 0.72
                                        enableAnimation: false
                                        colPrimary: Appearance.colors.colPrimary
                                        colSecondary: Qt.rgba(1, 1, 1, 0.2)
                                        RotationAnimator on rotation {
                                            running: previewLoadingOverlay?.visible ?? false
                                            from: 0; to: 360
                                            duration: 850
                                            loops: Animation.Infinite
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.margins: 6
                                    radius: Appearance.rounding.full
                                    color: Qt.rgba(0, 0, 0, 0.68)
                                    implicitWidth: resBadgeTxt.implicitWidth + 14
                                    implicitHeight: 20
                                    StyledText {
                                        id: resBadgeTxt
                                        anchors.centerIn: parent
                                        text: modelData.res ? modelData.res.replace("x", "×") : (modelData.localPath ? "LOCAL" : "MP4")
                                        color: "#ffffff"
                                        font.pixelSize: 10
                                        font.weight: Font.Medium
                                    }
                                }

                                // Where the wallpaper comes from
                                Rectangle {
                                    visible: !!modelData.sourceName
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.margins: 6
                                    radius: Appearance.rounding.full
                                    color: Qt.rgba(0, 0, 0, 0.68)
                                    implicitWidth: srcBadgeTxt.implicitWidth + 14
                                    implicitHeight: 20
                                    StyledText {
                                        id: srcBadgeTxt
                                        anchors.centerIn: parent
                                        text: modelData.sourceName ?? ""
                                        color: "#ffffff"
                                        font.pixelSize: 10
                                        font.weight: Font.Medium
                                    }
                                }

                                // Top-right preview play/stop button
                                Rectangle {
                                    visible: (modelData.previewMp4 ?? "") !== ""
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 6
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: parent.isPreviewing ? Appearance.colors.colPrimary : Qt.rgba(0, 0, 0, 0.68)

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: parent.parent.isPreviewing ? "stop" : "play_arrow"
                                        iconSize: 18
                                        color: parent.parent.isPreviewing ? Appearance.m3colors.m3onPrimary : "#ffffff"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            storePopup.previewingId = (storePopup.previewingId === modelData.id) ? "" : modelData.id;
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                StyledText {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: modelData.title
                                    color: Appearance.m3colors.m3onSurface
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                }
                                Rectangle {
                                    id: applyBtn
                                    readonly property bool isBusy: storePopup.downloadingId === modelData.id
                                    implicitWidth: Math.max(66, applyTxt.implicitWidth + 24)
                                    implicitHeight: 28
                                    Layout.minimumWidth: implicitWidth
                                    Layout.preferredWidth: implicitWidth
                                    Layout.preferredHeight: 28
                                    radius: 14
                                    color: storePopup.downloadingId === "" ? Appearance.colors.colPrimary : Appearance.colors.colLayer1
                                    opacity: (storePopup.downloadingId === "" || applyBtn.isBusy || modelData.browseOnly) ? 1.0 : 0.55

                                    StyledText {
                                        id: applyTxt
                                        z: 2
                                        anchors.centerIn: parent
                                        text: modelData.browseOnly ? Translation.tr("Open page") : (applyBtn.isBusy ? Translation.tr("Downloading...") : Translation.tr("Apply"))
                                        color: Appearance.m3colors.m3onPrimary
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: storePopup.downloadingId === "" || modelData.browseOnly
                                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: {
                                            if (modelData.browseOnly) {
                                                // These sites do not allow automated downloads: open the page and download there
                                                Qt.openUrlExternally(modelData.pageUrl);
                                                return;
                                            }
                                            storePopup.downloadingId = modelData.id;
                                            const mon = storePopup.targetMonitor;
                                            if (modelData.localPath) {
                                                downloadProc.command = [
                                                    "python3",
                                                    Quickshell.shellPath("scripts/colors/live-wallpaper-store.py"),
                                                    "apply-local",
                                                    modelData.localPath,
                                                    mon
                                                ];
                                            } else {
                                                downloadProc.command = [
                                                    "python3",
                                                    Quickshell.shellPath("scripts/colors/live-wallpaper-store.py"),
                                                    "download",
                                                    modelData.id,
                                                    modelData.slug,
                                                    mon
                                                ];
                                            }
                                            downloadProc.running = false;
                                            downloadProc.running = true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Pagination: arrows and page numbers, e.g.  <  1 2 3 4 5 6 7 8 9 10  >  (shifts along as you go further)
        RowLayout {
            visible: !storePopup.historyMode && (storePopup.items.length > 0 || storePopup.loading)
            Layout.fillWidth: true
            spacing: 4
            Item { Layout.fillWidth: true }

            Rectangle {
                readonly property bool canClick: storePopup.currentPage > 1 && !storePopup.loading
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: arrowLeftArea.containsMouse && canClick ? Appearance.colors.colLayer2 : "transparent"
                opacity: canClick ? 1.0 : 0.4
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "chevron_left"
                    iconSize: 22
                    color: Appearance.m3colors.m3onSurface
                }
                MouseArea {
                    id: arrowLeftArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: parent.canClick
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: storePopup.goToPage(storePopup.currentPage - 1)
                }
            }

            Repeater {
                model: storePopup.pageNumbers
                delegate: Rectangle {
                    required property int modelData
                    readonly property bool isCurrent: modelData === storePopup.currentPage
                    Layout.preferredWidth: Math.max(32, pageTxt.implicitWidth + 16)
                    Layout.preferredHeight: 32
                    radius: 16
                    color: isCurrent ? Appearance.colors.colPrimary : (pageArea.containsMouse && modelData > 0 ? Appearance.colors.colLayer2 : "transparent")
                    StyledText {
                        id: pageTxt
                        anchors.centerIn: parent
                        text: modelData > 0 ? String(modelData) : "…"
                        color: parent.isCurrent ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurface
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: parent.isCurrent ? Font.DemiBold : Font.Normal
                    }
                    MouseArea {
                        id: pageArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: modelData > 0 && !parent.isCurrent && !storePopup.loading
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: storePopup.goToPage(modelData)
                    }
                }
            }

            Rectangle {
                readonly property bool canClick: storePopup.currentPage < storePopup.knownPages && !storePopup.loading
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: arrowRightArea.containsMouse && canClick ? Appearance.colors.colLayer2 : "transparent"
                opacity: canClick ? 1.0 : 0.4
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "chevron_right"
                    iconSize: 22
                    color: Appearance.m3colors.m3onSurface
                }
                MouseArea {
                    id: arrowRightArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: parent.canClick
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: storePopup.goToPage(storePopup.currentPage + 1)
                }
            }
            Item { Layout.fillWidth: true }
        }
    }
}
