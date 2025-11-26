pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

// TODO: The overlaps are crazy, but the positioning approach works.
//       This could work well if we do it week by week instead of month by month.
BodyRectangle {
    id: root

    // State
    property bool collapsed

    // Sizes
    property int _rowsPerMonth: 6
    property real viewHeight: (_rowsPerMonth * buttonSize) + ((_rowsPerMonth - 1) * buttonSpacing)
    property real buttonSize: 40
    property real buttonSpacing: 2
    property real spacePerExtraRow: buttonSize + buttonSpacing

    implicitWidth: currentMonthGrid.implicitWidth
    implicitHeight: collapsed ? 0 : viewHeight
    opacity: implicitHeight > 0 ? 1 : 0

    Behavior on implicitHeight {
        animation: Looks.transition.enter.createObject(this)
    }

    // Month stuff
    property real targetMonthDiff: 0
    property real monthDiff: targetMonthDiff
    property int focusedMonthDiff: monthDiff // whole part of monthDiff
    property int currentMonth: DateTime.clock.date.getMonth() + 1 // 0-indexed -> 1-indexed
    property int currentYear: DateTime.clock.date.getFullYear()

    clip: true
    property list<DiffMonthGrid> monthGrids: [previousPreviousMonthGrid, previousMonthGrid, currentMonthGrid, nextMonthGrid, nextNextMonthGrid]
    ColumnLayout {
        spacing: 0
        y: {
            const origin = - currentMonthGrid.y;
            const diff = root.monthDiff * root.viewHeight;
            return origin + (-diff % root.viewHeight);
        }
        DiffMonthGrid {
            id: previousPreviousMonthGrid
            monthDiff: root.focusedMonthDiff - 2
        }
        DiffMonthGrid {
            id: previousMonthGrid
            monthDiff: root.focusedMonthDiff - 1
        }
        DiffMonthGrid {
            id: currentMonthGrid
            monthDiff: root.focusedMonthDiff
        }
        DiffMonthGrid {
            id: nextMonthGrid
            monthDiff: root.focusedMonthDiff + 1
        }
        DiffMonthGrid {
            id: nextNextMonthGrid
            monthDiff: root.focusedMonthDiff + 2
        }
    }

    MouseArea {
        anchors.fill: parent
        onWheel: wheel => {
            root.targetMonthDiff += wheel.angleDelta.y / 120 * -0.333333; // Reverse cuz scrolling down should advance
        }
    }

    Behavior on monthDiff {
        animation: Looks.transition.enter.createObject(this)
    }

    component DiffMonthGrid: MonthGrid {
        id: monthGrid
        required property int monthDiff
        property int index: root.monthGrids.indexOf(this)
        month: ((root.currentMonth - 1) + monthDiff) % 12 // 1-indexed -> 0-indexed
        year: root.currentYear + Math.floor((root.currentMonth - 1 + monthDiff) / 12)

        spacing: root.buttonSpacing
        // background: Rectangle {
        //     color: Qt.rgba(Math.abs(Math.sin(month * 12.9898)) % 1, Math.abs(Math.sin(month * 78.233)) % 1, Math.abs(Math.sin(month * 45.164)) % 1, 1)
        // }
        delegate: MonthDayButton {}
    }

    component MonthDayButton: WButton {
        id: monthDayButton
        required property var model
        opacity: model.month == parent.parent.month || model.today ? 1 : 0
        checked: model.today
        implicitWidth: root.buttonSize
        implicitHeight: root.buttonSize
        radius: height / 2

        required property int index

        contentItem: Item {
            WText {
                anchors.centerIn: parent
                text: monthDayButton.model.day
                color: {
                    if (monthDayButton.model.today)
                        return Looks.colors.accentFg;
                    if (monthDayButton.model.month == root.currentMonth - 1)
                        return Looks.colors.fg;
                    return Looks.colors.subfg;
                }
                font.pixelSize: Looks.font.pixelSize.large
            }
        }
    }
}
