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

    StyledPopup {
        hoverTarget: mouseArea
        contentComponent: Rectangle {
            id: datePopup
            readonly property real margin: 12
            implicitWidth: columnLayout.implicitWidth + margin * 2
            implicitHeight: columnLayout.implicitHeight + margin * 2
            color: Appearance.colors.colTooltip
            radius: Appearance.rounding.small
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
                        color: Appearance.colors.colOnTooltip
                        text: `${root.formattedDate} • ${root.formattedTime}`
                    }
                }

                // Uptime row
                RowLayout {
                    spacing: 5
                    Layout.fillWidth: true
                    MaterialSymbol { text: "timelapse"; color: Appearance.colors.colOnTooltip }
                    StyledText { text: Translation.tr("System uptime:"); color: Appearance.colors.colOnTooltip }
                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        color: Appearance.colors.colOnTooltip
                        text: root.formattedUptime
                    }
                }

                // Tasks
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 5
                        Layout.fillWidth: true
                        MaterialSymbol { text: "checklist"; color: Appearance.colors.colOnTooltip }
                        StyledText { text: Translation.tr("To Do:"); color: Appearance.colors.colOnTooltip }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        topPadding: 5
                        horizontalAlignment: Text.AlignLeft
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colOnTooltip
                        text: root.todosSection
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
