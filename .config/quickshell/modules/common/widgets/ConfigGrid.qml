import QtQuick
import QtQuick.Layouts

GridLayout {
    property bool uniform: false

    rowSpacing: 10
    columnSpacing: 10

    uniformCellHeights: uniform
    uniformCellWidths: uniform
}
