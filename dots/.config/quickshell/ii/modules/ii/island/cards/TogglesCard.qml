import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.island

// Long-press the island: quick toggles without opening a sidebar.
RowLayout {
    id: root
    signal done()
    spacing: 8
    width: 352

    component Toggle: Rectangle {
        id: t
        property string icon: ""
        property string label: ""
        property bool on: false
        signal activated()
        Layout.fillWidth: true
        implicitHeight: 62
        radius: 18
        color: on ? Appearance.colors.colPrimary : (area.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2)
        Behavior on color { ColorAnimation { duration: 180 } }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2
            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: t.icon
                iconSize: 22
                fill: t.on ? 1 : 0
                color: t.on ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: t.label
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: t.on ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
            }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: t.activated()
        }
    }

    Toggle {
        icon: Notifications.silent ? "notifications_off" : "notifications"
        label: Translation.tr("Silent")
        on: Notifications.silent
        onActivated: Notifications.silent = !Notifications.silent
    }
    Toggle {
        icon: (Audio.source?.audio?.muted ?? false) ? "mic_off" : "mic"
        label: Translation.tr("Mic")
        on: !(Audio.source?.audio?.muted ?? true)
        onActivated: Audio.toggleMicMute()
    }
    Toggle {
        icon: "bedtime"
        label: Translation.tr("Night")
        on: Hyprsunset.temperatureActive
        onActivated: Hyprsunset.toggleTemperature()
    }
    Toggle {
        icon: "timer"
        label: TimerService.pomodoroRunning ? Translation.tr("Stop") : Translation.tr("Focus")
        on: TimerService.pomodoroRunning
        onActivated: TimerService.togglePomodoro()
    }
    Toggle {
        icon: "graphic_eq"
        label: Translation.tr("What's on?")
        onActivated: {
            IslandState.songRecognitionRequested();
            root.done();
        }
    }
}
