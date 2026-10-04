pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets
import "calendar_layout.js" as CalendarLayout

AbstractBackgroundWidget {
    id: root

    configEntryName: "todo"
    needsColText: true

    readonly property real minWidth: 280
    readonly property real maxWidth: Math.min(900, scaledScreenWidth - 40)
    readonly property real minHeight: 220
    readonly property real maxHeight: Math.min(1000, scaledScreenHeight - 40)

    width: Math.max(minWidth, Math.min(maxWidth, configEntry?.width ?? 380))
    height: Math.max(minHeight, Math.min(maxHeight, configEntry?.height ?? 420))

    function saveDimensions() {
        if (configEntry) {
            configEntry.width = root.width;
            configEntry.height = root.height;
            configEntry.x = root.x;
            configEntry.y = root.y;
            root.targetX = root.x;
            root.targetY = root.y;
        }
    }

    property bool showCalendar: false
    property int monthShift: 0
    property var viewingDate: CalendarLayout.getDateInXMonthsTime(monthShift)
    property var calendarLayout: CalendarLayout.getCalendarLayout(viewingDate, monthShift === 0)
    property string selectedDateString: CalendarLayout.getTodayDateString()

    readonly property string todayDateString: CalendarLayout.getTodayDateString()
    readonly property bool isViewingPastDate: root.selectedDateString < root.todayDateString

    function getTaskCountForDate(dateStr, list) {
        if (!list) return 0;
        const todayStr = root.todayDateString;
        if (dateStr < todayStr) {
            // For past dates: count tasks originating on that date that were left unfinished on that date
            return list.filter(t => {
                const itemDate = t.date || todayStr;
                if (itemDate !== dateStr) return false;
                const completedDate = t.completedDate || (t.done ? itemDate : null);
                return (!t.done || (completedDate && completedDate > dateStr));
            }).length;
        } else if (dateStr === todayStr) {
            // For today: count all pending tasks (today's + past rolled over)
            return list.filter(t => {
                const itemDate = t.date || todayStr;
                return (!t.done && (itemDate <= todayStr));
            }).length;
        } else {
            // For future dates: scheduled tasks
            return list.filter(t => !t.done && t.date === dateStr).length;
        }
    }

    function addTask(text) {
        const trimmed = (text ?? "").trim();
        if (trimmed.length > 0) {
            Todo.addTask(trimmed, root.selectedDateString);
            taskTextField.text = "";
        }
    }

    readonly property var selectedDateTasks: {
        if (!Todo.list) return [];
        const todayStr = root.todayDateString;
        const isViewingToday = (root.selectedDateString === todayStr);
        const isViewingPast = (root.selectedDateString < todayStr);

        return Todo.list
            .map((item, index) => {
                const itemDate = item.date || todayStr;
                const completedDate = item.completedDate || (item.done ? itemDate : null);

                let showOnSelectedDate = false;
                let isRolledOverToHere = false;
                let isPastUnfinished = false;

                if (isViewingToday) {
                    if (itemDate === todayStr || completedDate === todayStr) {
                        showOnSelectedDate = true;
                        isRolledOverToHere = (itemDate < todayStr && !item.done);
                    } else if (itemDate < todayStr && !item.done) {
                        showOnSelectedDate = true;
                        isRolledOverToHere = true;
                    }
                } else if (isViewingPast) {
                    if (itemDate === root.selectedDateString) {
                        showOnSelectedDate = true;
                        if (!item.done || (completedDate && completedDate > root.selectedDateString)) {
                            isPastUnfinished = true;
                        }
                    }
                } else {
                    if (itemDate === root.selectedDateString) {
                        showOnSelectedDate = true;
                    }
                }

                return Object.assign({}, item, {
                    originalIndex: index,
                    itemDate: itemDate,
                    completedDate: completedDate,
                    showOnSelectedDate: showOnSelectedDate,
                    isRolledOverToHere: isRolledOverToHere,
                    isPastUnfinished: isPastUnfinished,
                    subtasks: (item.subtasks && Array.isArray(item.subtasks)) ? item.subtasks : []
                });
            })
            .filter(item => item.showOnSelectedDate)
            .sort((a, b) => {
                if (a.isPastUnfinished !== b.isPastUnfinished) {
                    return a.isPastUnfinished ? -1 : 1;
                }
                if (a.done !== b.done) {
                    return a.done ? 1 : -1;
                }
                return a.originalIndex - b.originalIndex;
            });
    }

    readonly property int remainingCount: selectedDateTasks.filter(t => !t.done).length
    readonly property int pastRolledOverCount: selectedDateTasks.filter(t => t.isPastUnfinished).length

    function getFormattedDateTitle(dateStr) {
        if (!dateStr) return "";
        const todayStr = CalendarLayout.getTodayDateString();
        if (dateStr === todayStr) return Translation.tr("Today");

        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        const tomorrowStr = CalendarLayout.formatDateKey(tomorrow.getFullYear(), tomorrow.getMonth() + 1, tomorrow.getDate());
        if (dateStr === tomorrowStr) return Translation.tr("Tomorrow");

        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        const yesterdayStr = CalendarLayout.formatDateKey(yesterday.getFullYear(), yesterday.getMonth() + 1, yesterday.getDate());
        if (dateStr === yesterdayStr) return Translation.tr("Yesterday");

        const parts = dateStr.split("-").map(p => parseInt(p, 10));
        const d = new Date(parts[0], parts[1] - 1, parts[2]);
        return d.toLocaleDateString(Qt.locale(), "dddd");
    }

    function getFormattedDateSubtitle(dateStr) {
        if (!dateStr) return "";
        const parts = dateStr.split("-").map(p => parseInt(p, 10));
        const d = new Date(parts[0], parts[1] - 1, parts[2]);
        return d.toLocaleDateString(Qt.locale(), "MMMM d, yyyy");
    }

    // Shadow
    StyledRectangularShadow {
        target: backgroundCard
        radius: backgroundCard.radius
        blur: 0.6 * Appearance.sizes.elevationMargin
    }

    // Main Card
    Rectangle {
        id: backgroundCard
        z: 1
        anchors.fill: parent
        color: Appearance.colors.colLayer0
        radius: Appearance.rounding.large
        border.width: 1
        border.color: Appearance.colors.colLayer0Border

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
        Behavior on border.color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            // Header for selected day
            RowLayout {
                id: headerRow
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    RowLayout {
                        spacing: 6

                        StyledText {
                            text: root.getFormattedDateTitle(root.selectedDateString)
                            font.pixelSize: Appearance.font.pixelSize.larger
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer0
                            elide: Text.ElideRight
                        }

                        // Return to Today chip if viewing another date
                        RippleButton {
                            implicitWidth: 24
                            implicitHeight: 24
                            buttonRadius: Appearance.rounding.verysmall
                            visible: root.selectedDateString !== CalendarLayout.getTodayDateString()
                            onClicked: {
                                root.selectedDateString = CalendarLayout.getTodayDateString();
                                root.monthShift = 0;
                            }
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "today"
                                iconSize: 16
                                color: Appearance.colors.colPrimary
                            }
                        }
                    }

                    StyledText {
                        text: root.getFormattedDateSubtitle(root.selectedDateString)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOutlineVariant
                        elide: Text.ElideRight
                    }
                }

                // Task count chip
                Rectangle {
                    implicitWidth: badgeLayout.implicitWidth + 14
                    implicitHeight: 24
                    radius: Appearance.rounding.full
                    color: {
                        if (root.isViewingPastDate && root.pastRolledOverCount > 0) {
                            return ColorUtils.transparentize("#E5C07B", 0.82);
                        }
                        if (root.remainingCount > 0) {
                            return ColorUtils.transparentize(Appearance.colors.colPrimary, 0.85);
                        }
                        return Appearance.colors.colLayer2;
                    }

                    RowLayout {
                        id: badgeLayout
                        anchors.centerIn: parent
                        spacing: 4

                        MaterialSymbol {
                            visible: root.isViewingPastDate && root.pastRolledOverCount > 0
                            text: "arrow_forward"
                            iconSize: 13
                            color: "#E5C07B"
                        }

                        StyledText {
                            id: badgeText
                            text: {
                                if (root.isViewingPastDate && root.pastRolledOverCount > 0) {
                                    return `${root.pastRolledOverCount} rolled over`;
                                }
                                if (root.remainingCount > 0) {
                                    return `${root.remainingCount} pending`;
                                }
                                return Translation.tr("All done");
                            }
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: Font.DemiBold
                            color: {
                                if (root.isViewingPastDate && root.pastRolledOverCount > 0) {
                                    return "#E5C07B";
                                }
                                if (root.remainingCount > 0) {
                                    return Appearance.colors.colPrimary;
                                }
                                return Appearance.colors.colOutlineVariant;
                            }
                        }
                    }
                }

                // Calendar toggle button
                RippleButton {
                    id: calendarButton
                    implicitWidth: 32
                    implicitHeight: 32
                    buttonRadius: Appearance.rounding.verysmall
                    toggled: root.showCalendar
                    onClicked: root.showCalendar = !root.showCalendar

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "calendar_month"
                        iconSize: 18
                        color: root.showCalendar ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer0
                    }
                }
            }

            // Tasks list
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                // Empty state
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: root.selectedDateTasks.length === 0
                    spacing: 6

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        text: "event_available"
                        iconSize: 36
                        color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.5)
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("No tasks for this day")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOutlineVariant
                    }
                }

                // Task List View
                ListView {
                    id: taskListView
                    anchors.fill: parent
                    spacing: 4
                    model: root.selectedDateTasks
                    boundsBehavior: Flickable.StopAtBounds
                    displaced: Transition {
                        NumberAnimation {
                            properties: "y"
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                        }
                    }

                    delegate: Rectangle {
                        id: taskRow
                        required property var modelData
                        property bool isEditing: false
                        property bool cancelRequested: false
                        property bool isExpanded: true
                        property bool isAddingSubtask: false

                        readonly property bool isPastUnfinished: taskRow.modelData.isPastUnfinished ?? false
                        readonly property bool isRolledOverToHere: taskRow.modelData.isRolledOverToHere ?? false
                        readonly property var subtasks: taskRow.modelData.subtasks ?? []
                        readonly property int totalSubtasks: subtasks.length
                        readonly property int doneSubtasks: {
                            let count = 0;
                            for (let i = 0; i < subtasks.length; i++) {
                                if (subtasks[i].done) count++;
                            }
                            return count;
                        }

                        readonly property color colYellow: "#E5C07B"
                        readonly property color textMainColor: {
                            if (isPastUnfinished) return colYellow;
                            if (taskRow.modelData.done) return Appearance.colors.colOutlineVariant;
                            return Appearance.colors.colOnLayer0;
                        }

                        width: taskListView.width
                        implicitHeight: taskMainCol.implicitHeight + 8
                        radius: Appearance.rounding.small
                        color: taskRow.isEditing
                            ? Appearance.colors.colLayer2
                            : (isPastUnfinished
                                ? (rowMouseArea.containsMouse ? ColorUtils.transparentize(colYellow, 0.88) : ColorUtils.transparentize(colYellow, 0.94))
                                : (rowMouseArea.containsMouse ? Appearance.colors.colLayer1 : "transparent"))

                        border.width: isPastUnfinished ? 1 : 0
                        border.color: isPastUnfinished ? ColorUtils.transparentize(colYellow, 0.6) : "transparent"

                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }

                        function startEdit() {
                            taskRow.cancelRequested = false;
                            editTextField.text = taskRow.modelData.content;
                            taskRow.isEditing = true;
                            Qt.callLater(() => {
                                editTextField.forceActiveFocus();
                                editTextField.selectAll();
                            });
                        }

                        function commitEdit() {
                            if (!taskRow.isEditing) return;
                            const trimmed = (editTextField.text ?? "").trim();
                            if (trimmed.length > 0 && trimmed !== taskRow.modelData.content) {
                                Todo.editTask(taskRow.modelData.originalIndex, trimmed);
                            }
                            taskRow.isEditing = false;
                            taskRow.cancelRequested = false;
                        }

                        function cancelEdit() {
                            taskRow.isEditing = false;
                            taskRow.cancelRequested = false;
                            editTextField.text = taskRow.modelData.content;
                        }

                        ColumnLayout {
                            id: taskMainCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 4
                            spacing: 4

                            // Primary Task Row
                            Item {
                                Layout.fillWidth: true
                                implicitHeight: Math.max(34, taskRowLayout.implicitHeight)

                                MouseArea {
                                    id: rowMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: !taskRow.isEditing
                                    onDoubleClicked: (mouse) => {
                                        taskRow.startEdit();
                                    }
                                }

                                RowLayout {
                                    id: taskRowLayout
                                    anchors.fill: parent
                                    anchors.leftMargin: 4
                                    anchors.rightMargin: 4
                                    spacing: 6

                                    // Expand/Collapse Chevron (visible when task has subtasks)
                                    RippleButton {
                                        implicitWidth: 20
                                        implicitHeight: 20
                                        buttonRadius: Appearance.rounding.verysmall
                                        visible: taskRow.totalSubtasks > 0
                                        onClicked: taskRow.isExpanded = !taskRow.isExpanded

                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: taskRow.isExpanded ? "expand_more" : "chevron_right"
                                            iconSize: 16
                                            color: Appearance.colors.colOutlineVariant
                                        }
                                    }

                                    // Toggle Checkbox
                                    MouseArea {
                                        implicitWidth: 22
                                        implicitHeight: 22
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (taskRow.isEditing) {
                                                taskRow.commitEdit();
                                            }
                                            if (taskRow.modelData.done) {
                                                Todo.markUnfinished(taskRow.modelData.originalIndex);
                                            } else {
                                                Todo.markDone(taskRow.modelData.originalIndex, root.selectedDateString);
                                            }
                                        }

                                        MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: {
                                                if (taskRow.modelData.done) return "check_circle";
                                                if (taskRow.isPastUnfinished) return "arrow_forward";
                                                return "radio_button_unchecked";
                                            }
                                            iconSize: 20
                                            color: {
                                                if (taskRow.modelData.done) return Appearance.colors.colPrimary;
                                                if (taskRow.isPastUnfinished) return taskRow.colYellow;
                                                return Appearance.colors.colOutline;
                                            }
                                        }
                                    }

                                    // Task Content (view mode)
                                    RowLayout {
                                        Layout.fillWidth: true
                                        visible: !taskRow.isEditing
                                        spacing: 6

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: taskRow.modelData.content
                                            wrapMode: Text.Wrap
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                            font.strikeout: taskRow.modelData.done
                                            color: taskRow.textMainColor
                                            opacity: taskRow.isPastUnfinished ? 0.95 : 1.0
                                        }

                                        // Subtask Progress Badge
                                        Rectangle {
                                            visible: taskRow.totalSubtasks > 0
                                            implicitWidth: subtaskProgressText.implicitWidth + 10
                                            implicitHeight: 18
                                            radius: Appearance.rounding.full
                                            color: (taskRow.doneSubtasks === taskRow.totalSubtasks)
                                                ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.8)
                                                : Appearance.colors.colLayer2

                                            StyledText {
                                                id: subtaskProgressText
                                                anchors.centerIn: parent
                                                text: `${taskRow.doneSubtasks}/${taskRow.totalSubtasks}`
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                font.weight: Font.DemiBold
                                                color: (taskRow.doneSubtasks === taskRow.totalSubtasks)
                                                    ? Appearance.colors.colPrimary
                                                    : Appearance.colors.colOutlineVariant
                                            }
                                        }

                                        // Rolled Over Badge (when viewing a past date)
                                        Rectangle {
                                            visible: taskRow.isPastUnfinished
                                            implicitWidth: rolledOverBadgeLayout.implicitWidth + 10
                                            implicitHeight: 18
                                            radius: Appearance.rounding.full
                                            color: ColorUtils.transparentize(taskRow.colYellow, 0.82)

                                            RowLayout {
                                                id: rolledOverBadgeLayout
                                                anchors.centerIn: parent
                                                spacing: 2
                                                MaterialSymbol {
                                                    text: "arrow_forward"
                                                    iconSize: 11
                                                    color: taskRow.colYellow
                                                }
                                                StyledText {
                                                    text: Translation.tr("Rolled over")
                                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                                    font.weight: Font.Medium
                                                    color: taskRow.colYellow
                                                }
                                            }
                                        }

                                        // Origin Badge (when viewing today, showing where task rolled over from)
                                        Rectangle {
                                            visible: taskRow.isRolledOverToHere && !taskRow.modelData.done
                                            implicitWidth: originBadgeText.implicitWidth + 10
                                            implicitHeight: 18
                                            radius: Appearance.rounding.full
                                            color: Appearance.colors.colLayer2

                                            StyledText {
                                                id: originBadgeText
                                                anchors.centerIn: parent
                                                text: `from ${taskRow.modelData.itemDate}`
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                color: Appearance.colors.colOutlineVariant
                                            }
                                        }
                                    }

                                    // Task Content (edit mode)
                                    TextField {
                                        id: editTextField
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 32
                                        Layout.alignment: Qt.AlignVCenter
                                        verticalAlignment: Text.AlignVCenter
                                        visible: taskRow.isEditing
                                        color: Appearance.colors.colOnLayer0
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        selectByMouse: true
                                        activeFocusOnTab: true
                                        clip: true
                                        leftPadding: 8
                                        rightPadding: 8
                                        topPadding: 0
                                        bottomPadding: 0
                                        background: Rectangle {
                                            color: Appearance.colors.colLayer1
                                            radius: Appearance.rounding.verysmall
                                            border.width: 1
                                            border.color: Appearance.colors.colPrimary
                                        }
                                        onAccepted: taskRow.commitEdit()
                                        Keys.onEscapePressed: (event) => {
                                            taskRow.cancelEdit();
                                            event.accepted = true;
                                        }
                                        onActiveFocusChanged: {
                                            if (!activeFocus && taskRow.isEditing) {
                                                if (!taskRow.cancelRequested) {
                                                    taskRow.commitEdit();
                                                } else {
                                                    taskRow.cancelEdit();
                                                }
                                            }
                                        }
                                    }

                                    // Action Button: Add Subtask (on hover)
                                    RippleButton {
                                        implicitWidth: 24
                                        implicitHeight: 24
                                        buttonRadius: Appearance.rounding.verysmall
                                        visible: !taskRow.isEditing && rowMouseArea.containsMouse
                                        onClicked: {
                                            taskRow.isExpanded = true;
                                            taskRow.isAddingSubtask = true;
                                        }

                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: "playlist_add"
                                            iconSize: 16
                                            color: Appearance.colors.colOutlineVariant
                                        }
                                    }

                                    // Action Button: Edit (on hover)
                                    RippleButton {
                                        implicitWidth: 24
                                        implicitHeight: 24
                                        buttonRadius: Appearance.rounding.verysmall
                                        visible: !taskRow.isEditing && rowMouseArea.containsMouse
                                        onClicked: taskRow.startEdit()

                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: "edit"
                                            iconSize: 15
                                            color: Appearance.colors.colOutlineVariant
                                        }
                                    }

                                    // Action Button: Delete (on hover)
                                    RippleButton {
                                        implicitWidth: 24
                                        implicitHeight: 24
                                        buttonRadius: Appearance.rounding.verysmall
                                        visible: !taskRow.isEditing && rowMouseArea.containsMouse
                                        onClicked: Todo.deleteItem(taskRow.modelData.originalIndex)

                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: "close"
                                            iconSize: 16
                                            color: Appearance.colors.colOutlineVariant
                                        }
                                    }

                                    // Action Button: Save Edit (when editing)
                                    RippleButton {
                                        id: saveEditButton
                                        implicitWidth: 24
                                        implicitHeight: 24
                                        buttonRadius: Appearance.rounding.verysmall
                                        visible: taskRow.isEditing
                                        onClicked: taskRow.commitEdit()

                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: "check"
                                            iconSize: 17
                                            color: Appearance.colors.colPrimary
                                        }
                                    }

                                    // Action Button: Cancel Edit (when editing)
                                    RippleButton {
                                        id: cancelEditButton
                                        implicitWidth: 24
                                        implicitHeight: 24
                                        buttonRadius: Appearance.rounding.verysmall
                                        visible: taskRow.isEditing
                                        onPressed: {
                                            taskRow.cancelRequested = true;
                                        }
                                        onClicked: {
                                            taskRow.cancelEdit();
                                        }

                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: "close"
                                            iconSize: 17
                                            color: Appearance.colors.colOutlineVariant
                                        }
                                    }
                                }
                            }

                            // Subtasks Section (Indented tree with guideline)
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: 26
                                Layout.rightMargin: 4
                                visible: taskRow.isExpanded && (taskRow.totalSubtasks > 0 || taskRow.isAddingSubtask)
                                spacing: 3

                                // Repeater for Subtasks
                                Repeater {
                                    model: taskRow.subtasks
                                    delegate: Rectangle {
                                        id: subtaskRow
                                        required property int index
                                        required property var modelData
                                        property bool isSubtaskEditing: false
                                        property bool cancelSubtaskRequested: false

                                        Layout.fillWidth: true
                                        implicitHeight: Math.max(26, subtaskRowLayout.implicitHeight + 4)
                                        radius: Appearance.rounding.verysmall
                                        color: subtaskRow.isSubtaskEditing
                                            ? Appearance.colors.colLayer2
                                            : (subtaskMouseArea.containsMouse ? Appearance.colors.colLayer2 : "transparent")

                                        function startSubtaskEdit() {
                                            subtaskRow.cancelSubtaskRequested = false;
                                            subtaskEditField.text = subtaskRow.modelData.content;
                                            subtaskRow.isSubtaskEditing = true;
                                            Qt.callLater(() => {
                                                subtaskEditField.forceActiveFocus();
                                                subtaskEditField.selectAll();
                                            });
                                        }

                                        function commitSubtaskEdit() {
                                            if (!subtaskRow.isSubtaskEditing) return;
                                            const trimmed = (subtaskEditField.text ?? "").trim();
                                            if (trimmed.length > 0 && trimmed !== subtaskRow.modelData.content) {
                                                Todo.editSubtask(taskRow.modelData.originalIndex, subtaskRow.index, trimmed);
                                            }
                                            subtaskRow.isSubtaskEditing = false;
                                            subtaskRow.cancelSubtaskRequested = false;
                                        }

                                        function cancelSubtaskEdit() {
                                            subtaskRow.isSubtaskEditing = false;
                                            subtaskRow.cancelSubtaskRequested = false;
                                            subtaskEditField.text = subtaskRow.modelData.content;
                                        }

                                        MouseArea {
                                            id: subtaskMouseArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            enabled: !subtaskRow.isSubtaskEditing
                                            onDoubleClicked: (mouse) => {
                                                subtaskRow.startSubtaskEdit();
                                            }
                                        }

                                        RowLayout {
                                            id: subtaskRowLayout
                                            anchors.fill: parent
                                            anchors.leftMargin: 4
                                            anchors.rightMargin: 4
                                            spacing: 6

                                            // Branch icon
                                            MaterialSymbol {
                                                text: "subdirectory_arrow_right"
                                                iconSize: 14
                                                color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.45)
                                            }

                                            // Subtask Checkbox
                                            MouseArea {
                                                implicitWidth: 18
                                                implicitHeight: 18
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    Todo.toggleSubtask(taskRow.modelData.originalIndex, subtaskRow.index);
                                                }

                                                MaterialSymbol {
                                                    anchors.centerIn: parent
                                                    text: subtaskRow.modelData.done ? "check_circle" : "radio_button_unchecked"
                                                    iconSize: 16
                                                    color: subtaskRow.modelData.done ? Appearance.colors.colPrimary : Appearance.colors.colOutline
                                                }
                                            }

                                            // Subtask Content (view mode)
                                            StyledText {
                                                Layout.fillWidth: true
                                                visible: !subtaskRow.isSubtaskEditing
                                                text: subtaskRow.modelData.content
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                font.strikeout: subtaskRow.modelData.done
                                                color: subtaskRow.modelData.done
                                                    ? Appearance.colors.colOutlineVariant
                                                    : (taskRow.isPastUnfinished ? taskRow.colYellow : Appearance.colors.colOnLayer0)
                                            }

                                            // Subtask Content (edit mode)
                                            TextField {
                                                id: subtaskEditField
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 26
                                                Layout.alignment: Qt.AlignVCenter
                                                verticalAlignment: Text.AlignVCenter
                                                visible: subtaskRow.isSubtaskEditing
                                                color: Appearance.colors.colOnLayer0
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                selectByMouse: true
                                                activeFocusOnTab: true
                                                clip: true
                                                leftPadding: 6
                                                rightPadding: 6
                                                topPadding: 0
                                                bottomPadding: 0
                                                background: Rectangle {
                                                    color: Appearance.colors.colLayer1
                                                    radius: Appearance.rounding.verysmall
                                                    border.width: 1
                                                    border.color: Appearance.colors.colPrimary
                                                }
                                                onAccepted: subtaskRow.commitSubtaskEdit()
                                                Keys.onEscapePressed: (event) => {
                                                    subtaskRow.cancelSubtaskEdit();
                                                    event.accepted = true;
                                                }
                                                onActiveFocusChanged: {
                                                    if (!activeFocus && subtaskRow.isSubtaskEditing) {
                                                        if (!subtaskRow.cancelSubtaskRequested) {
                                                            subtaskRow.commitSubtaskEdit();
                                                        } else {
                                                            subtaskRow.cancelSubtaskEdit();
                                                        }
                                                    }
                                                }
                                            }

                                            // Subtask Edit (on hover)
                                            RippleButton {
                                                implicitWidth: 20
                                                implicitHeight: 20
                                                buttonRadius: Appearance.rounding.verysmall
                                                visible: !subtaskRow.isSubtaskEditing && subtaskMouseArea.containsMouse
                                                onClicked: subtaskRow.startSubtaskEdit()
                                                contentItem: MaterialSymbol {
                                                    anchors.centerIn: parent
                                                    text: "edit"
                                                    iconSize: 13
                                                    color: Appearance.colors.colOutlineVariant
                                                }
                                            }

                                            // Subtask Delete (on hover)
                                            RippleButton {
                                                implicitWidth: 20
                                                implicitHeight: 20
                                                buttonRadius: Appearance.rounding.verysmall
                                                visible: !subtaskRow.isSubtaskEditing && subtaskMouseArea.containsMouse
                                                onClicked: Todo.deleteSubtask(taskRow.modelData.originalIndex, subtaskRow.index)
                                                contentItem: MaterialSymbol {
                                                    anchors.centerIn: parent
                                                    text: "close"
                                                    iconSize: 14
                                                    color: Appearance.colors.colOutlineVariant
                                                }
                                            }

                                            // Subtask Save Edit
                                            RippleButton {
                                                implicitWidth: 20
                                                implicitHeight: 20
                                                buttonRadius: Appearance.rounding.verysmall
                                                visible: subtaskRow.isSubtaskEditing
                                                onClicked: subtaskRow.commitSubtaskEdit()
                                                contentItem: MaterialSymbol {
                                                    anchors.centerIn: parent
                                                    text: "check"
                                                    iconSize: 14
                                                    color: Appearance.colors.colPrimary
                                                }
                                            }

                                            // Subtask Cancel Edit
                                            RippleButton {
                                                implicitWidth: 20
                                                implicitHeight: 20
                                                buttonRadius: Appearance.rounding.verysmall
                                                visible: subtaskRow.isSubtaskEditing
                                                onPressed: subtaskRow.cancelSubtaskRequested = true
                                                onClicked: subtaskRow.cancelSubtaskEdit()
                                                contentItem: MaterialSymbol {
                                                    anchors.centerIn: parent
                                                    text: "close"
                                                    iconSize: 14
                                                    color: Appearance.colors.colOutlineVariant
                                                }
                                            }
                                        }
                                    }
                                }

                                // Inline Add Subtask Input Box
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 28
                                    visible: taskRow.isAddingSubtask
                                    radius: Appearance.rounding.verysmall
                                    color: Appearance.colors.colLayer1
                                    border.width: 1
                                    border.color: addSubtaskInput.activeFocus ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.7)

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 6
                                        anchors.rightMargin: 4
                                        spacing: 4

                                        MaterialSymbol {
                                            text: "subdirectory_arrow_right"
                                            iconSize: 14
                                            color: Appearance.colors.colPrimary
                                        }

                                        TextField {
                                            id: addSubtaskInput
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            verticalAlignment: Text.AlignVCenter
                                            color: Appearance.colors.colOnLayer0
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            placeholderText: Translation.tr("Add subtask...")
                                            placeholderTextColor: Appearance.colors.colOutlineVariant
                                            selectByMouse: true
                                            activeFocusOnTab: true
                                            clip: true
                                            background: null
                                            onAccepted: {
                                                const trimmed = text.trim();
                                                if (trimmed.length > 0) {
                                                    Todo.addSubtask(taskRow.modelData.originalIndex, trimmed);
                                                    text = "";
                                                } else {
                                                    taskRow.isAddingSubtask = false;
                                                }
                                            }
                                            Keys.onEscapePressed: (event) => {
                                                taskRow.isAddingSubtask = false;
                                                event.accepted = true;
                                            }
                                        }

                                        // Submit button
                                        RippleButton {
                                            implicitWidth: 22
                                            implicitHeight: 22
                                            buttonRadius: Appearance.rounding.verysmall
                                            enabled: addSubtaskInput.text.trim().length > 0
                                            onClicked: {
                                                const trimmed = addSubtaskInput.text.trim();
                                                if (trimmed.length > 0) {
                                                    Todo.addSubtask(taskRow.modelData.originalIndex, trimmed);
                                                    addSubtaskInput.text = "";
                                                }
                                            }
                                            contentItem: MaterialSymbol {
                                                anchors.centerIn: parent
                                                text: "arrow_upward"
                                                iconSize: 14
                                                color: addSubtaskInput.text.trim().length > 0 ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                                            }
                                        }

                                        // Close/Cancel button
                                        RippleButton {
                                            implicitWidth: 20
                                            implicitHeight: 20
                                            buttonRadius: Appearance.rounding.verysmall
                                            onClicked: {
                                                taskRow.isAddingSubtask = false;
                                                addSubtaskInput.text = "";
                                            }
                                            contentItem: MaterialSymbol {
                                                anchors.centerIn: parent
                                                text: "close"
                                                iconSize: 14
                                                color: Appearance.colors.colOutlineVariant
                                            }
                                        }
                                    }

                                    Connections {
                                        target: taskRow
                                        function onIsAddingSubtaskChanged() {
                                            if (taskRow.isAddingSubtask) {
                                                Qt.callLater(() => addSubtaskInput.forceActiveFocus());
                                            }
                                        }
                                    }
                                }

                                // "+ Add subtask" button when not actively typing
                                MouseArea {
                                    Layout.fillWidth: true
                                    implicitHeight: 20
                                    visible: !taskRow.isAddingSubtask
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        taskRow.isAddingSubtask = true;
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: 4
                                        MaterialSymbol {
                                            text: "add"
                                            iconSize: 13
                                            color: parent.parent.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                                        }
                                        StyledText {
                                            text: Translation.tr("Add subtask")
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: parent.parent.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Quick Add Input Box
            Rectangle {
                Layout.fillWidth: true
                height: 42
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: taskTextField.activeFocus ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.7)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 6
                    spacing: 6

                    MaterialSymbol {
                        text: "add_task"
                        iconSize: 18
                        color: Appearance.colors.colOutlineVariant
                    }

                    TextField {
                        id: taskTextField
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        verticalAlignment: Text.AlignVCenter
                        color: Appearance.colors.colOnLayer0
                        font.pixelSize: Appearance.font.pixelSize.normal
                        placeholderText: Translation.tr("Add task...")
                        placeholderTextColor: Appearance.colors.colOutlineVariant
                        selectByMouse: true
                        activeFocusOnTab: true
                        clip: true
                        background: null
                        onAccepted: root.addTask(taskTextField.text)
                    }

                    RippleButton {
                        implicitWidth: 30
                        implicitHeight: 30
                        buttonRadius: Appearance.rounding.verysmall
                        enabled: taskTextField.text.trim().length > 0
                        onClicked: root.addTask(taskTextField.text)

                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "arrow_upward"
                            iconSize: 18
                            color: taskTextField.text.trim().length > 0 ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                        }
                    }
                }
            }
        }

        // Visual resize grip in bottom-right corner
        Item {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: 16
            height: 16
            visible: !GlobalStates.screenLocked

            Canvas {
                id: gripCanvas
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.strokeStyle = Appearance.colors.colOutlineVariant;
                    ctx.lineWidth = 1.5;
                    ctx.lineCap = "round";

                    ctx.beginPath();
                    ctx.moveTo(width - 4, height - 10);
                    ctx.lineTo(width - 10, height - 4);
                    ctx.stroke();

                    ctx.beginPath();
                    ctx.moveTo(width - 4, height - 6);
                    ctx.lineTo(width - 6, height - 4);
                    ctx.stroke();
                }
                Connections {
                    target: Appearance.colors
                    function onColOutlineVariantChanged() { gripCanvas.requestPaint(); }
                }
            }
        }
    }

    // ================= DISMISS OVERLAY =================
    // Sits at z: 90 above backgroundCard (z: 1), but below calendarPopupCard (z: 100)
    MouseArea {
        id: popupDismissArea
        z: 90
        anchors.fill: parent
        visible: root.showCalendar
        onClicked: root.showCalendar = false
    }

    // ================= CALENDAR POPUP OVERLAY CARD =================
    // Sits at z: 100 directly on root, so it completely overlays backgroundCard and dismiss overlay
    Rectangle {
        id: calendarPopupCard
        z: 100
        visible: root.showCalendar
        opacity: root.showCalendar ? 1 : 0
        x: Math.max(10, root.width - 240 - 16)
        y: 56
        width: 240
        height: calendarColumn.implicitHeight + 20
        radius: Appearance.rounding.normal
        color: Appearance.m3colors.m3surfaceContainerHigh
        border.width: 1
        border.color: Appearance.colors.colOutlineVariant

        Behavior on opacity {
            NumberAnimation { duration: Appearance.animation.elementMoveFast.duration }
        }

        StyledRectangularShadow {
            target: calendarPopupCard
            radius: calendarPopupCard.radius
            blur: Appearance.sizes.elevationMargin * 1.5
        }

        // Catch clicks on card padding so they do not dismiss
        MouseArea {
            anchors.fill: parent
            z: 0
            onClicked: {}
        }

        Column {
            id: calendarColumn
            z: 1
            anchors.centerIn: parent
            spacing: 5
            width: 216

            // Month navigation row
            RowLayout {
                width: parent.width
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    text: `${root.monthShift !== 0 ? "• " : ""}${root.viewingDate.toLocaleDateString(Qt.locale(), "MMM yyyy")}`
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer0
                    elide: Text.ElideRight

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: root.monthShift !== 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (root.monthShift !== 0) {
                                root.monthShift = 0;
                                root.selectedDateString = CalendarLayout.getTodayDateString();
                            }
                        }
                    }
                }

                // Jump to today if shifted
                RippleButton {
                    implicitWidth: 24
                    implicitHeight: 24
                    buttonRadius: Appearance.rounding.verysmall
                    visible: root.monthShift !== 0
                    onClicked: {
                        root.monthShift = 0;
                        root.selectedDateString = CalendarLayout.getTodayDateString();
                    }
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "today"
                        iconSize: 15
                        color: Appearance.colors.colPrimary
                    }
                }

                // Prev month
                RippleButton {
                    implicitWidth: 24
                    implicitHeight: 24
                    buttonRadius: Appearance.rounding.verysmall
                    onClicked: root.monthShift--
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "chevron_left"
                        iconSize: 16
                        color: Appearance.colors.colOnLayer0
                    }
                }

                // Next month
                RippleButton {
                    implicitWidth: 24
                    implicitHeight: 24
                    buttonRadius: Appearance.rounding.verysmall
                    onClicked: root.monthShift++
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "chevron_right"
                        iconSize: 16
                        color: Appearance.colors.colOnLayer0
                    }
                }

                // Close button
                RippleButton {
                    implicitWidth: 24
                    implicitHeight: 24
                    buttonRadius: Appearance.rounding.verysmall
                    onClicked: root.showCalendar = false
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "close"
                        iconSize: 16
                        color: Appearance.colors.colOutlineVariant
                    }
                }
            }

            // Weekday headers
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4

                Repeater {
                    model: CalendarLayout.weekDays
                    delegate: CalendarDayCell {
                        day: Translation.tr(modelData.day)
                        isWeekdayHeader: true
                        isBold: true
                    }
                }
            }

            // 6-Row Calendar Grid
            Repeater {
                model: 6
                delegate: Row {
                    id: weekRow
                    required property int modelData
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4

                    Repeater {
                        model: 7
                        delegate: CalendarDayCell {
                            required property int index
                            readonly property var cellData: root.calendarLayout[weekRow.modelData][index]

                            day: String(cellData.day)
                            dateString: cellData.dateString
                            isToday: cellData.today
                            isSelected: cellData.dateString === root.selectedDateString
                            taskCount: root.getTaskCountForDate(cellData.dateString, Todo.list)
                            isPastWithRemaining: (cellData.dateString < root.todayDateString) && (taskCount > 0)

                            onClicked: {
                                root.selectedDateString = cellData.dateString;
                                root.showCalendar = false;
                            }
                        }
                    }
                }
            }
        }
    }

    // ================= RESIZE HANDLES =================
    component ResizeHandle: MouseArea {
        id: handle
        required property string edge
        property var resizeCursor: {
            if (edge === "top" || edge === "bottom") return Qt.SizeVerCursor;
            if (edge === "left" || edge === "right") return Qt.SizeHorCursor;
            if (edge === "top-left" || edge === "bottom-right") return Qt.SizeFDiagCursor;
            if (edge === "top-right" || edge === "bottom-left") return Qt.SizeBDiagCursor;
            return Qt.ArrowCursor;
        }
        cursorShape: resizeCursor
        hoverEnabled: true
        z: 80
        visible: !root.showCalendar
        enabled: !root.showCalendar

        property real pressGlobalX: 0
        property real pressGlobalY: 0
        property real initialX: 0
        property real initialY: 0
        property real initialWidth: 0
        property real initialHeight: 0

        onPressed: (mouse) => {
            let globalPos = mapToItem(root.parent, mouse.x, mouse.y);
            pressGlobalX = globalPos.x;
            pressGlobalY = globalPos.y;
            initialX = root.x;
            initialY = root.y;
            initialWidth = root.width;
            initialHeight = root.height;
            root.animateXPos = false;
            root.animateYPos = false;
        }

        onPositionChanged: (mouse) => {
            if (!pressed) return;
            let currentGlobal = mapToItem(root.parent, mouse.x, mouse.y);
            let deltaX = currentGlobal.x - pressGlobalX;
            let deltaY = currentGlobal.y - pressGlobalY;

            if (edge.indexOf("right") !== -1) {
                let newW = Math.max(root.minWidth, Math.min(root.maxWidth, initialWidth + deltaX));
                root.width = newW;
            }
            if (edge.indexOf("left") !== -1) {
                let newW = Math.max(root.minWidth, Math.min(root.maxWidth, initialWidth - deltaX));
                let actualDeltaX = initialWidth - newW;
                root.width = newW;
                root.x = initialX + actualDeltaX;
            }
            if (edge.indexOf("bottom") !== -1) {
                let newH = Math.max(root.minHeight, Math.min(root.maxHeight, initialHeight + deltaY));
                root.height = newH;
            }
            if (edge.indexOf("top") !== -1) {
                let newH = Math.max(root.minHeight, Math.min(root.maxHeight, initialHeight - deltaY));
                let actualDeltaY = initialHeight - newH;
                root.height = newH;
                root.y = initialY + actualDeltaY;
            }
        }

        onReleased: {
            root.animateXPos = true;
            root.animateYPos = true;
            root.saveDimensions();
        }
    }

    // Corners
    ResizeHandle {
        edge: "top-left"
        anchors.left: parent.left
        anchors.top: parent.top
        width: 14
        height: 14
    }
    ResizeHandle {
        edge: "top-right"
        anchors.right: parent.right
        anchors.top: parent.top
        width: 14
        height: 14
    }
    ResizeHandle {
        edge: "bottom-left"
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: 14
        height: 14
    }
    ResizeHandle {
        edge: "bottom-right"
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 16
        height: 16
    }

    // Edges
    ResizeHandle {
        edge: "top"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        height: 8
    }
    ResizeHandle {
        edge: "bottom"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        height: 8
    }
    ResizeHandle {
        edge: "left"
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.topMargin: 14
        anchors.bottomMargin: 14
        width: 8
    }
    ResizeHandle {
        edge: "right"
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.topMargin: 14
        anchors.bottomMargin: 14
        width: 8
    }
}
