import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/file_utils.js" as FileUtils
import "periodic_table.js" as PTable
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Hyprland

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