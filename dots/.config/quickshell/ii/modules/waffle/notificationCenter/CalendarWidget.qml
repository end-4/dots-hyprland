pragma ComponentBehavior: Bound
import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.waffle.looks

BodyRectangle {
    id: root

    // State
    property bool collapsed

    // Locale
    property var locale: Qt.locale(Config.options.calendar.locale)

    implicitHeight: collapsed ? 0 : contentColumn.implicitHeight
    implicitWidth: contentColumn.implicitWidth

    Behavior on implicitHeight {
        animation: Looks.transition.enter.createObject(this)
    }

    clip: true
    ColumnLayout {
        id: contentColumn
        spacing: 12
        CalendarHeader {
            Layout.topMargin: 10
            Layout.fillWidth: true
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 5
            Layout.rightMargin: 5
            spacing: 1
            DayOfWeekRow {
                Layout.fillWidth: true
                locale: root.locale
                spacing: calendarView.buttonSpacing
                implicitHeight: calendarView.buttonSize
                delegate: Item {
                    id: dayOfWeekItem
                    required property var model
                    implicitHeight: calendarView.buttonSize
                    implicitWidth: calendarView.buttonSize
                    WText {
                        anchors.centerIn: parent
                        text: {
                            var result = dayOfWeekItem.model.shortName;
                            if (Config.options.waffles.calendar.force2CharDayOfWeek) result = result.substring(0,2);
                            return result;
                        }
                        color: Looks.colors.fg
                        font.pixelSize: Looks.font.pixelSize.large
                    }
                }
            }
            CalendarView {
                id: calendarView
                locale: root.locale
                verticalPadding: 2
                buttonSize: 41 // ???
                buttonSpacing: 6
                buttonVerticalSpacing: 1
                Layout.fillWidth: true
                delegate: DayButton {}
            }
        }
    }

    component DayButton: WButton {
        id: dayButton
        required property var model
        checked: model.today
        enabled: hovered || calendarView.scrolling || checked || model.month === calendarView.focusedMonth
        implicitWidth: calendarView.buttonSize
        implicitHeight: calendarView.buttonSize
        radius: height / 2

        required property int index

        contentItem: Item {
            WText {
                anchors.centerIn: parent
                text: dayButton.model.day
                color: dayButton.fgColor
                font.pixelSize: Looks.font.pixelSize.larger
            }
        }
    }

    component CalendarHeader: RowLayout {
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        spacing: 8

        WBorderlessButton {
            Layout.fillWidth: true
            implicitHeight: 34
            contentItem: Item {
                WText {
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignLeft
                    text: Qt.locale().toString(calendarView.focusedDate, "MMMM yyyy")
                    font.pixelSize: Looks.font.pixelSize.large
                    font.weight: Looks.font.weight.strong
                }
            }
        }
        ScrollMonthButton {
            scrollDown: false
        }
        ScrollMonthButton {
            scrollDown: true
        }
    }

    component ScrollMonthButton: WBorderlessButton {
        id: scrollMonthButton
        required property bool scrollDown
        Layout.alignment: Qt.AlignVCenter

        onClicked: {
            calendarView.scrollMonthsAndSnap(scrollDown ? 1 : -1);
        }
        implicitWidth: 32
        implicitHeight: 34

        contentItem: FluentIcon {
            filled: true
            implicitSize: 12
            icon: scrollMonthButton.scrollDown ? "caret-down" : "caret-up"
        }
    }
}
