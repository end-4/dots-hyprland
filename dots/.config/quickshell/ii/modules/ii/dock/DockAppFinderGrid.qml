pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Item {
    id: root
    property string searchText: ""
    property real cellWidth: 90
    property real cellHeight: 90
    property int columns: Config.options?.dock.appFinder.columns ?? 5
    property int maxRows: Config.options?.dock.appFinder.maxRows ?? 5
    property real spacing: 6

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

    // Size: width uses max columns; height capped to maxRows
    implicitWidth: root.columns * (root.cellWidth + root.spacing) - root.spacing
    readonly property real maxPanelHeight: root.maxRows * (root.cellHeight + root.spacing) + 40 // 40px for headers
    implicitHeight: Math.min(columnLayout.implicitHeight, maxPanelHeight)

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true
        contentWidth: columnLayout.width
        contentHeight: columnLayout.implicitHeight
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            interactive: false
        }

        ColumnLayout {
            id: columnLayout
            width: flick.width
            spacing: 2

            Repeater {
                model: root.groups

                ColumnLayout {
                    required property var modelData
                    spacing: 2
                    Layout.fillWidth: true

                    // ── Category header ──
                    StyledText {
                        Layout.leftMargin: 4
                        text: modelData.name
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.bold: true
                        color: Appearance.colors.colPrimary
                    }

                    // ── Chunked rows, each centered ──
                    Repeater {
                        model: {
                            const apps = modelData.apps;
                            const rows = [];
                            for (let i = 0; i < apps.length; i += root.columns)
                                rows.push(apps.slice(i, i + root.columns));
                            return rows;
                        }

                        Item {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitWidth: row.implicitWidth
                            implicitHeight: row.implicitHeight

                            Row {
                                id: row
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: root.spacing

                                Repeater {
                                    model: modelData
                                    DockAppFinderItem {
                                        required property var modelData
                                        entry: modelData
                                        cellWidth: root.cellWidth
                                        cellHeight: root.cellHeight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
