import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.sidebarRight.calendar
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

StyledPopup {
    id: root
    property string formattedDate: Qt.locale().toString(DateTime.clock.date, "dddd, MMMM dd, yyyy")
    property string formattedTime: DateTime.time
    property string formattedUptime: DateTime.uptime
    property string todosSection: getUpcomingTodos()
    property bool showCalendar: false
    property bool calendarOpen: false

    // Click to show calendar. Content is only reset on open, so closing doesn't flash the info view
    keepOpen: calendarOpen
    onActiveChanged: if (active) showCalendar = calendarOpen

    property Connections clickHandler: Connections {
        target: root.hoverTarget
        function onClicked() {
            root.calendarOpen = !root.calendarOpen;
            root.showCalendar = root.calendarOpen;
        }
    }

    property HyprlandFocusGrab focusGrab: HyprlandFocusGrab { // Close calendar when clicking outside
        active: root.calendarOpen
        windows: [root.item, root.QsWindow?.window]
        onCleared: root.calendarOpen = false
    }

    function getUpcomingTodos() {
        const unfinishedTodos = Todo.list.filter(function (item) {
            return !item.done;
        });
        if (unfinishedTodos.length === 0) {
            return Translation.tr("No pending tasks");
        }

        // Limit to first 5 todos to keep popup manageable
        const limitedTodos = unfinishedTodos.slice(0, 5);
        let todoText = limitedTodos.map(function (item, index) {
            return `  ${index + 1}. ${item.content}`;
        }).join('\n');

        if (unfinishedTodos.length > 5) {
            todoText += `\n  ${Translation.tr("... and %1 more").arg(unfinishedTodos.length - 5)}`;
        }

        return todoText;
    }

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 4

        StyledPopupHeaderRow {
            icon: "calendar_month"
            label: root.formattedDate
        }

        Loader { // Only built when shown
            active: root.showCalendar
            visible: active
            sourceComponent: CalendarWidget {}
        }

        StyledPopupValueRow {
            visible: !root.showCalendar
            icon: "timelapse"
            label: Translation.tr("System uptime:")
            value: root.formattedUptime
        }

        // Tasks
        Column {
            visible: !root.showCalendar
            spacing: 0
            Layout.fillWidth: true

            StyledPopupValueRow {
                icon: "checklist"
                label: Translation.tr("To Do:")
                value: ""
            }

            StyledText {
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.Wrap
                color: Appearance.colors.colOnSurfaceVariant
                text: root.todosSection
            }
        }
    }
}
