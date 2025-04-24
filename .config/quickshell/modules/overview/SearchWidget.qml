import "root:/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item { // Wrapper
    id: root
    required property var panelWindow
    property string searchingText: ""
    property bool showResults: searchingText != ""
    property real searchBarHeight: searchBar.height + Appearance.sizes.elevationMargin * 2
    implicitWidth: searchWidgetContent.implicitWidth + Appearance.sizes.elevationMargin * 2
    implicitHeight: searchWidgetContent.implicitHeight + Appearance.sizes.elevationMargin * 2

    Rectangle { // Background
        id: searchWidgetContent
        anchors.centerIn: parent
        implicitWidth: columnLayout.implicitWidth
        implicitHeight: columnLayout.implicitHeight
        radius: Appearance.rounding.large
        color: Appearance.colors.colLayer0

        ColumnLayout {
            id: columnLayout
            anchors.centerIn: parent
            spacing: 0

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: searchWidgetContent.width
                    height: searchWidgetContent.width
                    radius: searchWidgetContent.radius
                }
            }

            RowLayout {
                id: searchBar
                spacing: 5
                KeyNavigation.down: appResults
                MaterialSymbol {
                    id: searchIcon
                    Layout.leftMargin: 15
                    font.pixelSize: Appearance.font.pixelSize.huge
                    color: Appearance.m3colors.m3onSurface
                    text: "search"
                }
                TextField { // Search box
                    id: searchInput

                    padding: 15
                    Layout.rightMargin: 15
                    color: activeFocus ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3onSurfaceVariant
                    selectedTextColor: Appearance.m3colors.m3onSurface
                    placeholderText: qsTr("Search")
                    placeholderTextColor: Appearance.m3colors.m3outline
                    focus: root.panelWindow.visible || GlobalStates.overviewOpen

                    implicitWidth: Appearance.sizes.searchWidth

                    onTextChanged: root.searchingText = text
                    Connections {
                        target: root
                        function onVisibleChanged() {
                            searchInput.selectAll()
                            root.searchingText = ""
                        }
                    }

                    background: Item {}

                    cursorDelegate: Rectangle {
                        width: 1
                        color: searchInput.activeFocus ? Appearance.m3colors.m3primary : "transparent"
                        radius: 1
                    }
                }
            }

            Rectangle { // Separator
                visible: root.showResults
                Layout.fillWidth: true
                height: 1
                color: Appearance.m3colors.m3outline
            }

            ListView { // App results
                id: appResults
                visible: root.showResults
                Layout.fillWidth: true
                implicitHeight: 600
                clip: true
                topMargin: 10
                bottomMargin: 10
                spacing: 0
                KeyNavigation.up: searchBar

                model: ScriptModel {
                    id: model;
                    values: DesktopEntries.applications.values
                        .filter((entry) => {
                            if (root.searchingText == "") return false
                            return entry.name.toLowerCase().includes(root.searchingText.toLowerCase())
                        })
                        .map((entry) => {
                            entry.clickActionName = "Launch";
                            return entry;
                        })
                }
                delegate: SearchItem {
                    desktopEntry: modelData
                    // itemName: modelData.name
                    // itemIcon: modelData.icon
                }
            }
            
        }
    }

    DropShadow {
        id: searchWidgetShadow
        anchors.fill: searchWidgetContent
        source: searchWidgetContent
        radius: Appearance.sizes.elevationMargin
        samples: radius * 2 + 1
        color: Appearance.colors.colShadow
        verticalOffset: 2
        horizontalOffset: 0
    }
}