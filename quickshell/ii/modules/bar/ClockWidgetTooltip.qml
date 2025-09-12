import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root
    property string formattedDate: Qt.locale().toString(DateTime.clock.date, "dddd, MMMM dd, yyyy")
    property string formattedTime: DateTime.time
    property string formattedUptime: DateTime.uptime
    property string todosSection: getUpcomingTodos()

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
            return `${index + 1}. ${item.content}`;
        }).join('\n');

        if (unfinishedTodos.length > 5) {
            todoText += `\n${Translation.tr("... and %1 more").arg(unfinishedTodos.length - 5)}`;
        }

        return todoText;
    }

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 4

        // Date + Time row
        RowLayout {
            spacing: 5

            MaterialSymbol {
                fill: 0
                font.weight: Font.Medium
                text: "calendar_month"
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnSurfaceVariant
            }
            StyledText {
                horizontalAlignment: Text.AlignLeft
                color: Appearance.colors.colOnSurfaceVariant
                text: `${root.formattedDate}`
                font.weight: Font.Medium
            }
        }

        // Uptime row
        RowLayout {
            spacing: 5
            Layout.fillWidth: true
            MaterialSymbol {
                text: "timelapse"
                color: Appearance.colors.colOnSurfaceVariant
                font.pixelSize: Appearance.font.pixelSize.large
            }
            StyledText {
                text: Translation.tr("System uptime:")
                color: Appearance.colors.colOnSurfaceVariant
            }
            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                color: Appearance.colors.colOnSurfaceVariant
                text: root.formattedUptime
            }
        }

        // Tasks
        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true

            RowLayout {
                spacing: 4
                Layout.fillWidth: true
                MaterialSymbol {
                    text: "checklist"
                    color: Appearance.colors.colOnSurfaceVariant
                    font.pixelSize: Appearance.font.pixelSize.large
                }
                StyledText {
                    text: Translation.tr("To Do:")
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.Wrap
                color: Appearance.colors.colOnSurfaceVariant
                text: root.todosSection
            }
        }
    }
}
