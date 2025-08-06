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
            return "No pending tasks"
        }
        
        // Limit to first 5 todos to keep popup manageable
        const limitedTodos = unfinishedTodos.slice(0, 5)
        let todoText = limitedTodos.map(function(item, index) {
            return `${index + 1}. ${item.content}`
        }).join('\n')
        
        if (unfinishedTodos.length > 5) {
            todoText += `\n... and ${unfinishedTodos.length - 5} more`
        }
        
        return todoText
    }

    // Generate popup content with date and upcoming todos
    property string dateDetails: {
        const todosSection = getUpcomingTodos()
        return `${Qt.locale().toString(DateTime.clock.date, "dddd, MMMM dd, yyyy")} • ${DateTime.time}
Uptime: ${DateTime.uptime}

📋 Upcoming Tasks:
${todosSection}`
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    LazyLoader {
        id: popupLoader
        active: mouseArea.containsMouse

        component: PopupWindow {
            id: popupWindow
            visible: true
            implicitWidth: datePopup.implicitWidth
            implicitHeight: datePopup.implicitHeight
            anchor.item: root
            anchor.edges: Edges.Top
            anchor.rect.x: (root.implicitWidth - popupWindow.implicitWidth) / 2
            anchor.rect.y: Config.options.bar.bottom ? 
                (-datePopup.implicitHeight - 15) :
                (root.implicitHeight + 15)
            color: "transparent"
            
            Rectangle {
                id: datePopup
                readonly property real margin: 12
                implicitWidth: popupText.implicitWidth + margin * 2
                implicitHeight: popupText.implicitHeight + margin * 2
                color: Appearance.colors.colLayer0
                radius: Appearance.rounding.small
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                
                StyledText {
                    id: popupText
                    anchors.centerIn: parent
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer0
                    text: dateDetails
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
