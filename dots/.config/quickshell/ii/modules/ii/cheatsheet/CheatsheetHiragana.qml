import "hiragana_table.js" as HTable  // Import the new JS file
import QtQuick

Item {
    id: root
    readonly property var elements: HTable.elements
    property real spacing: 6
    implicitWidth: mainLayout.implicitWidth
    implicitHeight: mainLayout.implicitHeight

    Row { // Changed from Column to Row to make it vertical-scroll friendly if needed, or keep Column
        id: mainLayout
        anchors.centerIn: parent
        spacing: root.spacing

        // We use a Row of Columns (Vertical writing style) OR Column of Rows (Standard table).
        // The data in JS is organized as Rows (A, K, S...), so we use Column layout.
        
        Column {
             spacing: root.spacing
             
             Repeater {
                model: root.elements
                
                delegate: Row {
                    id: tableRow
                    spacing: root.spacing
                    required property var modelData
                    
                    Repeater {
                        model: tableRow.modelData
                        delegate: HiraganaTile { // Use the new Tile component
                            required property var modelData
                            element: modelData
                        }
                    }
                }
            }
        }
    }
}

