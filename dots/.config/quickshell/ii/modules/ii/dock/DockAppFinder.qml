pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root
    property var dockWindow
    property bool showing: false
    property real gapFromDock: 12
    property string searchText: ""
    property string _pendingSearchText: ""

    // ── Recent files (from KDE-style recently-used.xbel) ──
    property var recentFiles: []
    readonly property string recentFilePath: `${Directories.home}.local/share/recently-used.xbel`

    FileView {
        id: recentFilesView
        path: root.recentFilePath
        onTextChanged: root.parseRecentFiles(recentFilesView.text)
    }

    function decodeUrl(url) {
        try { return decodeURIComponent(url.replace("file://", "")); }
        catch (e) { return url.replace("file://", ""); }
    }

    function parseRecentFiles(xbelText) {
        if (!xbelText) { root.recentFiles = []; return; }
        const items = [];
        // <bookmark href="..."> ... <mime:mime-type type="..."/> (may span lines)
        const re = /href="(file:[^"]+)"[\s\S]*?mime:mime-type type="([^"]+)"/g;
        let m;
        while ((m = re.exec(xbelText)) !== null) {
            const href = m[1];
            const mime = m[2];
            if (mime.startsWith("inode/")) continue; // skip directories
            const path = root.decodeUrl(href);
            const name = path.split("/").pop() || path;
            items.push({ path: path, name: name, mime: mime });
            if (items.length >= 8) break;
        }
        root.recentFiles = items;
    }

    // Debounce search input so we don't run fuzzy search on every keystroke
    Timer {
        id: searchDebounce
        interval: 150
        repeat: false
        onTriggered: {
            root.searchText = root._pendingSearchText
        }
    }
    readonly property real dockHeight: root.dockWindow?.implicitHeight ?? 70

    screen: root.dockWindow?.screen
    color: "transparent"
    visible: root.showing || contentWrapper.opacity > 0
    exclusionMode: ExclusionMode.Ignore

    // Position: bottom of screen, above the dock
    anchors {
        bottom: true
        left: true
        right: true
    }
    margins {
        bottom: root.dockHeight + root.gapFromDock
    }

    WlrLayershell.namespace: "quickshell:appfinder"
    WlrLayershell.keyboardFocus: root.showing ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    implicitWidth: contentWrapper.implicitWidth
    implicitHeight: contentWrapper.implicitHeight

    // NOTE: no mask on purpose — the window spans the whole bottom edge and
    // the transparent area around the panel must receive clicks so that
    // outsideClickCatcher can dismiss the panel (see below).

    onShowingChanged: {
        if (!showing) {
            searchText = ""
            _pendingSearchText = ""
            input.text = ""
        }
    }

    // ── Dismiss: click outside the panel (window covers the whole screen
    // bottom edge, so catch presses on the transparent area around the panel).
    // A plain MouseArea at the window root; content inside the panel sits on
    // top (higher z) and consumes its own events, so only outside clicks land here.
    MouseArea {
        id: outsideClickCatcher
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: (event) => {
            const p = contentWrapper.mapFromItem(root, event.x, event.y);
            const inside = p.x >= 0 && p.x <= contentWrapper.width
                && p.y >= 0 && p.y <= contentWrapper.height;
            if (!inside) {
                root.showing = false;
                event.accepted = true;
            }
            // inside: don't accept — let the panel content handle the click
        }
    }

    // ── Animation: short slide + fade (panel is almost fully visible right
    // away; only a slight upward shift, avoiding the long "crawl from below"
    // feel that looked laggy).
    property real animSlide: showing ? 0 : 24
    property real animOpacity: showing ? 1.0 : 0.0

    Behavior on animSlide {
        NumberAnimation {
            duration: showing ? 180 : 140
            easing.type: Easing.BezierSpline
            easing.bezierCurve: showing
                ? Appearance.animationCurves.emphasizedDecel
                : Appearance.animationCurves.emphasizedAccel
        }
    }
    Behavior on animOpacity {
        NumberAnimation {
            duration: showing ? 120 : 90
            easing.type: Easing.BezierSpline
            easing.bezierCurve: showing
                ? Appearance.animationCurves.standardDecel
                : Appearance.animationCurves.standardAccel
        }
    }

    // ── Content ──
    Item {
        id: contentWrapper
        anchors.horizontalCenter: parent.horizontalCenter
        // y animated for slide-up; NO top anchor to avoid conflict
        y: root.animSlide
        opacity: root.animOpacity

        readonly property real pad: 12
        readonly property real gap: 8
        readonly property real sbHeight: 48
        readonly property int panelWidth: Config.options?.dock.appFinder.width ?? 640
        readonly property int panelHeight: Config.options?.dock.appFinder.height ?? 560

        implicitWidth: panelWidth
        implicitHeight: sbHeight + panelHeight + pad * 2 + gap

        StyledRectangularShadow { target: bg }

        Rectangle {
            id: bg
            anchors.fill: parent
            color: Appearance.m3colors.m3surfaceContainer
            radius: Appearance.rounding.large
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            ColumnLayout {
                anchors { fill: parent; margins: contentWrapper.pad }
                spacing: contentWrapper.gap

                // ── Search bar ──
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: contentWrapper.sbHeight
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    radius: Appearance.rounding.full

                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 8 }
                        spacing: 6

                        MaterialSymbol {
                            Layout.alignment: Qt.AlignVCenter
                            text: "search"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnSurfaceVariant
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            implicitHeight: input.implicitHeight

                            TextInput {
                                id: input
                                anchors.fill: parent
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.m3colors.m3onSurface
                                activeFocusOnPress: true
                                focus: root.showing
                                onTextChanged: {
                                    root._pendingSearchText = text
                                    searchDebounce.restart()
                                }
                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Escape) {
                                        root.showing = false
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Up
                                               || event.key === Qt.Key_Left || event.key === Qt.Key_Right
                                               || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        // Forward navigation keys to the grid (keyboard navigation)
                                        appGridLoader.item?.keyNavigate(event)
                                        event.accepted = true
                                    }
                                }
                            }

                            StyledText {
                                anchors.fill: parent
                                text: Translation.tr("Search apps...")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnSurfaceVariant
                                visible: input.text === "" && !input.activeFocus
                            }
                        }

                        RippleButton {
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 28; implicitHeight: 28
                            visible: input.text !== ""
                            buttonRadius: Appearance.rounding.full
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colLayer1Hover
                            colRipple: Appearance.colors.colLayer1Active
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "close"
                                iconSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnSurfaceVariant
                            }
                            onClicked: {
                                input.text = ""
                                root._pendingSearchText = ""
                                searchDebounce.restart()
                            }
                        }
                    }
                }

                // Grid area with fixed configured height; scrolls internally
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: contentWrapper.panelHeight

                    Loader {
                        id: appGridLoader
                        // Keep loaded permanently so opening the drawer is
                        // instant — the app list is built once, not on every open.
                        active: true
                        anchors.fill: parent
                        sourceComponent: appGridComponent
                    }

                    Component {
                        id: appGridComponent
                        DockAppFinderGrid {
                            anchors.fill: parent
                            searchText: root.searchText
                            onContextMenuRequested: (entry, itemPos, item) => {
                                // Map the clicked item's local coords into the menu overlay
                                const mapped = appFinderMenu.mapFromItem(item, itemPos.x, itemPos.y);
                                appFinderMenu.menuEntry = entry;
                                appFinderMenu.menuPosition = mapped;
                                appFinderMenu.menuOpen = true;
                            }
                        }
                    }
                }

                // ── Context menu (themed, animated) — in-panel overlay ──
                // Lives inside the panel (same window), so menuPosition from the
                // grid's mapToItem matches exactly; no cross-window coordinate issues.
                Item {
                    id: appFinderMenu
                    anchors.fill: parent
                    z: 100
                    property var menuEntry: null
                    property point menuPosition: Qt.point(0, 0)
                    property bool menuOpen: false

                    // Click anywhere else in the panel closes the menu.
                    // Only active while the menu is open, so it never swallows
                    // right-clicks meant for the grid icons below.
                    MouseArea {
                        anchors.fill: parent
                        enabled: appFinderMenu.menuOpen
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onPressed: appFinderMenu.menuOpen = false
                    }

                    ThemedContextMenu {
                        id: contextMenu
                        anchors.fill: parent
                        width: 200
                        open: appFinderMenu.menuOpen
                        menuPosition: appFinderMenu.menuPosition
                        onOpenChanged: {
                            if (!contextMenu.open)
                                appFinderMenu.menuOpen = false;
                        }
                        onItemClicked: appFinderMenu.menuOpen = false
                        // Static entries first, then the entry's custom actions
                        // (e.g. browser "open in incognito window")
                        model: {
                            const items = [
                                {
                                    icon: "content_copy",
                                    text: Translation.tr("Copy path"),
                                    onClicked: () => appFinderMenu.copyEntryPath(appFinderMenu.menuEntry)
                                },
                                {
                                    icon: "push_pin",
                                    text: TaskbarApps.isPinned(appFinderMenu.menuEntry?.id)
                                        ? Translation.tr("Unpin")
                                        : Translation.tr("Pin to dock"),
                                    onClicked: () => TaskbarApps.togglePin(appFinderMenu.menuEntry.id)
                                }
                            ];
                            // Custom desktop actions from the .desktop file (no icon)
                            for (const action of (appFinderMenu.menuEntry?.actions ?? [])) {
                                items.push({
                                    icon: "",
                                    text: action.name ?? "",
                                    onClicked: () => {
                                        if (!action.runInTerminal)
                                            action.execute();
                                        else
                                            Quickshell.execDetached(["bash", '-c', `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(action.command.join(' '))}'`]);
                                        appFinderMenu.menuOpen = false;
                                    }
                                });
                            }
                            // Recent files section (KDE-style)
                            if (root.recentFiles.length > 0) {
                                items.push({ icon: "separator", text: "" });
                                items.push({
                                    icon: "",
                                    text: Translation.tr("Recent files"),
                                    textBold: true,
                                    onClicked: () => {}
                                });
                                for (const rf of root.recentFiles) {
                                    items.push({
                                        icon: "",
                                        text: rf.name,
                                        onClicked: () => {
                                            Quickshell.execDetached(["xdg-open", rf.path]);
                                            appFinderMenu.menuOpen = false;
                                        }
                                    });
                                }
                            }
                            return items;
                        }
                    }

                    function copyEntryPath(entry) {
                        if (!entry) return;
                        const exec = (entry.exec || "").split(" ")[0] || "";
                        if (!exec) return;
                        Quickshell.clipboardText = exec;
                    }
                }

            }
        }
    }
}


