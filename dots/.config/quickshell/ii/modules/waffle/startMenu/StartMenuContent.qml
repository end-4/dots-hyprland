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
    property string searchText: ""

    contentItem: WPane {
        contentItem: WPanelPageColumn {
            SearchBar {
                focus: true
                Layout.fillWidth: true
                Synchronizer on searching {
                    property alias target: root.searching
                }
                Synchronizer on text {
                    property alias source: root.searchText
                }
            }
            Loader {
                id: pageContentLoader
                Layout.fillWidth: true
                source: root.searching ? "SearchPageContent.qml" : "StartPageContent.qml"
            }
        }
    }
    
}
