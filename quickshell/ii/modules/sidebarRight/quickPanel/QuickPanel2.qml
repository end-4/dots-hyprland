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
Item {
    id: root
    // Required specs
    property int columns: 4
    property int columnWidth: 90
    property int rowHeight: 70
    property int gap: 16


    Rectangle {
        anchors.fill : parent
        border.color : "pink"
        border.width : 0
        color : "transparent"
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
        ListElement { text: "wifi"; span: 2; row: -1; col: -1 }
        ListElement { text: "Bluetooth"; span: 2; row: -1; col: -1 }
        ListElement { text: "C"; span: 2; row: -1; col: -1 }
        ListElement { text: "D"; span: 2; row: -1; col: -1 }
        ListElement { text: "E"; span: 2; row: -1; col: -1 }
        ListElement { text: "F"; span: 2; row: -1; col: -1 }
        ListElement { text: "G"; span: 2; row: -1; col: -1 }
        ListElement { text: "H"; span: 2; row: -1; col: -1 }
        ListElement { text: "I"; span: 2; row: -1; col: -1 }
        ListElement { text: "J"; span: 2; row: -1; col: -1 }
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
        delegate: QuickToggle { // IMPORTANT: access roles directly (no 'model.' prefix)
            toggled: Network.active
            halfToggled: Network.wifiEnabled
            onClicked: Network.toggleWifi()
            altAction: () => {
                                   Network.enableWifi();
                                   Network.rescanWifi();
                                   root.showWifiDialog = true;
                               }
            buttonIcon: model.text
            x: col * (root.columnWidth + root.gap)
            y: row * (root.rowHeight + root.gap)
            baseWidth: (model.span * root.columnWidth) + ((model.span - 1) * root.gap)
            baseHeight: root.rowHeight


        }
    }
}
