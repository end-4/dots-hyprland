pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

GridLayout {
    id: root

    property list<var> desktopEntries: []

    columnSpacing: 0
    rowSpacing: 0

    uniformCellHeights: true
    uniformCellWidths: true

    Repeater {
        model: root.desktopEntries
        delegate: StartAppButton {
            id: pinnedAppButton
            required property var modelData
            desktopEntry: modelData
            onClicked: {
                GlobalStates.searchOpen = false;
                desktopEntry.execute();
            }
        }
    }
}
