pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

RowLayout {
    id: root
    spacing: 4

    Connections {
        target: GlobalStates
        function onOverviewOpenChanged() {
            if (!GlobalStates.overviewOpen) {
                FileSearch.sortMenuOpen = false;
                FileSearch.filterMenuOpen = false;
            }
        }
    }

    IconToolbarButton {
        id: sortBtn
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        toggled: FileSearch.sortMenuOpen || FileSearch.sortBy !== "relevance"
        onClicked: {
            FileSearch.filterMenuOpen = false;
            FileSearch.sortMenuOpen = !FileSearch.sortMenuOpen;
        }
        text: FileSearch.sortOrder === "asc" && FileSearch.sortBy !== "relevance" ? "arrow_upward" : "swap_vert"
        StyledToolTip {
            text: Translation.tr("Sort (%1)").arg(FileSearch.sortOrder === "asc" ? Translation.tr("Ascending") : Translation.tr("Descending"))
        }
    }

    IconToolbarButton {
        id: filterBtn
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        toggled: FileSearch.filterMenuOpen || FileSearch.filterType !== "all"
        onClicked: {
            FileSearch.sortMenuOpen = false;
            FileSearch.filterMenuOpen = !FileSearch.filterMenuOpen;
        }
        text: "filter_list"
        StyledToolTip {
            text: Translation.tr("Filter")
        }
    }
}
