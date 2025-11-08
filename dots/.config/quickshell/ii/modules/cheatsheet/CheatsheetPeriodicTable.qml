import "periodic_table.js" as PTable
import QtQuick

Item {
    id: root
    readonly property var elements: PTable.elements
    readonly property var series: PTable.series
    property real spacing: 6
    implicitWidth: mainLayout.implicitWidth
    implicitHeight: mainLayout.implicitHeight

    Column {
        id: mainLayout
        anchors.centerIn: parent
        spacing: root.spacing

        Repeater { // Main table rows
            model: root.elements
            
            delegate: Row { // Table cells
                id: tableRow
                spacing: root.spacing
                required property var modelData
                
                Repeater {
                    model: tableRow.modelData
                    delegate: ElementTile {
                        required property var modelData
                        element: modelData
                    }

                }
            }
            
        }

        Item {
            id: gap
            implicitHeight: 20
        }

        Repeater { // Main table rows
            model: root.series
            
            delegate: Row { // Table cells
                id: seriesTableRow
                spacing: root.spacing
                required property var modelData
                
                Repeater {
                    model: seriesTableRow.modelData
                    delegate: ElementTile {
                        required property var modelData
                        element: modelData
                    }

                }
            }
            
        }
    }
    
}