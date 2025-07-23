import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import "periodic_table.js" as PTable
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    readonly property var elements: PTable.elements
    readonly property var series: PTable.series
    property real spacing: 6
    implicitWidth: mainLayout.implicitWidth
    implicitHeight: mainLayout.implicitHeight

    ColumnLayout {
        id: mainLayout
        spacing: root.spacing

        Repeater { // Main table rows
            model: root.elements
            
            delegate: RowLayout { // Table cells
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
            
            delegate: RowLayout { // Table cells
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