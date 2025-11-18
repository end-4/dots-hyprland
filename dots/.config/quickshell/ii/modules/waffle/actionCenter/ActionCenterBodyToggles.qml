pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.models.quickToggles
import qs.modules.common.functions
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter.toggles

Item {
    id: root

    property int currentPage: 0
    property alias columns: grid.columns
    property alias rows: grid.rows
    readonly property int itemsPerPage: columns * rows
    property list<string> toggles: Config.options.waffles.actionCenter.toggles
    property list<string> togglesInCurrentPage: toggles.slice(currentPage * itemsPerPage, (currentPage + 1) * itemsPerPage)

    property real padding: 22
    implicitHeight: grid.implicitHeight + padding * 2

    GridLayout {
        id: grid
        anchors {
            fill: parent
            margins: parent.padding
        }

        columns: 3
        rows: 2
        rowSpacing: 12
        columnSpacing: 12
        uniformCellHeights: true
        uniformCellWidths: true

        Repeater {
            model: ScriptModel {
                values: root.togglesInCurrentPage
            }
            delegate: ActionCenterTogglesDelegateChooser {}
        }
    }

    // TODO: pages indicator on the right
}
