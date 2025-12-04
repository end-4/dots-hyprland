pragma ComponentBehavior: Bound
import Qt.labs.synchronizer
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

WBarAttachedPanelContent {
    id: root

    property bool searching: false
    property string searchText: LauncherSearch.query

    contentItem: WPane {
        contentItem: WPanelPageColumn {
            SearchBar {
                focus: true
                Layout.fillWidth: true
                implicitWidth: 832 // TODO: Make sizes naturally inferred
                horizontalPadding: root.searching ? 24 : 32
                // verticalPadding: root.searching ? 32 : 16 // TODO: make this not nuke the panel
                Synchronizer on searching {
                    property alias target: root.searching
                }
                text: root.searchText
                onTextChanged: {
                    LauncherSearch.query = text;
                }
            }
            Item {
                implicitHeight: root.searching ? 736 : 736 // TODO: Make sizes naturally inferred
                Layout.fillWidth: true
                Loader {
                    id: pageContentLoader
                    anchors.fill: parent
                    sourceComponent: root.searching ? searchPageComp : startPageComp
                }
            }
        }
    }

    Component {
        id: searchPageComp
        SearchPageContent {}
    }

    Component {
        id: startPageComp
        StartPageContent {}
    }
}
