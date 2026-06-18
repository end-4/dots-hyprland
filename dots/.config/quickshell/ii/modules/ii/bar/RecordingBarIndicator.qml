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
    property int elapsedSeconds: 0

    readonly property color stateColor: Appearance.colors.colErrorContainer
    readonly property color stateColorHover: Appearance.colors.colErrorContainerHover
    readonly property color stateColorActive: Appearance.colors.colErrorContainerActive
    readonly property color stateTextColor: Appearance.colors.colOnErrorContainer

    // Size changes instantly when visible changes
    implicitWidth: visible ? (vertical ? Appearance.sizes.verticalBarWidth - 10 : 104) : 0
    implicitHeight: visible ? (vertical ? 54 : Appearance.sizes.baseBarHeight - 8) : 0

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

    // Poll wf-recorder process existence
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
        command: ["pidof", "wf-recorder"]
        onExited: (exitCode, exitStatus) => {
            const wasRecording = root.recording;
            root.recording = (exitCode === 0);
            if (root.recording && !wasRecording) {
                root.elapsedSeconds = 0;
            }
        }
    }

    // Elapsed time counter
    Timer {
        id: elapsedTimer
        interval: 1000
        running: root.recording
        repeat: true
        onTriggered: root.elapsedSeconds += 1
    }

    function recordingTimeText() {
        const minutes = Math.floor(root.elapsedSeconds / 60).toString().padStart(2, "0");
        const seconds = Math.floor(root.elapsedSeconds % 60).toString().padStart(2, "0");
        return `${minutes}:${seconds}`;
    }

    function compactMinutesText() {
        return Math.ceil(root.elapsedSeconds / 60).toString().padStart(2, "0");
    }

    onClicked: {
        // Stop recording
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
                text: root.recordingTimeText()
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
                text: root.compactMinutesText()
                font.family: Appearance.font.family.main
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: root.stateTextColor
            }
        }
    }

    StyledToolTip {
        text: Translation.tr("Recording")
    }
}
