pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * Claude's task list (TaskCreate/TaskUpdate), above the input box.
 * Collapses to a one-line summary once everything is done.
 */
Rectangle {
    id: root
    property var tasks: []
    readonly property int doneCount: tasks.filter(t => t.status === "completed").length
    property bool expanded: doneCount < tasks.length

    implicitHeight: column.implicitHeight + 6 * 2
    radius: Appearance.rounding.small
    color: Appearance.colors.colLayer2

    ColumnLayout {
        id: column
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 6
            leftMargin: 10
            rightMargin: 10
        }
        spacing: 2

        MouseArea {
            Layout.fillWidth: true
            implicitHeight: headerRow.implicitHeight + 4
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
            RowLayout {
                id: headerRow
                anchors.fill: parent
                spacing: 6
                MaterialSymbol {
                    text: "checklist"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer2
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Tasks  %1/%2").arg(root.doneCount).arg(root.tasks.length)
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnLayer2
                }
                MaterialSymbol {
                    text: "keyboard_arrow_down"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                    rotation: root.expanded ? 180 : 0
                }
            }
        }

        Repeater {
            model: root.expanded ? root.tasks : []
            delegate: RowLayout {
                id: taskRow
                required property var modelData
                readonly property string status: modelData.status
                Layout.fillWidth: true
                spacing: 6
                Item {
                    implicitWidth: 16
                    implicitHeight: 16
                    MaterialLoadingIndicator {
                        anchors.centerIn: parent
                        visible: taskRow.status === "in_progress"
                        implicitSize: 16
                    }
                    MaterialSymbol {
                        anchors.centerIn: parent
                        visible: taskRow.status !== "in_progress"
                        text: taskRow.status === "completed" ? "check_circle" : "radio_button_unchecked"
                        fill: taskRow.status === "completed" ? 1 : 0
                        iconSize: Appearance.font.pixelSize.normal
                        color: taskRow.status === "completed" ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: taskRow.status === "in_progress" && taskRow.modelData.activeForm ? taskRow.modelData.activeForm : taskRow.modelData.subject
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.strikeout: taskRow.status === "completed"
                    color: taskRow.status === "completed" ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer2
                }
            }
        }
    }
}
