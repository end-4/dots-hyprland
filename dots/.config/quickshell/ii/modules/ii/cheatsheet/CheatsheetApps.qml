pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

Item {
    id: root
    property real padding: 4
    implicitWidth: QsWindow?.window?.screen.width * 0.7 ?? 0
    implicitHeight: QsWindow?.window?.screen.height * 0.7 ?? 0

    signal appLaunched()

    property string searchQuery: ""

    readonly property var allApps: {
        const list = Array.from(DesktopEntries.applications.values);
        // Deduplicate by app id
        const deduped = list.filter((app, index, self) =>
            index === self.findIndex(t => t.id === app.id)
        );
        // Filter out empty entries
        const valid = deduped.filter(app => app && app.name && app.name.trim().length > 0);
        // Sort alphabetically by name
        valid.sort((a, b) => a.name.localeCompare(b.name));
        return valid;
    }

    readonly property var filteredApps: {
        const query = root.searchQuery.trim().toLowerCase();
        if (query.length === 0) {
            return root.allApps;
        }

        const fuzzyResults = AppSearch.fuzzyQuery(query);
        if (fuzzyResults && fuzzyResults.length > 0) {
            return fuzzyResults;
        }

        return root.allApps.filter(app =>
            (app.name && app.name.toLowerCase().includes(query)) ||
            (app.comment && app.comment.toLowerCase().includes(query)) ||
            (app.id && app.id.toLowerCase().includes(query))
        );
    }

    readonly property int gridColumns: Math.max(1, Math.floor(gridView.width / 130))

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.rounding.small
        spacing: 12

        // Top Search Bar & App Count
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                color: Appearance.colors.colLayer1
                radius: Appearance.rounding.full
                border.width: 1
                border.color: searchInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 10
                    spacing: 8

                    MaterialSymbol {
                        iconSize: 20
                        color: Appearance.colors.colSubtext
                        text: "search"
                    }

                    TextField {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        verticalAlignment: TextInput.AlignVCenter
                        placeholderText: Translation.tr("Search applications...")
                        placeholderTextColor: Appearance.colors.colSubtext
                        color: Appearance.colors.colOnLayer1
                        selectedTextColor: Appearance.colors.colOnSecondaryContainer
                        selectionColor: Appearance.colors.colSecondaryContainer
                        renderType: Text.NativeRendering
                        background: null
                        font {
                            family: Appearance.font.family.main
                            pixelSize: Appearance.font.pixelSize.normal
                        }

                        onTextChanged: {
                            root.searchQuery = text;
                            if (gridView.count > 0) {
                                gridView.currentIndex = 0;
                            }
                        }

                        onAccepted: {
                            if (root.filteredApps.length > 0) {
                                root.appLaunched();
                                root.filteredApps[0].execute();
                            }
                        }

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Escape) {
                                if (text.length > 0) {
                                    text = "";
                                    event.accepted = true;
                                }
                            } else if (event.key === Qt.Key_Down) {
                                if (root.filteredApps.length > 0) {
                                    gridView.forceActiveFocus();
                                    event.accepted = true;
                                }
                            }
                        }
                    }

                    RippleButton {
                        visible: searchInput.text.length > 0
                        implicitWidth: 26
                        implicitHeight: 26
                        buttonRadius: Appearance.rounding.full
                        colBackgroundHover: Appearance.colors.colLayer2Hover
                        onClicked: {
                            searchInput.text = "";
                            searchInput.forceActiveFocus();
                        }
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            iconSize: 18
                            color: Appearance.colors.colSubtext
                            text: "close"
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredHeight: 38
                Layout.preferredWidth: appCountText.implicitWidth + 24
                color: Appearance.colors.colLayer1
                radius: Appearance.rounding.full
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                StyledText {
                    id: appCountText
                    anchors.centerIn: parent
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    text: Translation.tr("%1 apps").arg(root.filteredApps.length)
                }
            }
        }

        // Apps Grid
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            GridView {
                id: gridView
                anchors.fill: parent
                cellWidth: Math.floor(width / root.gridColumns)
                cellHeight: 120
                interactive: true
                clip: true
                keyNavigationWraps: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: StyledScrollBar {}

                model: root.filteredApps

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (root.filteredApps.length > gridView.currentIndex && gridView.currentIndex >= 0) {
                            root.appLaunched();
                            root.filteredApps[gridView.currentIndex].execute();
                            event.accepted = true;
                        }
                    } else if (event.key === Qt.Key_Up && gridView.currentIndex < root.gridColumns) {
                        searchInput.forceActiveFocus();
                        event.accepted = true;
                    }
                }

                delegate: Item {
                    id: appDelegate
                    required property var modelData
                    required property int index
                    width: gridView.cellWidth
                    height: gridView.cellHeight

                    RippleButton {
                        id: appButton
                        anchors.fill: parent
                        anchors.margins: 4
                        buttonRadius: Appearance.rounding.normal
                        colBackground: (hovered || (gridView.currentIndex === appDelegate.index && gridView.activeFocus))
                            ? Appearance.colors.colLayer1Hover
                            : "transparent"
                        colRipple: Appearance.colors.colLayer1Active

                        contentItem: ColumnLayout {
                            anchors.centerIn: parent
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 6

                            IconImage {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 48
                                source: Quickshell.iconPath(appDelegate.modelData?.icon || "application-x-executable", "application-x-executable")
                            }

                            StyledText {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignHCenter
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: appDelegate.modelData?.name ?? ""
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.Wrap
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer0
                            }
                        }

                        StyledToolTip {
                            text: (appDelegate.modelData?.comment && appDelegate.modelData.comment.length > 0)
                                ? `${appDelegate.modelData.name}\n${appDelegate.modelData.comment}`
                                : (appDelegate.modelData?.name ?? "")
                        }

                        onClicked: {
                            root.appLaunched();
                            appDelegate.modelData.execute();
                        }
                    }
                }
            }

            ScrollEdgeFade {
                target: gridView
                vertical: true
                color: Appearance.colors.colLayer0Base
            }

            PagePlaceholder {
                anchors.centerIn: parent
                shown: root.filteredApps.length === 0
                icon: "search_off"
                title: Translation.tr("No applications found")
                description: Translation.tr("Try a different search term")
            }
        }
    }
}
