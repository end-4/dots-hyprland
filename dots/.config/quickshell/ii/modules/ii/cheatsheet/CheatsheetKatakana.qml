import "katakana_table.js" as KTable
import QtQuick

Item {
    id: root
    readonly property var elements: KTable.elements
    property real spacing: 6
    implicitWidth: mainLayout.implicitWidth
    implicitHeight: mainLayout.implicitHeight

    Row {
        id: mainLayout
        anchors.centerIn: parent
        spacing: root.spacing

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
                        delegate: KatakanaTile {
                            required property var modelData
                            element: modelData
                        }
                    }
                }
            }
        }
    }
}
