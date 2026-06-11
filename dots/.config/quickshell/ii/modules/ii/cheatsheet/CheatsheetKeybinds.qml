pragma ComponentBehavior: Bound

import "cheatsheet_search.js" as CheatsheetSearch
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    property string searchQuery: ""
    property real padding: 4
    implicitWidth: QsWindow?.window?.screen.width * 0.7 ?? 0
    implicitHeight: QsWindow?.window?.screen.height * 0.7 ?? 0

    readonly property bool hasResults: {
        if (root.searchQuery.trim().length === 0) return true;
        const query = root.searchQuery;
        return HyprlandKeybinds.keybinds.some(bind =>
            bind.description && CheatsheetSearch.matchesQuery(bind.description + " " + bind.key, query)
        );
    }

    StyledFlickable {
        id: flickable
        clip: true
        anchors.fill: parent
        anchors.margins: Appearance.rounding.small
        contentHeight: height
        contentWidth: flow.implicitWidth
        visible: root.hasResults

        Flow {
            id: flow
            height: flickable.height
            flow: Flow.TopToBottom
            spacing: 10
            Repeater {
                model: [...HyprlandKeybinds.keybindCategories, ""]
                delegate: CheatsheetKeybindsCategory {
                    required property var modelData
                    categoryName: modelData
                    searchQuery: root.searchQuery
                }
            }
        }
    }

    ScrollEdgeFade {
        target: flickable
        vertical: false
        color: Appearance.colors.colLayer0Base
        visible: flickable.visible
    }

    StyledText {
        anchors.centerIn: parent
        visible: root.searchQuery.trim().length > 0 && !root.hasResults
        font.pixelSize: Appearance.font.pixelSize.large
        color: Appearance.colors.colSubtext
        text: Translation.tr("No matching keybinds")
    }
}
