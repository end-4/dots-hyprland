pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

BodyRectangle {
    id: root

    property string searchText: LauncherSearch.query

    ColumnLayout {
        anchors {
            fill: parent
            topMargin: 2
            leftMargin: 24
            rightMargin: 24
        }
        spacing: 12

        TagStrip {
            Layout.fillWidth: true
            Layout.fillHeight: false
        }

        SearchResults {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
