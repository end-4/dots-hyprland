import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import "events.js" as EventData
import Quickshell.Io

Item {
    id: root
    property real spacing: 12
    property color backgroundColor: "transparent"
    property var timeSlots: ["7:30 AM", "8:00 AM", "8:30 AM", "9:00 AM", "9:30 AM", "10:00 AM", "10:30 AM", "11:00 AM", "11:30 AM", "12:00 PM", "12:30 PM", "1:00 PM", "1:30 PM", "2:00 PM", "2:30 PM", "3:00 PM", "3:30 PM", "4:00 PM", "4:30 PM", "5:00 PM", "5:30 PM", "6:00 PM", "6:30 PM", "7:00 PM"]

    property real maxHeight: 600
    property real headerHeight: 50
    property string currentTime: ""
    property real currentTimeY: -1

    implicitWidth: Math.max(headerRow.implicitWidth, eventsArea.implicitWidth)
    implicitHeight: Math.max(headerHeight + eventsArea.implicitHeight + 630, maxHeight)
    property var days: EventData.days

    Process {
        id: timeProcess
        command: ["date", "+%H:%M"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.currentTime = this.text.trim();
                root.updateCurrentTimeLine();
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: timeProcess.running = true
    }

    function updateCurrentTimeLine() {
        if (!currentTime)
            return;

        let parts = currentTime.split(" ");
        let timePart = parts[0];
        let period = parts[1];

        let timeParts = timePart.split(":");
        let hours = parseInt(timeParts[0]);
        let minutes = parseInt(timeParts[1]);

        if (period === "PM" && hours !== 12) {
            hours += 12;
        } else if (period === "AM" && hours === 12) {
            hours = 0;
        }

        let baseHour = 7;
        let baseMinute = 30;
        let currentMinutes = hours * 60 + minutes;
        let baseMinutes = baseHour * 60 + baseMinute;
        let diffMinutes = currentMinutes - baseMinutes;

        currentTimeY = (diffMinutes / 30) * 50;
    }

    function formatCurrentTime() {
        if (!currentTime)
            return "";

        let timeParts = currentTime.split(":");
        let hours = parseInt(timeParts[0]);
        let minutes = timeParts[1];

        let period = hours >= 12 ? "PM" : "AM";
        hours = hours % 12;
        hours = hours === 0 ? 12 : hours;

        return hours + ":" + minutes + " " + period;
    }

    Rectangle {
        anchors.fill: parent
        color: root.backgroundColor

        Column {
            anchors.fill: parent
            spacing: root.spacing

            Row {
                id: headerRow
                spacing: root.spacing

                Repeater {
                    model: root.days
                    delegate: Rectangle {
                        width: 150
                        height: root.headerHeight
                        color: "transparent"
                        StyledText {
                            id: sectionTitle
                            anchors.centerIn: parent
                            font.family: Appearance.font.family.title
                            font.pixelSize: Appearance.font.pixelSize.huge
                            color: Appearance.colors.colPrimary
                            text: modelData.name
                        }
                    }
                }
            }

            Item {
                id: eventsArea
                width: parent.width
                height: parent.height - root.headerHeight - root.spacing

                Flickable {
                    id: flickable
                    anchors.fill: parent

                    clip: true
                    contentWidth: eventsRow.implicitWidth
                    contentHeight: eventsRow.implicitHeight

                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: eventsRow
                        spacing: root.spacing

                        Repeater {
                            model: root.days
                            delegate: Item {
                                width: 150
                                height: root.timeSlots.length * 50

                                // Events
                                Repeater {
                                    model: modelData.events
                                    Rectangle {
                                        radius: 8
                                        width: parent.width - 10
                                        y: {
                                            let startHr = parseInt(modelData.start.split(":")[0]);
                                            let startMin = parseInt(modelData.start.split(":")[1]);
                                            let baseHr = 7;
                                            let baseMin = 30;
                                            let diffMins = (startHr * 60 + startMin) - (baseHr * 60 + baseMin);
                                            return (diffMins / 30) * 50;
                                        }
                                        height: {
                                            let startHr = parseInt(modelData.start.split(":")[0]);
                                            let endHr = parseInt(modelData.end.split(":")[0]);
                                            let startMin = parseInt(modelData.start.split(":")[1]);
                                            let endMin = parseInt(modelData.end.split(":")[1]);
                                            let totalMins = (endHr * 60 + endMin) - (startHr * 60 + startMin);
                                            return totalMins > 0 ? (totalMins / 30) * 48 : 50;
                                        }

                                        gradient: Gradient {
                                            GradientStop {
                                                position: 0.0
                                                color: Qt.lighter(modelData.color, 1.5)
                                            }
                                            GradientStop {
                                                position: 1.0
                                                color: modelData.color
                                            }
                                        }

                                        border.color: Qt.darker(modelData.color, 1.3)
                                        border.width: 1
                                        layer.enabled: true
                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 8

                                            // Time row
                                            Text {
                                                text: {
                                                    let startHr = parseInt(modelData.start.split(":")[0]);
                                                    let startMin = modelData.start.split(":")[1];
                                                    let endHr = parseInt(modelData.end.split(":")[0]);
                                                    let endMin = modelData.end.split(":")[1];

                                                    let formatTime = (hour, minute) => {
                                                        let period = hour >= 12 ? "PM" : "AM";
                                                        hour = hour % 12;
                                                        hour = hour === 0 ? 12 : hour;
                                                        return hour + ":" + minute + " " + period;
                                                    };

                                                    return formatTime(startHr, startMin) + " - " + formatTime(endHr, endMin);
                                                }
                                                font.pointSize: 9
                                                color: "#222"
                                                Layout.fillWidth: true
                                                wrapMode: Text.WordWrap
                                            }

                                            // Divider line
                                            Rectangle {
                                                Layout.preferredHeight: 1
                                                Layout.fillWidth: true
                                                color: Qt.darker(modelData.color, 1.4)
                                            }

                                            // Event title
                                            Text {
                                                text: modelData.title
                                                font.pointSize: 10
                                                font.weight: Font.Medium
                                                wrapMode: Text.WordWrap
                                                Layout.fillWidth: true
                                                color: "#111"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: currentTimeLine
                        width: eventsRow.width
                        height: 3
                        color: Appearance.colors.colPrimary
                        y: root.currentTimeY
                        visible: root.currentTimeY >= 0 && root.currentTimeY <= eventsRow.height && root.currentTime !== ""
                        z: -1

                        Rectangle {
                            anchors.right: parent.right
                            anchors.bottom: parent.top
                            anchors.rightMargin: 14
                            anchors.bottomMargin: 5
                            width: timeText.width + 12
                            height: 24
                            color: "transparent"
                            z: 100

                            Text {
                                id: timeText
                                anchors.centerIn: parent
                                text: root.formatCurrentTime()
                                color: Appearance.colors.colPrimary
                                font.pixelSize: 20
                                font.bold: true
                            }
                        }
                    }
                }

                Rectangle {
                    id: scrollIndicator
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 2
                    width: 4
                    color: "transparent"
                    radius: 2
                    visible: flickable.contentHeight > flickable.height

                    Rectangle {
                        width: parent.width
                        height: Math.max(20, (flickable.height / flickable.contentHeight) * parent.height)
                        y: flickable.contentHeight > flickable.height ? (flickable.contentY / (flickable.contentHeight - flickable.height)) * (parent.height - height) : 0
                        color: Appearance.colors.colPrimary
                        radius: 2
                    }
                }
            }
        }
    }
}
