import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool showDate: Config.options.bar.verbose
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: 32

    // Helper function to get upcoming todos
    function getUpcomingTodos() {
        const unfinishedTodos = Todo.list.filter(function(item) { return !item.done; })
        if (unfinishedTodos.length === 0) {
            return Translation.tr("No pending tasks")
        }
        
        // Limit to first 5 todos to keep popup manageable
        const limitedTodos = unfinishedTodos.slice(0, 5)
        let todoText = limitedTodos.map(function(item, index) {
            return `${index + 1}. ${item.content}`
        }).join('\n')
        
        if (unfinishedTodos.length > 5) {
            todoText += `\n${Translation.tr("... and %1 more").arg(unfinishedTodos.length - 5)}`
        }
        
        return todoText
    }

    // Popup Data
    property string formattedDate: Qt.locale().toString(DateTime.clock.date, "dddd, MMMM dd, yyyy")
    property string formattedTime: DateTime.time
    property string formattedUptime: DateTime.uptime
    property string todosSection: getUpcomingTodos()

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    LazyLoader {
        id: popupLoader
        active: mouseArea.containsMouse

        component: PanelWindow {
            id: popupWindow
            visible: true
            implicitWidth: datePopup.implicitWidth
            implicitHeight: datePopup.implicitHeight
            color: "transparent"
            exclusiveZone: 0

            anchors.top: true
            anchors.left: true

            margins {
                left: root.mapToGlobal(Qt.point(
                    (root.width - datePopup.implicitWidth) / 2,
                    0
                )).x
                top: root.mapToGlobal(Qt.point(0, root.height)).y - 30 
            }

            mask: Region {
                item: datePopup
            }
            
            Rectangle {
                id: datePopup
                readonly property real margin: 12
                implicitWidth: columnLayout.implicitWidth + margin * 2
                implicitHeight: columnLayout.implicitHeight + margin * 2
                color: Appearance.colors.colLayer0
                radius: Appearance.rounding.small
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                clip: true

                ColumnLayout {
                    id: columnLayout
                    anchors.centerIn: parent
                    spacing: 8

                    // Date + Time row
                    RowLayout {
                        spacing: 5
                        Layout.fillWidth: true
                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignLeft
                            color: Appearance.colors.colOnLayer1
                            text: `${root.formattedDate} • ${root.formattedTime}`
                        }
                    }

                    // Uptime row
                    RowLayout {
                        spacing: 5
                        Layout.fillWidth: true
                        MaterialSymbol { text: "timelapse"; color: Appearance.m3colors.m3onSecondaryContainer }
                        StyledText { text: Translation.tr("Uptime:"); color: Appearance.colors.colOnLayer1 }
                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight
                            color: Appearance.colors.colOnLayer1
                            text: root.formattedUptime
                        }
                    }

                    // Upcoming tasks row
                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true

                        RowLayout {
                            spacing: 5
                            Layout.fillWidth: true
                            MaterialSymbol { text: "checklist"; color: Appearance.m3colors.m3onSecondaryContainer }
                            StyledText { text: Translation.tr("Upcoming Tasks:"); color: Appearance.colors.colOnLayer1 }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            topPadding: 5
                            horizontalAlignment: Text.AlignLeft
                            wrapMode: Text.Wrap
                            color: Appearance.colors.colOnLayer1
                            text: root.todosSection
                        }
                    }
                }
            }

        }
    }

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            text: DateTime.time
        }

        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: "•"
        }

        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: DateTime.date
        }

    }

}
