import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    property string time: Qt.formatDateTime(clock.date, "hh:mm")
    property string date: Qt.formatDateTime(clock.date, "dddd, dd/MM")

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

}
