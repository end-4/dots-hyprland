import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * Date & Time settings — format strings, pomodoro timer, locale.
 */
ContentPage {
    forceWidth: true

    ContentSection {
        icon: "schedule"
        title: Translation.tr("Time Format")

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Time format (Qt format, e.g. hh:mm)")
            text: Config.options.time.format
            onTextChanged: { Qt.callLater(() => { Config.options.time.format = text }) }
        }

        ConfigSwitch {
            buttonIcon: "timer"
            text: Translation.tr("Second precision (update every second)")
            checked: Config.options.time.secondPrecision
            onCheckedChanged: { Config.options.time.secondPrecision = checked }
        }
    }

    ContentSection {
        icon: "calendar_month"
        title: Translation.tr("Date Format")

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Short date format (e.g. dd/MM)")
            text: Config.options.time.shortDateFormat
            onTextChanged: { Qt.callLater(() => { Config.options.time.shortDateFormat = text }) }
        }
        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Full date format (e.g. ddd, dd/MM)")
            text: Config.options.time.dateFormat
            onTextChanged: { Qt.callLater(() => { Config.options.time.dateFormat = text }) }
        }
        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Calendar locale (e.g. en-GB)")
            text: Config.options.calendar.locale
            onTextChanged: { Qt.callLater(() => { Config.options.calendar.locale = text }) }
        }
    }

    ContentSection {
        icon: "hourglass_empty"
        title: Translation.tr("Pomodoro Timer")

        ConfigSpinBox {
            icon: "target"
            text: Translation.tr("Focus duration (seconds)")
            value: Config.options.time.pomodoro.focus
            from: 60; to: 7200; stepSize: 60
            onValueChanged: { Config.options.time.pomodoro.focus = value }
        }
        ConfigSpinBox {
            icon: "free_cancellation"
            text: Translation.tr("Break duration (seconds)")
            value: Config.options.time.pomodoro.breakTime
            from: 30; to: 1800; stepSize: 30
            onValueChanged: { Config.options.time.pomodoro.breakTime = value }
        }
        ConfigSpinBox {
            icon: "coffee"
            text: Translation.tr("Long break (seconds)")
            value: Config.options.time.pomodoro.longBreak
            from: 60; to: 3600; stepSize: 60
            onValueChanged: { Config.options.time.pomodoro.longBreak = value }
        }
        ConfigSpinBox {
            icon: "loop"
            text: Translation.tr("Cycles before long break")
            value: Config.options.time.pomodoro.cyclesBeforeLongBreak
            from: 1; to: 10; stepSize: 1
            onValueChanged: { Config.options.time.pomodoro.cyclesBeforeLongBreak = value }
        }
    }
}
