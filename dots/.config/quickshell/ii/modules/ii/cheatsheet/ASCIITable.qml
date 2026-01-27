import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    // Predefined ASCII table data (codes 32-127), arranged in 16 columns to make it more horizontal
    readonly property var asciiTable: [
        [
            { code: 32, char: "SPC" },
            { code: 33, char: "!" },
            { code: 34, char: "\"" },
            { code: 35, char: "#" },
            { code: 36, char: "$" },
            { code: 37, char: "%" },
            { code: 38, char: "&" },
            { code: 39, char: "'" },
            { code: 40, char: "(" },
            { code: 41, char: ")" },
            { code: 42, char: "*" },
            { code: 43, char: "+" },
            { code: 44, char: "," },
            { code: 45, char: "-" },
            { code: 46, char: "." },
            { code: 47, char: "/" }
        ],
        [
            { code: 48, char: "0" },
            { code: 49, char: "1" },
            { code: 50, char: "2" },
            { code: 51, char: "3" },
            { code: 52, char: "4" },
            { code: 53, char: "5" },
            { code: 54, char: "6" },
            { code: 55, char: "7" },
            { code: 56, char: "8" },
            { code: 57, char: "9" },
            { code: 58, char: ":" },
            { code: 59, char: ";" },
            { code: 60, char: "<" },
            { code: 61, char: "=" },
            { code: 62, char: ">" },
            { code: 63, char: "?" }
        ],
        [
            { code: 64, char: "@" },
            { code: 65, char: "A" },
            { code: 66, char: "B" },
            { code: 67, char: "C" },
            { code: 68, char: "D" },
            { code: 69, char: "E" },
            { code: 70, char: "F" },
            { code: 71, char: "G" },
            { code: 72, char: "H" },
            { code: 73, char: "I" },
            { code: 74, char: "J" },
            { code: 75, char: "K" },
            { code: 76, char: "L" },
            { code: 77, char: "M" },
            { code: 78, char: "N" },
            { code: 79, char: "O" }
        ],
        [
            { code: 80, char: "P" },
            { code: 81, char: "Q" },
            { code: 82, char: "R" },
            { code: 83, char: "S" },
            { code: 84, char: "T" },
            { code: 85, char: "U" },
            { code: 86, char: "V" },
            { code: 87, char: "W" },
            { code: 88, char: "X" },
            { code: 89, char: "Y" },
            { code: 90, char: "Z" },
            { code: 91, char: "[" },
            { code: 92, char: "\\" },
            { code: 93, char: "]" },
            { code: 94, char: "^" },
            { code: 95, char: "_" }
        ],
        [
            { code: 96, char: "`" },
            { code: 97, char: "a" },
            { code: 98, char: "b" },
            { code: 99, char: "c" },
            { code: 100, char: "d" },
            { code: 101, char: "e" },
            { code: 102, char: "f" },
            { code: 103, char: "g" },
            { code: 104, char: "h" },
            { code: 105, char: "i" },
            { code: 106, char: "j" },
            { code: 107, char: "k" },
            { code: 108, char: "l" },
            { code: 109, char: "m" },
            { code: 110, char: "n" },
            { code: 111, char: "o" }
        ],
        [
            { code: 112, char: "p" },
            { code: 113, char: "q" },
            { code: 114, char: "r" },
            { code: 115, char: "s" },
            { code: 116, char: "t" },
            { code: 117, char: "u" },
            { code: 118, char: "v" },
            { code: 119, char: "w" },
            { code: 120, char: "x" },
            { code: 121, char: "y" },
            { code: 122, char: "z" },
            { code: 123, char: "{" },
            { code: 124, char: "|" },
            { code: 125, char: "}" },
            { code: 126, char: "~" },
            { code: 127, char: "DEL" }
        ]
    ]

    property real spacing: 5
    property real tileSize: 0
    implicitWidth: columnLayout.implicitWidth
    implicitHeight: columnLayout.implicitHeight

    onWidthChanged: {
        if (width > 0) {
             var availableWidth = panel.implicitWidth - (15 * spacing);
            var calculatedSize = Math.max(30, availableWidth / 16);
            tileSize = calculatedSize;
        }
    }

    Component.onCompleted: {
        var panel = findParentWithProperty(this, "implicitWidth");
        if (panel && panel.implicitWidth > 0) {
            var availableWidth = panel.implicitWidth - (15 * spacing);
            var calculatedSize = Math.max(30, availableWidth / 16);
            tileSize = calculatedSize;
        } else if (width > 0) {
            var availableWidth = width - (15 * spacing);
            var calculatedSize = Math.max(30, availableWidth / 16);
            tileSize = calculatedSize;
        }
    }

    function findParentWithProperty(item, prop) {
        var parent = item.parent;
        while (parent) {
            if (parent.hasOwnProperty(prop) || parent[prop] !== undefined) {
                return parent;
            }
            parent = parent.parent;
        }
        return null;
    }

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: root.spacing


        Column {
            Layout.alignment: Qt.AlignHCenter
            spacing: root.spacing

            Repeater { // Main table rows
                model: root.asciiTable

                delegate: Row { // Table cells
                    id: tableRow
                    spacing: root.spacing
                    required property var modelData

                    Repeater {
                        model: tableRow.modelData
                        delegate: ASCIITile {
                            required property var modelData
                            asciiInfo: modelData
                            tileDim: root.tileSize
                        }
                    }
                }
            }
        }
    }
}
