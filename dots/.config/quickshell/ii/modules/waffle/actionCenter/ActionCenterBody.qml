import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

Rectangle {
    id: root

    property int currentPage: 0
    property alias columns: grid.columns
    property alias rows: grid.rows
    readonly property int itemsPerPage: columns * rows
    property list<string> toggles: Config.options.waffles.actionCenter.toggles
    property list<string> togglesInCurrentPage: toggles.slice(currentPage * itemsPerPage, (currentPage + 1) * itemsPerPage)

    Layout.fillHeight: true
    Layout.fillWidth: true
    color: Looks.colors.bgPanelBody

    implicitWidth: 360
    implicitHeight: contentLayout.implicitHeight

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        spacing: 0

        Item {
            id: togglesContainer
            property real padding: 22
            Layout.fillWidth: true
            Layout.bottomMargin: -12
            implicitHeight: grid.implicitHeight + padding * 2

            GridLayout {
                id: grid
                anchors {
                    fill: parent
                    margins: parent.padding
                }

                columns: 3
                rows: 2
                rowSpacing: 12
                columnSpacing: 12
                uniformCellHeights: true
                uniformCellWidths: true

                Repeater {
                    model: ScriptModel {
                        values: root.togglesInCurrentPage
                    }
                    delegate: ActionCenterToggle {
                        required property var modelData
                        name: modelData
                    }
                }
            }

            // TODO: pages indicator on the right
        }

        Rectangle {
            implicitHeight: 1
            Layout.fillWidth: true
            color: Looks.colors.bg1Border
        }

        RowLayout {
            Layout.margins: 12
            Layout.topMargin: 18
            Layout.bottomMargin: 14
            spacing: 4

            WPanelIconButton {
                iconName: WIcons.volumeIcon
                onClicked: {
                    Audio.sink.audio.muted = !Audio.sink.audio.muted;
                }
            }
            WSlider {
                Layout.fillWidth: true
                value: Audio.sink.audio.volume
                onMoved: {
                    Audio.sink.audio.volume = value;
                }
            }
            WPanelIconButton {
                contentItem: Item {
                    anchors.centerIn: parent
                    Row {
                        anchors.centerIn: parent
                        spacing: -1
                        FluentIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 18
                            icon: "settings"
                        }
                        FluentIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 12
                            icon: "chevron-right"
                        }
                    }
                }
            }
        }
    }
}
