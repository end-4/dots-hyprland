pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    implicitHeight: contentCol.implicitHeight + 16
    color: Appearance.colors.colLayer1

    readonly property var sortOptions: [
        { id: "relevance", label: Translation.tr("Relevance"),     icon: "auto_awesome" },
        { id: "name",      label: Translation.tr("Name"),          icon: "sort_by_alpha" },
        { id: "size",      label: Translation.tr("Size"),          icon: "straighten" },
        { id: "type",      label: Translation.tr("File type"),     icon: "category" },
        { id: "mtime",     label: Translation.tr("Date modified"), icon: "schedule" }
    ]

    readonly property var filterOptions: [
        { id: "all",     label: Translation.tr("All"),                     icon: "select_all" },
        { id: "dir",     label: Translation.tr("Folders"),                 icon: "folder" },
        { id: "file",    label: Translation.tr("Files"),                   icon: "description" },
        { id: "image",   label: Translation.tr("Images"),                  icon: "image" },
        { id: "video",   label: Translation.tr("Videos"),                  icon: "movie" },
        { id: "audio",   label: Translation.tr("Audio"),                   icon: "music_note" },
        { id: "doc",     label: Translation.tr("Documents"),               icon: "article" },
        { id: "archive", label: Translation.tr("Archives"),                icon: "folder_zip" },
        { id: "exec",    label: Translation.tr("Apps / Exe / AppImage"),   icon: "sports_esports" },
        { id: "code",    label: Translation.tr("Code / Config"),           icon: "code" }
    ]

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Appearance.colors.colOutlineVariant
    }

    ColumnLayout {
        id: contentCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 8

        StyledText {
            Layout.leftMargin: 4
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            text: FileSearch.sortMenuOpen
                ? Translation.tr("Sort (click again to toggle ↑/↓)")
                : Translation.tr("Filter by file type")
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6
            visible: FileSearch.sortMenuOpen

            Repeater {
                model: root.sortOptions
                delegate: RippleButton {
                    required property var modelData
                    readonly property bool active: FileSearch.sortBy === modelData.id
                    implicitWidth: sortRow.implicitWidth + 18
                    implicitHeight: 32
                    buttonRadius: Appearance.rounding.full
                    colBackground: active ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSurfaceContainerHigh
                    colBackgroundHover: active ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2Hover
                    onClicked: FileSearch.setSort(modelData.id)

                    contentItem: RowLayout {
                        id: sortRow
                        anchors.centerIn: parent
                        spacing: 6
                        MaterialSymbol {
                            text: modelData.icon
                            iconSize: 17
                            color: active ? Appearance.colors.colOnPrimaryContainer : Appearance.m3colors.m3onSurface
                        }
                        StyledText {
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: active ? Appearance.colors.colOnPrimaryContainer : Appearance.m3colors.m3onSurface
                            text: modelData.label
                        }
                        MaterialSymbol {
                            visible: active
                            text: FileSearch.sortOrder === "asc" ? "arrow_upward" : "arrow_downward"
                            iconSize: 17
                            color: Appearance.colors.colPrimary
                        }
                    }
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6
            visible: FileSearch.filterMenuOpen

            Repeater {
                model: root.filterOptions
                delegate: RippleButton {
                    required property var modelData
                    readonly property bool active: FileSearch.filterType === modelData.id
                    implicitWidth: filterRow.implicitWidth + 18
                    implicitHeight: 32
                    buttonRadius: Appearance.rounding.full
                    colBackground: active ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSurfaceContainerHigh
                    colBackgroundHover: active ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2Hover
                    onClicked: {
                        FileSearch.setFilter(modelData.id);
                        FileSearch.filterMenuOpen = false;
                    }

                    contentItem: RowLayout {
                        id: filterRow
                        anchors.centerIn: parent
                        spacing: 6
                        MaterialSymbol {
                            text: modelData.icon
                            iconSize: 17
                            color: active ? Appearance.colors.colOnPrimaryContainer : Appearance.m3colors.m3onSurface
                        }
                        StyledText {
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: active ? Appearance.colors.colOnPrimaryContainer : Appearance.m3colors.m3onSurface
                            text: modelData.label
                        }
                    }
                }
            }
        }
    }
}
