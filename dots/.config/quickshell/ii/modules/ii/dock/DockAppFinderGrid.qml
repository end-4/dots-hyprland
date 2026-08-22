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
import Quickshell.Widgets

Item {
    id: root
    property string searchText: ""
    property int columns: Config.options?.dock.appFinder.columns ?? 5
    property real spacing: 10
    // Cell width adapts to panel width so columns always fit evenly
    readonly property real cellWidth: Math.max(72, (root.width - (root.columns - 1) * root.spacing - 16) / root.columns)
    readonly property real cellHeight: Math.max(88, root.cellWidth * 1.2)

    // Context menu state (managed by DockAppFinder)
    property var contextMenuApp: null
    property point contextMenuPosition: Qt.point(0, 0)
    property bool contextMenuVisible: false
    property var propertiesDialogApp: null
    property bool propertiesDialogVisible: false

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

    implicitWidth: root.columns * (root.cellWidth + root.spacing) - root.spacing

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
            spacing: 12

            Repeater {
                model: root.groups

                ColumnLayout {
                    required property var modelData
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
                            // Height = number of rows * (cellHeight + spacing)
                            const rows = Math.ceil(modelData.apps.length / root.columns);
                            return Math.max(1, rows) * (root.cellHeight + root.spacing) - root.spacing;
                        }
                        cellWidth: root.cellWidth
                        cellHeight: root.cellHeight
                        interactive: false // Outer Flickable handles scrolling
                        boundsBehavior: Flickable.StopAtBounds
                        clip: false

                        model: modelData.apps

                        delegate: DockAppFinderItem {
                            id: itemDelegate
                            required property var modelData
                            width: catGrid.cellWidth
                            height: catGrid.cellHeight

                            entry: modelData
                            iconSize: Config.options?.dock.appFinder.iconSize ?? 40

                            // ── Right-click context menu ──
                            altAction: (event) => {
                                const globalPos = itemDelegate.mapToItem(root, event.x, event.y);
                                root.contextMenuPosition = globalPos;
                                root.contextMenuApp = modelData;
                                root.contextMenuVisible = true;
                                event.accepted = true;
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Context menu ──
    Loader {
        id: contextMenuLoader
        active: root.contextMenuVisible
        anchors.fill: parent

        sourceComponent: Item {
            anchors.fill: parent

            MouseArea {
                anchors.fill: parent
                onPressed: root.contextMenuVisible = false
            }

            StyledRectangularShadow {
                target: contextMenuRect
            }

            Rectangle {
                id: contextMenuRect
                x: Math.min(root.contextMenuPosition.x, parent.width - width - 10)
                y: Math.min(root.contextMenuPosition.y, parent.height - height - 10)
                width: 200
                height: contextMenuColumn.implicitHeight + 16
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                ColumnLayout {
                    id: contextMenuColumn
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    // Copy path
                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        buttonRadius: Appearance.rounding.small
                        colBackground: ColorUtils.transparentize(Appearance.colors.colLayer0)
                        colBackgroundHover: Appearance.colors.colLayer2
                        colRipple: Appearance.colors.colLayer2Active

                        onClicked: {
                            copyAppPath(root.contextMenuApp);
                            root.contextMenuVisible = false;
                        }

                        contentItem: RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            MaterialSymbol {
                                text: "content_copy"
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer0
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: Translation.tr("Copy path")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer0
                            }
                        }
                    }

                    // Pin / Unpin
                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        buttonRadius: Appearance.rounding.small
                        colBackground: ColorUtils.transparentize(Appearance.colors.colLayer0)
                        colBackgroundHover: Appearance.colors.colLayer2
                        colRipple: Appearance.colors.colLayer2Active

                        onClicked: {
                            TaskbarApps.togglePin(root.contextMenuApp.id);
                            root.contextMenuVisible = false;
                        }

                        contentItem: RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            MaterialSymbol {
                                text: "push_pin"
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer0
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: TaskbarApps.isPinned(root.contextMenuApp.id)
                                    ? Translation.tr("Unpin")
                                    : Translation.tr("Pin to dock")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer0
                            }
                        }
                    }

                    // Properties
                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        buttonRadius: Appearance.rounding.small
                        colBackground: ColorUtils.transparentize(Appearance.colors.colLayer0)
                        colBackgroundHover: Appearance.colors.colLayer2
                        colRipple: Appearance.colors.colLayer2Active

                        onClicked: {
                            root.propertiesDialogApp = root.contextMenuApp;
                            root.propertiesDialogVisible = true;
                            root.contextMenuVisible = false;
                        }

                        contentItem: RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            MaterialSymbol {
                                text: "info"
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer0
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: Translation.tr("Properties")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer0
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Properties dialog ──
    Loader {
        id: propertiesDialogLoader
        active: root.propertiesDialogVisible
        anchors.fill: parent

        sourceComponent: Item {
            anchors.fill: parent

            MouseArea {
                anchors.fill: parent
                onPressed: root.propertiesDialogVisible = false
            }

            StyledRectangularShadow {
                target: propertiesRect
            }

            Rectangle {
                id: propertiesRect
                anchors.centerIn: parent
                width: 320
                height: Math.min(400, parent.height - 40)
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        IconImage {
                            source: Quickshell.iconPath(root.propertiesDialogApp?.icon ?? "", "image-missing")
                            implicitSize: 40
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            StyledText {
                                text: root.propertiesDialogApp?.name ?? ""
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.bold: true
                                color: Appearance.colors.colOnLayer0
                                elide: Text.ElideRight
                            }
                            StyledText {
                                text: root.propertiesDialogApp?.id ?? ""
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                elide: Text.ElideRight
                            }
                        }
                        RippleButton {
                            implicitWidth: 28; implicitHeight: 28
                            buttonRadius: Appearance.rounding.full
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colLayer2
                            colRipple: Appearance.colors.colLayer2Active
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "close"
                                iconSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer0
                            }
                            onClicked: root.propertiesDialogVisible = false
                        }
                    }

                    Item { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Appearance.colors.colLayer0Border }

                    // Description
                    StyledText {
                        Layout.fillWidth: true
                        visible: root.propertiesDialogApp?.description
                        text: root.propertiesDialogApp?.description ?? ""
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer0
                        wrapMode: Text.WordWrap
                    }

                    // Exec
                    StyledText {
                        Layout.fillWidth: true
                        visible: root.propertiesDialogApp?.exec
                        text: Translation.tr("Exec: %1").arg(root.propertiesDialogApp?.exec ?? "")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.family: Appearance.font.family.monospace
                        color: Appearance.colors.colSubtext
                        wrapMode: Text.WrapAnywhere
                    }

                    // Categories
                    StyledText {
                        Layout.fillWidth: true
                        visible: root.propertiesDialogApp?.categories
                        text: Translation.tr("Categories: %1").arg((root.propertiesDialogApp?.categories ?? []).join(", "))
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }

    // ── Helper: copy executable path via `which` ──
    function getExecutablePath(app) {
        if (!app) return "";
        const exec = app.exec || "";
        const parts = exec.split(" ");
        return parts[0] || "";
    }

    Process {
        id: pathFinderProcess
        property var app: null
        property string execName: ""
        command: ["which", execName]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && stdout.length > 0) {
                Quickshell.clipboardText = stdout.trim();
            } else {
                Quickshell.clipboardText = execName;
            }
        }
    }

    function copyAppPath(app) {
        if (!app) return;
        const execName = getExecutablePath(app);
        if (!execName) {
            Quickshell.clipboardText = Translation.tr("Unknown executable");
            return;
        }
        pathFinderProcess.app = app;
        pathFinderProcess.execName = execName;
        pathFinderProcess.running = true;
    }
}
