import "root:/modules/common"
import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

/**
 * A nice wrapper for date and time strings.
 */
Singleton {
    property string time: Qt.formatDateTime(clock.date, ConfigOptions?.time.format ?? "hh:mm")
    property string date: Qt.formatDateTime(clock.date, ConfigOptions?.time.dateFormat ?? "dddd, dd/MM")
    property string collapsedCalendarFormat: Qt.formatDateTime(clock.date, "dd MMMM yyyy")
    property string uptime: "0h, 0m"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Timer {
        interval: 10
        running: true
        repeat: true
        onTriggered: {
            fileUptime.reload()
            const textUptime = fileUptime.text()
            const uptimeSeconds = Number(textUptime.split(" ")[0] ?? 0)

            // Convert seconds to days, hours, and minutes
            const days = Math.floor(uptimeSeconds / 86400)
            const hours = Math.floor((uptimeSeconds % 86400) / 3600)
            const minutes = Math.floor((uptimeSeconds % 3600) / 60)

            // Build the formatted uptime string
            let formatted = ""
            if (days > 0) formatted += `${days}d`
            if (hours > 0) formatted += `${formatted ? ", " : ""}${hours}h`
            if (minutes > 0 || !formatted) formatted += `${formatted ? ", " : ""}${minutes}m`
            uptime = formatted
            interval = ConfigOptions?.resources?.updateInterval ?? 3000
        }
    }

    FileView {
        id: fileUptime

        path: "/proc/uptime"
    }

}
