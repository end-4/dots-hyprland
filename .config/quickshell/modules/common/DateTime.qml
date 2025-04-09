import QtQuick
import Quickshell
import Quickshell.Io
// with this line our type becomes a singleton
pragma Singleton

// your singletons should always have Singleton as the type
Singleton {
    property string time: Qt.formatDateTime(clock.date, "hh:mm")
    // something like Wednesday, 09/04
    property string date:  Qt.formatDateTime(clock.date, "dddd, dd/MM")

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

}
