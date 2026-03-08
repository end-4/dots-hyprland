pragma ComponentBehavior: Bound
import QtQuick

/**
 * Replacement for QtQuick Controls DayOfWeek row.
 * I have to do this because that one is somehow really unreliable in my dynamically loaded widget
 */
Row {
    id: root
    property Component delegate
    property alias model: repeater.model

    property var locale: Qt.locale()
    readonly property var firstDayOfWeek: locale.firstDayOfWeek

    Repeater {
        id: repeater
        model: Array.from({
            length: 7
        }, (_, i) => {
            const day = (root.firstDayOfWeek + i + 7 - 1) % 7 + 1
            return ({
                // Convert Locale day of week enum values to that of Qt enum values for
                // consistency with DayOfWeekRow. Note that Locale day of week enum values are 0-indexed,
                // while Qt day of week enum values are 1-indexed.
                // Refererences:
                // Locale enum values: https://doc.qt.io/qt-6/qml-qtqml-locale.html#firstDayOfWeek-prop
                // DayOfWeek model values: https://doc.qt.io/qt-6/qml-qtquick-controls-dayofweekrow.html#delegate-prop
                // which mentions the enum values in the Qt namespace at: https://doc.qt.io/qt-6/qt.html#DayOfWeek-enum
                day: day,
                shortName: root.locale.toString(new Date(2024, 0, day), "ddd")
            })
        })
        delegate: root.delegate
    }
}
