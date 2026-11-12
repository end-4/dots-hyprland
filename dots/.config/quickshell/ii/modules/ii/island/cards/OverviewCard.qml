import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.island

// Clicking the main island: recent notifications and glance items that have an
// action (e.g. updates). Audio sources live in the DJ island.
ColumnLayout {
    id: root
    signal done()
    spacing: 10
    width: 352

    readonly property var recent: Notifications.list.slice(-3).reverse()
    // Priority order, but graph tiles last: they span both columns, so the pairs above stay even.
    readonly property var tiles: Object.values(IslandState.glances).sort((a, b) => root.hasGraph(a) - root.hasGraph(b) || (b.priority ?? 50) - (a.priority ?? 50))

    function hasGraph(t) {
        return (t.graph ?? []).length > 1 ? 1 : 0;
    }
    readonly property int plainCount: tiles.filter(t => !root.hasGraph(t)).length

    // Idle dashboard: every glance item at once (clickable when it has an action).
    GridLayout {
        Layout.fillWidth: true
        visible: root.tiles.length > 0
        columns: 2
        rowSpacing: 6
        columnSpacing: 6
        Repeater {
            model: root.tiles
            Rectangle {
                id: tile
                required property var modelData
                required property int index
                readonly property bool clickable: (modelData.command ?? []).length > 0
                readonly property color tint: (modelData.color ?? "") !== "" ? modelData.color : Appearance.colors.colPrimary
                readonly property var graph: modelData.graph ?? []
                Layout.fillWidth: true
                // Graph tiles, and an odd last plain tile, take the full row (no empty cell).
                Layout.columnSpan: root.hasGraph(modelData) || (index === root.plainCount - 1 && root.plainCount % 2 === 1) ? 2 : 1
                Layout.preferredWidth: 1
                implicitHeight: 40
                radius: 14
                color: tileArea.containsMouse && clickable ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 7
                    MaterialSymbol {
                        text: tile.modelData.icon ?? "info"
                        iconSize: 18
                        fill: 1
                        color: tile.tint
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: tile.modelData.text ?? ""
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnLayer2
                    }
                    // Sparkline: filled area under a line, newest value on the right.
                    Canvas {
                        id: spark
                        visible: root.hasGraph(tile.modelData)
                        implicitWidth: 130
                        implicitHeight: 22
                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            const g = tile.graph;
                            if (g.length < 2)
                                return;
                            const step = width / (g.length - 1);
                            const yOf = v => height - 1 - (height - 2) * Math.max(0, Math.min(1, v));
                            ctx.beginPath();
                            ctx.moveTo(0, yOf(g[0]));
                            for (let i = 1; i < g.length; i++)
                                ctx.lineTo(i * step, yOf(g[i]));
                            ctx.lineWidth = 1.5;
                            ctx.strokeStyle = tile.tint;
                            ctx.stroke();
                            ctx.lineTo(width, height);
                            ctx.lineTo(0, height);
                            ctx.closePath();
                            ctx.fillStyle = Qt.rgba(tile.tint.r, tile.tint.g, tile.tint.b, 0.25);
                            ctx.fill();
                        }
                        Connections {
                            target: tile
                            function onGraphChanged() {
                                spark.requestPaint();
                            }
                        }
                    }
                }
                MouseArea {
                    id: tileArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: tile.clickable
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(tile.modelData.command);
                        root.done();
                    }
                }
            }
        }
    }

    // Notifications
    RowLayout {
        Layout.fillWidth: true
        visible: Notifications.list.length > 0
        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Notifications · %1").arg(Notifications.list.length)
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.DemiBold
            color: Appearance.colors.colSubtext
        }
        IslandChip {
            text: Translation.tr("Clear")
            onClicked: Notifications.discardAllNotifications()
        }
    }
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        visible: Notifications.list.length === 0
        spacing: 6
        MaterialSymbol {
            text: "notifications_none"
            iconSize: 16
            color: Appearance.colors.colSubtext
        }
        StyledText {
            text: Translation.tr("All caught up")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
        }
    }
    Repeater {
        model: root.recent
        Rectangle {
            id: row
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 14
            color: area.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 10
                NotificationAppIcon {
                    implicitWidth: 32
                    implicitHeight: 32
                    appIcon: row.modelData.appIcon ?? ""
                    image: row.modelData.image ?? ""
                    summary: row.modelData.summary ?? ""
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    StyledText {
                        Layout.fillWidth: true
                        text: (row.modelData.appName ? row.modelData.appName + " · " : "") + (row.modelData.summary ?? "")
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnLayer2
                    }
                    StyledText {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: (row.modelData.body ?? "").replace(/<[^>]*>/g, "").replace(/\n/g, " ")
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSubtext
                    }
                }
                MaterialSymbol {
                    id: closeIcon
                    text: "close"
                    iconSize: 16
                    color: closeHit.containsMouse ? Appearance.colors.colOnLayer2 : Appearance.colors.colSubtext
                    Item {
                        id: closeHit
                        anchors.fill: parent
                        anchors.margins: -8
                        readonly property bool containsMouse: area.containsMouse && contains(mapFromItem(area, area.mouseX, area.mouseY))
                    }
                }
            }
            // One area on top for the whole row (it used to only hover-highlight). The × is
            // hit-tested by position: dismiss only; anywhere else: default action, then gone.
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    const id = row.modelData.notificationId;
                    if (closeHit.contains(mapToItem(closeHit, mouse.x, mouse.y)))
                        Notifications.discardNotification(id);
                    else
                        IslandState.activateNotification(id, "notif-" + id);
                }
            }
        }
    }
}
