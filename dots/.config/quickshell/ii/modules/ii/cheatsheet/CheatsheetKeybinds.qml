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
    property bool noMatches: false
    property real padding: 4
    implicitWidth: QsWindow?.window?.screen.width * 0.7 ?? 0
    implicitHeight: QsWindow?.window?.screen.height * 0.7 ?? 0

    onSearchQueryChanged: matchUpdateTimer.restart()

    Timer {
        id: matchUpdateTimer
        interval: 0
        onTriggered: {
            if (!root.searchQuery.trim()) {
                root.noMatches = false;
                return;
            }
            let any = false;
            for (let i = 0; i < flow.children.length; i++) {
                if (flow.children[i].visible) {
                    any = true;
                    break;
                }
            }
            root.noMatches = !any;
        }
    }

    StyledFlickable {
        id: flickable
        clip: true
        anchors.fill: parent
        anchors.margins: Appearance.rounding.small
        contentHeight: height
        contentWidth: flow.implicitWidth

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
    }

    StyledText {
        anchors.centerIn: parent
        visible: root.noMatches
        font.pixelSize: Appearance.font.pixelSize.large
        color: Appearance.colors.colSubtext
        text: Translation.tr("No matching keybinds")
    }
}
