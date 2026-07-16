import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

RippleButton {
    id: root

    property bool vertical: false
    property bool recording: false
    property bool stopped: false
    property int elapsedSeconds: 0

    readonly property color stateColor: Appearance.colors.colErrorContainer
    readonly property color stateColorHover: Appearance.colors.colErrorContainerHover
    readonly property color stateColorActive: Appearance.colors.colErrorContainerActive
    readonly property color stateTextColor: Appearance.colors.colOnErrorContainer

    // Size changes instantly when visible changes
    implicitWidth: visible ? (vertical ? Appearance.sizes.verticalBarWidth - 10 : 104) : 0
    implicitHeight: visible ? (vertical ? 70 : Appearance.sizes.baseBarHeight - 8) : 0

    buttonRadius: Appearance.rounding.full
    toggled: root.recording
    colBackground: stateColor
    colBackgroundHover: stateColorHover
    colRipple: stateColorActive
    colBackgroundToggled: stateColor
    colBackgroundToggledHover: stateColorHover
    colRippleToggled: stateColorActive

    // Robust State Machine for show/hide transitions
    states: [
        State {
            name: "hidden"
            when: !root.recording
            PropertyChanges {
                target: root
                scale: 0.0
                visible: false
            }
        },
        State {
            name: "shown"
            when: root.recording
            PropertyChanges {
                target: root
                scale: 1.0
                visible: true
            }
        }
    ]

    transitions: [
        Transition {
            from: "hidden"
            to: "shown"
            SequentialAnimation {
                PropertyAction { target: root; property: "visible"; value: true }
                NumberAnimation {
                    target: root
                    property: "scale"
                    duration: 350
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.5
                }
            }
        },
        Transition {
            from: "shown"
            to: "hidden"
            SequentialAnimation {
                NumberAnimation {
                    target: root
                    property: "scale"
                    duration: 350
                    easing.type: Easing.InBack
                    easing.overshoot: 1.5
                }
                PropertyAction { target: root; property: "visible"; value: false }
            }
        }
    ]

    // Smooth local timer — ticks every second regardless of process latency
    Timer {
        id: elapsedTimer
        interval: 1000
        running: root.recording && !root.stopped
        repeat: true
        onTriggered: root.elapsedSeconds += 1
    }

    // Poll wf-recorder for start/stop detection
    Timer {
        id: pollTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: checkRecordingProc.running = true
    }

    Process {
        id: checkRecordingProc
        command: ["bash", "-c", "pid=$(pidof wf-recorder 2>/dev/null); if [ -n \"$pid\" ]; then echo \"1 $(ps -o etimes= -p $pid 2>/dev/null | tr -d ' ')\"; else echo 0; fi"]
        stdout: StdioCollector {
            id: recordingOutput
            onStreamFinished: {
                // Ignore polls during user-initiated stop (prevents re-trigger)
                if (root.stopped) return;

                const parts = recordingOutput.text.trim().split(/\s+/);
                const isRec = (parts[0] === "1");
                const wasRecording = root.recording;
                root.recording = isRec;
                if (isRec && !wasRecording) {
                    // Sync elapsed from OS only on recording start
                    root.elapsedSeconds = parseInt(parts[1]) || 0;
                }
            }
        }
    }

    // Reset after exit animation finishes
    onVisibleChanged: {
        if (!visible) {
            elapsedSeconds = 0;
            stopped = false;
        }
    }

    function displayText() {
        if (root.stopped) return "Stop";
        const minutes = Math.floor(root.elapsedSeconds / 60).toString().padStart(2, "0");
        const seconds = Math.floor(root.elapsedSeconds % 60).toString().padStart(2, "0");
        return `${minutes}:${seconds}`;
    }

    function verticalMinutes() {
        if (root.stopped) return "St";
        return Math.floor(root.elapsedSeconds / 60).toString().padStart(2, "0");
    }

    function verticalSeconds() {
        if (root.stopped) return "op";
        return Math.floor(root.elapsedSeconds % 60).toString().padStart(2, "0");
    }

    onClicked: {
        root.stopped = true;
        root.recording = false;
        Quickshell.execDetached(["bash", "-c", "kill -INT $(pidof wf-recorder)"]);
    }

    contentItem: Item {
        anchors.fill: parent

        // Horizontal layout
        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            visible: !root.vertical
            spacing: 5

            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                text: root.hovered ? "stop_circle" : "screen_record"
                iconSize: Appearance.font.pixelSize.larger
                color: root.stateTextColor

                // Morph / Hover animation: spin and scale slightly
                scale: root.hovered ? 1.15 : 1.0
                rotation: root.hovered ? 180 : 0

                Behavior on scale {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutBack
                    }
                }

                Behavior on rotation {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 48
                horizontalAlignment: Text.AlignHCenter
                topPadding: 2
                bottomPadding: -2
                text: root.displayText()
                font.family: Appearance.font.family.main
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.DemiBold
                color: root.stateTextColor
            }
        }

        // Vertical layout
        ColumnLayout {
            anchors.centerIn: parent
            visible: root.vertical
            spacing: 1

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: root.hovered ? "stop_circle" : "screen_record"
                iconSize: 18
                color: root.stateTextColor

                // Morph / Hover animation: spin and scale slightly
                scale: root.hovered ? 1.15 : 1.0
                rotation: root.hovered ? 180 : 0

                Behavior on scale {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutBack
                    }
                }

                Behavior on rotation {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.verticalMinutes()
                font.family: Appearance.font.family.main
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: root.stateTextColor
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.verticalSeconds()
                font.family: Appearance.font.family.main
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: root.stateTextColor
            }
        }
    }
}
