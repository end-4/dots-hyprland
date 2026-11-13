pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

Item {
    id: root
    property string searchText: ""
    property int columns: Config.options?.dock.appFinder.columns ?? 5
    // GridView cellWidth includes spacing, so divide panel width evenly
    // to get exactly `columns` columns (no extra blank column).
    readonly property real cellWidth: Math.max(1, Math.floor(root.width / root.columns))
    readonly property real cellHeight: Math.max(1, Math.floor(root.cellWidth * 1.2))

    // ── Keyboard navigation state ──
    property int currentIndex: 0
    readonly property var flatApps: {
        const out = [];
        for (const g of root.groups)
            for (const app of g.apps)
                out.push(app);
        return out;
    }
    function moveSelection(delta) {
        if (root.flatApps.length === 0) return;
        root.currentIndex = Math.max(0, Math.min(root.flatApps.length - 1, root.currentIndex + delta));
        root.ensureVisible();
    }
    function moveSelectionRow(delta) {
        root.moveSelection(delta * root.columns);
    }
    function activateCurrent() {
        const app = root.flatApps[root.currentIndex];
        if (app) app.execute();
    }

    // Scroll the flickable so the currently selected item is visible
    function ensureVisible() {
        const target = root.groups.find(g => g.apps.includes(root.flatApps[root.currentIndex]));
        if (!target) return;
        const groupIdx = root.groups.indexOf(target);
        // Approximate: y = sum of previous groups' heights + current row offset
        let y = 0;
        for (let i = 0; i < groupIdx; i++) {
            const g = root.groups[i];
            y += 24 /* header+spacing */ + Math.ceil(g.apps.length / root.columns) * root.cellHeight;
        }
        const inGroup = target.apps.indexOf(root.flatApps[root.currentIndex]);
        const row = Math.floor(inGroup / root.columns);
        y += 20 /* header */ + row * root.cellHeight;
        flick.contentY = Math.max(0, Math.min(y - 20, flick.contentHeight - flick.height));
    }

    // Called by the search bar to forward navigation keys
    function keyNavigate(event) {
        switch (event.key) {
        case Qt.Key_Left:
            root.moveSelection(-1); return true;
        case Qt.Key_Right:
            root.moveSelection(1); return true;
        case Qt.Key_Up:
            root.moveSelectionRow(-1); return true;
        case Qt.Key_Down:
            root.moveSelectionRow(1); return true;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            root.activateCurrent(); return true;
        }
        return false;
    }

    Keys.onPressed: event => {
        if (root.keyNavigate(event))
            event.accepted = true;
    }
    onSearchTextChanged: root.currentIndex = 0

    // Context menu (themed, animated) — hosted by AppFinder's overlay
    signal contextMenuRequested(var entry, point itemPos, var item)

    readonly property var catNames: ({
        "AudioVideo":  Translation.tr("Multimedia"),
        "Development": Translation.tr("Development"),
        "Education":   Translation.tr("Education"),
        "Game":        Translation.tr("Games"),
        "Graphics":    Translation.tr("Graphics"),
        "Network":     Translation.tr("Internet"),
        "Office":      Translation.tr("Office"),
        "Science":     Translation.tr("Science"),
        "Settings":    Translation.tr("Settings"),
        "System":      Translation.tr("System"),
        "Utility":     Translation.tr("Utilities"),
        "__other__":   Translation.tr("Other")
    })

    readonly property var catOrder: [
        "AudioVideo", "Development", "Education", "Game",
        "Graphics", "Network", "Office", "Science",
        "Settings", "System", "Utility"
    ]

    function getCat(entry) {
        if (!entry || !entry.categories) return "__other__";
        for (let i = 0; i < root.catOrder.length; i++)
            if (entry.categories.includes(root.catOrder[i])) return root.catOrder[i];
        return "__other__";
    }

    // Build sorted, deduplicated app list
    property var allApps: {
        const apps = [];
        for (const entry of DesktopEntries.applications.values)
            apps.push(entry);
        const seen = {};
        const deduped = apps.filter(a => {
            const id = a.id || a.name;
            if (seen[id]) return false;
            seen[id] = true;
            return true;
        });
        deduped.sort((a, b) => {
            const ai = root.catOrder.indexOf(root.getCat(a));
            const bi = root.catOrder.indexOf(root.getCat(b));
            const ra = ai === -1 ? 999 : ai;
            const rb = bi === -1 ? 999 : bi;
            if (ra !== rb) return ra - rb;
            return (a.name || "").localeCompare(b.name || "", "en", { sensitivity: "base" });
        });
        return deduped;
    }

    readonly property var filtered: {
        if (root.searchText === "")
            return root.allApps;
        return AppSearch.fuzzyQuery(root.searchText);
    }

    // Group filtered apps by category
    readonly property var groups: {
        const map = {};
        for (const app of root.filtered) {
            const cat = root.getCat(app);
            if (!map[cat]) map[cat] = [];
            map[cat].push(app);
        }
        // Build ordered array
        const result = [];
        for (const cat of root.catOrder) {
            if (map[cat]) result.push({ name: root.catNames[cat] || cat, apps: map[cat] });
        }
        if (map["__other__"]) result.push({ name: root.catNames["__other__"], apps: map["__other__"] });
        return result.filter(g => g.apps.length > 0);
    }

    implicitWidth: root.columns * root.cellWidth

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true
        contentWidth: columnLayout.width
        contentHeight: columnLayout.implicitHeight
        // interactive=true restores built-in wheel scrolling. To keep clicks
        // working, delegates rely on RippleButton's MouseArea which accepts
        // presses before the Flickable can steal them (verified).
        interactive: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            interactive: false
        }

        ColumnLayout {
            id: columnLayout
            width: flick.width
            spacing: 12

            Repeater {
                model: root.groups

                ColumnLayout {
                    required property var modelData
                    required property int index
                    spacing: 6
                    Layout.fillWidth: true

                    // ── Category header ──
                    StyledText {
                        Layout.leftMargin: 4
                        text: modelData.name
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.bold: true
                        color: Appearance.colors.colPrimary
                    }

                    // ── GridView per category (grid-style, like ApplicationDrawer) ──
                    GridView {
                        id: catGrid
                        Layout.fillWidth: true
                        Layout.preferredHeight: {
                            // Height = number of rows * cellHeight
                            const rows = Math.ceil(modelData.apps.length / root.columns);
                            return Math.max(1, rows) * root.cellHeight;
                        }
                        cellWidth: root.cellWidth
                        cellHeight: root.cellHeight
                        interactive: false // Outer Flickable handles scrolling
                        boundsBehavior: Flickable.StopAtBounds
                        clip: false

                        model: modelData.apps

                        // Flat index of the first app in this category
                        readonly property int flatStart: {
                            let n = 0;
                            for (let i = 0; i < index; i++)
                                n += root.groups[i].apps.length;
                            return n;
                        }

                        delegate: DockAppFinderItem {
                            id: itemDelegate
                            required property var modelData
                            required property int index
                            width: catGrid.cellWidth
                            height: catGrid.cellHeight

                            entry: modelData
                            selected: root.currentIndex === catGrid.flatStart + index

                            // ── Right-click context menu (overlay hosted by AppFinder) ──
                            altAction: (event) => {
                                // Pass item-local coords; AppFinder maps them into the menu overlay
                                root.contextMenuRequested(modelData, Qt.point(event.x, event.y), itemDelegate);
                                event.accepted = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
