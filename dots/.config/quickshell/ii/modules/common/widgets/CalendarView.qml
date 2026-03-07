pragma ComponentBehavior: Bound
import QtQml
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    // Expose delegate
    property Component delegate: Text {
        required property var model
        text: model.day
    }

    // Configuration
    property int paddingWeeks: 2 // 1 should be sufficient with proper clipping and no padding
    property var locale: Qt.locale() // Should be of type Locale but QML is being funny

    // Scrolling
    function scrollMonthsAndSnap(x) { // Scroll x months and snap to month
        const focusedDate = root.focusedDate;
        const focusedMonth = focusedDate.getMonth();
        const focusedYear = focusedDate.getFullYear();
        const targetMonth = focusedMonth + x;
        const targetDate = new Date(focusedYear, targetMonth, 1);
        const currentFirstShownDate = new Date(root.dateInFirstWeek.getTime() + (root.paddingWeeks * root.millisPerWeek));
        const diffMillis = targetDate.getTime() - currentFirstShownDate.getTime();
        const diffWeeks = Math.round(diffMillis / root.millisPerWeek);
        root.targetWeekDiff += diffWeeks;
    }
    function scrollToToday() {
        root.targetWeekDiff = 0;
    }
    property int weeksPerScroll: 1
    property real targetWeekDiff: 0
    property real weekDiff: targetWeekDiff
    property int contentWeekDiff: weekDiff // whole part of weekDiff
    property bool scrolling: false

    property Animation scrollAnimation: NumberAnimation {
        duration: Config.options.calendar.animate ? Appearance.animation.scroll.duration : 0
        easing.type: Appearance.animation.scroll.type
        easing.bezierCurve: Appearance.animation.scroll.bezierCurve
    }
    Behavior on weekDiff {
        id: weekScrollBehavior
        animation: root.scrollAnimation
    }
    Timer {
        id: scrollAnimationCheckTimer
        interval: 30 // Should be plenty for 60fps
        onTriggered: root.scrolling = false;
    }
    onWeekDiffChanged: {
        scrolling = true;
        scrollAnimationCheckTimer.restart();
    }

    property var wheelAction: (wheel) => {
        // Reverse cuz scrolling down should advance
        const sign = wheel.angleDelta.y / 120 * -1;
        if (Config.options.calendar.weekScrollPrecision) {
            root.targetWeekDiff += sign * root.weeksPerScroll;
        } else {
            scrollMonthsAndSnap(sign);
        }
    }
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onWheel: (wheel) => root.wheelAction(wheel)
    }

    // Date calculations
    readonly property int millisPerWeek: 7 * 24 * 60 * 60 * 1000
    readonly property int totalWeeks: 6 + (paddingWeeks * 2)
    readonly property int focusedWeekIndex: 2 // The third row, 0-indexed
    readonly property int focusDayOfWeekIndex: 6
    property date dateInFirstWeek: {
        const currentDate = new Date();
        const currentMonth = currentDate.getMonth();
        const currentYear = currentDate.getFullYear();
        const firstDayThisMonth = new Date(currentYear, currentMonth, 1);
        return new Date(firstDayThisMonth.getTime() - (paddingWeeks * millisPerWeek) + contentWeekDiff * millisPerWeek);
    }
    property date focusedDate: {
        // The last day of 3rd week shown is considered the focused month
        const addedTime = (root.paddingWeeks + root.focusedWeekIndex) * root.millisPerWeek
        const dateInTargetWeek = new Date(root.dateInFirstWeek.getTime() + addedTime);
        return DateUtils.getIthDayDateOfSameWeek(dateInTargetWeek, root.focusDayOfWeekIndex - root.locale.firstDayOfWeek, root.locale.firstdayOfWeek); // 4 = Thursday
    }
    property int focusedMonth: focusedDate.getMonth() + 1 // 0-indexed -> 1-indexed
    property string title: locale.toString(focusedDate, "MMMM yyyy")

    // Sizes
    property real verticalPadding: 0
    property real horizontalPadding: 0
    property real buttonSize: 40
    property real buttonSpacing: 2
    property real buttonVerticalSpacing: buttonSpacing
    implicitHeight: (6 * buttonSize) + (5 * buttonVerticalSpacing) + (2 * verticalPadding)
    implicitWidth: weeksColumn.implicitWidth + (2 * horizontalPadding)
    clip: true
    
    ColumnLayout {
        id: weeksColumn
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }
        y: {
            const spacePerExtraRow = root.buttonSize + root.buttonVerticalSpacing;
            const origin = -(spacePerExtraRow * root.paddingWeeks);
            const diff = root.weekDiff * spacePerExtraRow;
            return origin + (-diff % spacePerExtraRow) + root.verticalPadding;
        }

        spacing: root.buttonVerticalSpacing
        
        Repeater {
            model: root.totalWeeks

            WeekRow {
                required property int index
                locale: root.locale
                date: new Date(root.dateInFirstWeek.getTime() + (index * root.millisPerWeek))
                Layout.fillWidth: true
                spacing: root.buttonSpacing
                delegate: root.delegate
            }
        }
    }
}
