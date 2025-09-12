import QtQuick 2.15
import QtQuick.Controls 2.15
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions
import "../"
import qs
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "./toggles"

Item {
    id: root
    // Required specs
    property int columns: 4
    property int rowHeight: 65
    property int gap: 16
    property int columnWidth: 90

    Rectangle {
        anchors.fill: parent
        border.color: "pink"
        border.width: 0
        color: "transparent"
    }

    // Computed height based on rows used
    property int rowCount: 0

    width: columns * columnWidth + (columns - 1) * gap
    height: rowCount * rowHeight + rowCount * gap
    implicitHeight: rowCount * rowHeight + rowCount * gap

    // Declare roles up-front so setProperty works
    ListModel {
        id: items
        // span can be 1 or 2; row/col initialized to -1

        // ListElement { name: "GameModeToggle"; span: 1; row: -1; col: -1 }

        Component.onCompleted: {

            if (Config?.options?.quickToggle?.toggles.length) {
                Config.options.quickToggle.toggles.forEach(toggle => {
                    items.append({
                        name: toggle.name || "",
                        span: toggle.span || 1,
                        row: -1,
                        col: -1,
                    });
                });

            }
        }
    }

    function pack() {
        var occupancy = [];
        function ensureRow(r) {
            while (occupancy.length <= r) {
                var row = [];
                for (var c = 0; c < columns; ++c) row.push(false);
                occupancy.push(row);
            }
        }
        function fitsAt(r, c, span) {
            if (c + span > columns) return false;
            for (var k = 0; k < span; ++k)
                if (occupancy[r][c + k]) return false;
            return true;
        }
        function occupy(r, c, span) {
            for (var k = 0; k < span; ++k) occupancy[r][c + k] = true;
        }

        // clear previous placement
        for (var i = 0; i < items.count; ++i) {
            items.setProperty(i, "row", -1);
            items.setProperty(i, "col", -1);
        }

        for (var idx = 0; idx < items.count; ++idx) {
            var spanVal = Math.max(1, Math.min(2, items.get(idx).span));
            var placed = false;

            // try to backfill earlier rows first
            for (var r = 0; r < occupancy.length && !placed; ++r) {
                for (var c = 0; c < columns && !placed; ++c) {
                    if (fitsAt(r, c, spanVal)) {
                        occupy(r, c, spanVal);
                        items.setProperty(idx, "row", r);
                        items.setProperty(idx, "col", c);
                        placed = true;
                    }
                }
            }

            if (!placed) {
                var newRow = occupancy.length;
                ensureRow(newRow);
                for (var c2 = 0; c2 < columns && !placed; ++c2) {
                    if (fitsAt(newRow, c2, spanVal)) {
                        occupy(newRow, c2, spanVal);
                        items.setProperty(idx, "row", newRow);
                        items.setProperty(idx, "col", c2);
                        placed = true;
                    }
                }
            }
        }

        rowCount = Math.max(occupancy.length, 1);
    }

    Component.onCompleted: pack()
    Connections {
        target: items
        function onCountChanged() { pack() }
    }

    Repeater {
        model: items
        delegate: Rectangle {

            x: col * (root.columnWidth + root.gap)
                        y: row * (root.rowHeight + root.gap)
                        width: (span * root.columnWidth) + ((span - 1) * root.gap)
                        height: root.rowHeight
                        color: "transparent"
            Loader {
            // Load the specific QML file based on the text property
            source: "./toggles/" + name + ".qml"

            anchors.fill: parent
            // Pass properties to the loaded component
            onLoaded: {
                if (item) {
                    if (item.hasOwnProperty("sizeType")) {
                        item.sizeType = model.span;
                    }



                }
            }
        } }
    }
}
