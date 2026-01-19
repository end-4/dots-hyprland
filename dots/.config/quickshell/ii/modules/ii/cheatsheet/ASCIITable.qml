import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    // Predefined ASCII table data (codes 32-126), arranged in 16 columns to make it more horizontal
    readonly property var asciiTable: [
        [
            { code: 32, char: "SPC", type: "char" },
            { code: 33, char: "!", type: "char" },
            { code: 34, char: "\"", type: "char" },
            { code: 35, char: "#", type: "char" },
            { code: 36, char: "$", type: "char" },
            { code: 37, char: "%", type: "char" },
            { code: 38, char: "&", type: "char" },
            { code: 39, char: "'", type: "char" },
            { code: 40, char: "(", type: "char" },
            { code: 41, char: ")", type: "char" },
            { code: 42, char: "*", type: "char" },
            { code: 43, char: "+", type: "char" },
            { code: 44, char: ",", type: "char" },
            { code: 45, char: "-", type: "char" },
            { code: 46, char: ".", type: "char" },
            { code: 47, char: "/", type: "char" }
        ],
        [
            { code: 48, char: "0", type: "char" },
            { code: 49, char: "1", type: "char" },
            { code: 50, char: "2", type: "char" },
            { code: 51, char: "3", type: "char" },
            { code: 52, char: "4", type: "char" },
            { code: 53, char: "5", type: "char" },
            { code: 54, char: "6", type: "char" },
            { code: 55, char: "7", type: "char" },
            { code: 56, char: "8", type: "char" },
            { code: 57, char: "9", type: "char" },
            { code: 58, char: ":", type: "char" },
            { code: 59, char: ";", type: "char" },
            { code: 60, char: "<", type: "char" },
            { code: 61, char: "=", type: "char" },
            { code: 62, char: ">", type: "char" },
            { code: 63, char: "?", type: "char" }
        ],
        [
            { code: 64, char: "@", type: "char" },
            { code: 65, char: "A", type: "char" },
            { code: 66, char: "B", type: "char" },
            { code: 67, char: "C", type: "char" },
            { code: 68, char: "D", type: "char" },
            { code: 69, char: "E", type: "char" },
            { code: 70, char: "F", type: "char" },
            { code: 71, char: "G", type: "char" },
            { code: 72, char: "H", type: "char" },
            { code: 73, char: "I", type: "char" },
            { code: 74, char: "J", type: "char" },
            { code: 75, char: "K", type: "char" },
            { code: 76, char: "L", type: "char" },
            { code: 77, char: "M", type: "char" },
            { code: 78, char: "N", type: "char" },
            { code: 79, char: "O", type: "char" }
        ],
        [
            { code: 80, char: "P", type: "char" },
            { code: 81, char: "Q", type: "char" },
            { code: 82, char: "R", type: "char" },
            { code: 83, char: "S", type: "char" },
            { code: 84, char: "T", type: "char" },
            { code: 85, char: "U", type: "char" },
            { code: 86, char: "V", type: "char" },
            { code: 87, char: "W", type: "char" },
            { code: 88, char: "X", type: "char" },
            { code: 89, char: "Y", type: "char" },
            { code: 90, char: "Z", type: "char" },
            { code: 91, char: "[", type: "char" },
            { code: 92, char: "\\", type: "char" },
            { code: 93, char: "]", type: "char" },
            { code: 94, char: "^", type: "char" },
            { code: 95, char: "_", type: "char" }
        ],
        [
            { code: 96, char: "`", type: "char" },
            { code: 97, char: "a", type: "char" },
            { code: 98, char: "b", type: "char" },
            { code: 99, char: "c", type: "char" },
            { code: 100, char: "d", type: "char" },
            { code: 101, char: "e", type: "char" },
            { code: 102, char: "f", type: "char" },
            { code: 103, char: "g", type: "char" },
            { code: 104, char: "h", type: "char" },
            { code: 105, char: "i", type: "char" },
            { code: 106, char: "j", type: "char" },
            { code: 107, char: "k", type: "char" },
            { code: 108, char: "l", type: "char" },
            { code: 109, char: "m", type: "char" },
            { code: 110, char: "n", type: "char" },
            { code: 111, char: "o", type: "char" }
        ],
        [
            { code: 112, char: "p", type: "char" },
            { code: 113, char: "q", type: "char" },
            { code: 114, char: "r", type: "char" },
            { code: 115, char: "s", type: "char" },
            { code: 116, char: "t", type: "char" },
            { code: 117, char: "u", type: "char" },
            { code: 118, char: "v", type: "char" },
            { code: 119, char: "w", type: "char" },
            { code: 120, char: "x", type: "char" },
            { code: 121, char: "y", type: "char" },
            { code: 122, char: "z", type: "char" },
            { code: 123, char: "{", type: "char" },
            { code: 124, char: "|", type: "char" },
            { code: 125, char: "}", type: "char" },
            { code: 126, char: "~", type: "char" },
            { code: undefined, char: "", type: "empty" }
        ]
    ]

    property real spacing: 5
    property real titleSpacing: 7
    property real tileSize: 35  // Inicializa com valor padrão
    implicitWidth: columnLayout.implicitWidth
    implicitHeight: columnLayout.implicitHeight

    // Atualiza o tamanho do tile quando o componente é exibido
    onWidthChanged: {
        if (width > 0) {
            // Considera 16 colunas + espaçamentos
            var availableWidth = width - (15 * spacing); // espaço entre 16 colunas
            var calculatedSize = Math.max(30, Math.min(50, availableWidth / 16));
            tileSize = calculatedSize;
        }
    }

    // Garante que o tamanho seja atualizado quando o componente for completo
    Component.onCompleted: {
        // Tenta encontrar as dimensões do painel pai para calcular melhor o tamanho dos tiles
        var panel = findParentWithProperty(this, "implicitWidth");
        if (panel && panel.implicitWidth > 0) {
            var availableWidth = panel.implicitWidth - (15 * spacing); // espaço entre 16 colunas
            var calculatedSize = Math.max(30, Math.min(50, availableWidth / 16));
            tileSize = calculatedSize;
        } else if (width > 0) {
            // Fallback para o próprio tamanho
            var availableWidth = width - (15 * spacing); // espaço entre 16 colunas
            var calculatedSize = Math.max(30, Math.min(50, availableWidth / 16));
            tileSize = calculatedSize;
        }
    }

    // Função auxiliar para encontrar o pai com uma propriedade específica
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