import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common.functions

RowLayout {
    id: root

    // Pls supply
    required property date date // Any date within the week
    property var locale

    // Expose model and delegate for flexibility
    property list<var> model: {
        // Should expose props like here: https://doc.qt.io/qt-6/qml-qtquick-controls-monthgrid.html#delegate-prop
        // (except weekNumber because i'm lazy and it's not so important)
        const firstDayOfWeek = DateUtils.getFirstDayOfWeek(root.date, root.locale.firstDayOfWeek);
        const weekDates = [];
        for (let i = 0; i < 7; i++) {
            const dayDate = new Date(firstDayOfWeek);
            dayDate.setDate(firstDayOfWeek.getDate() + i);
            weekDates.push({ 
                date: dayDate,
                day: dayDate.getDate(),
                month: dayDate.getMonth() + 1,
                year: dayDate.getFullYear(),
                today: DateUtils.sameDate(dayDate, DateTime.clock.date)
            });
        }
        return weekDates;
    }
    property Component delegate: Text {
        required property var model
        text: model.day
    }

    // Obvious
    Repeater {
        model: root.model
        delegate: root.delegate
    }
}
