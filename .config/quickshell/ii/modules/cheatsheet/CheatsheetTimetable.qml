import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Material

Item {
    id: root
    property real spacing: 8
    property color backgroundColor: "transparent"

    property int startHour: 0
    property int startMinute: 0
    property int endHour: 24
    property int slotDuration: 60 // in minutes
    property int slotHeight: 60 // in pixels
    property int timeColumnWidth: 100
    property real maxContentWidth: 1200

    readonly property int totalSlots: Math.floor(((endHour * 60) - (startHour * 60 + startMinute)) / slotDuration)
    readonly property real pixelsPerMinute: slotHeight / slotDuration
    readonly property int contentHeight: totalSlots * slotHeight

    property real maxHeight: 700
    property real headerHeight: 64 // Material 3 standard header height
    property real currentTimeY: -1
    readonly property real dayColumnWidth: Math.min(180, (maxContentWidth - timeColumnWidth - (days.length + 1) * spacing) / days.length)

    implicitWidth: Math.min(maxContentWidth, timeColumnWidth + (dayColumnWidth * days.length) + ((days.length + 1) * spacing))
    implicitHeight: Math.min(headerHeight + contentHeight, maxHeight)
    property var days: CalendarService.eventsInWeek

    function updateCurrentTimeLine() {
        let time = DateTime.clock.date;
        let hours = time.getHours();
        let minutes = time.getMinutes();

        let baseTotalMinutes = root.startHour * 60 + root.startMinute;
        let currentTotalMinutes = hours * 60 + minutes;
        let diffMinutes = currentTotalMinutes - baseTotalMinutes;

        currentTimeY = diffMinutes * root.pixelsPerMinute;
    }

    //TODO: add to color util later
    function getContrastingTextColor(bgColor) {
        if (!bgColor)
            return Appearance.colors.colOnSurface;

        let color = Qt.color(bgColor);
        // Calculate relative luminance using WCAG formula
        let r = color.r <= 0.03928 ? color.r / 12.92 : Math.pow((color.r + 0.055) / 1.055, 2.4);
        let g = color.g <= 0.03928 ? color.g / 12.92 : Math.pow((color.g + 0.055) / 1.055, 2.4);
        let b = color.b <= 0.03928 ? color.b / 12.92 : Math.pow((color.b + 0.055) / 1.055, 2.4);
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b;

        // Return high contrast color
        return luminance < 0.5 ? "#FFFFFF" : "#000000";
    }

    Connections {
        target: DateTime.clock
        function onDateChanged() {
            root.updateCurrentTimeLine();
        }
    }

    Component.onCompleted: {
        root.updateCurrentTimeLine();
    }

    // Material 3 surface container
    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colSurfaceContainer
        radius: Appearance.rounding.large
        border.width: 1
        border.color: Appearance.colors.colOutlineVariant
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Row {
            id: headerRow
            Layout.fillWidth: true
            Layout.preferredHeight: root.headerHeight
            spacing: root.spacing

            Item {
                width: root.timeColumnWidth
                height: root.headerHeight

                // Current time indicator
                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(timeHeaderText.implicitWidth + 16, parent.width - 4)
                    height: 32
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colSecondaryContainer

                    StyledText {
                        id: timeHeaderText
                        anchors.centerIn: parent
                        text: DateTime.time
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnSecondaryContainer
                        elide: Text.ElideRight
                    }
                }
            }

            Repeater {
                model: root.days
                delegate: Item {
                    width: root.dayColumnWidth
                    height: root.headerHeight

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 4
                        height: 40
                        radius: Appearance.rounding.large
                        color: Appearance.colors.colPrimaryContainer

                        StyledText {
                            id: dayTitle
                            anchors.centerIn: parent
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnPrimaryContainer
                            text: modelData.name
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        // Subtle separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Appearance.colors.colOutlineVariant
            Layout.bottomMargin: 8
        }

        // TODO: replace or check for StyledScrollBar
        StyledFlickable {
            id: styledFlickable
            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true
            contentWidth: width
            contentHeight: root.contentHeight
            topMargin: 20
            bottomMargin: 20

            Row {
                id: contentRow
                spacing: root.spacing

                Column {
                    id: timeColumn
                    width: root.timeColumnWidth

                    Repeater {
                        model: root.totalSlots
                        delegate: Item {
                            width: parent.width
                            height: root.slotHeight

                            StyledText {
                                text: {
                                    let totalMinutes = root.startMinute + (index * root.slotDuration);
                                    let hour = root.startHour + Math.floor(totalMinutes / 60);
                                    let minute = totalMinutes % 60;

                                    // Format time based on DateTime format
                                    let testDate = new Date();
                                    testDate.setHours(hour, minute, 0);
                                    return Qt.formatTime(testDate, Config.options?.time.format ?? "hh:mm");
                                }
                                anchors.top: parent.top
                                anchors.topMargin: -font.pixelSize / 2
                                anchors.horizontalCenter: parent.horizontalCenter
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnSurfaceVariant
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                Row {
                    id: eventsRow
                    height: root.contentHeight
                    spacing: root.spacing

                    Repeater {
                        model: root.days
                        delegate: Item {
                            width: root.dayColumnWidth
                            height: parent.height
                            clip: true

                            Repeater {
                                model: modelData.events
                                Rectangle {
                                    width: parent.width - 10
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    radius: Appearance.rounding.large
                                    y: {
                                        let startHr = parseInt(modelData.start.split(":")[0]);
                                        let startMin = parseInt(modelData.start.split(":")[1]);
                                        let baseTotalMinutes = root.startHour * 60 + root.startMinute;
                                        let eventTotalMinutes = startHr * 60 + startMin;
                                        let diffMinutes = eventTotalMinutes - baseTotalMinutes;
                                        return diffMinutes * root.pixelsPerMinute;
                                    }
                                    height: {
                                        let startHr = parseInt(modelData.start.split(":")[0]);
                                        let endHr = parseInt(modelData.end.split(":")[0]);
                                        let startMin = parseInt(modelData.start.split(":")[1]);
                                        let endMin = parseInt(modelData.end.split(":")[1]);
                                        let totalMins = (endHr * 60 + endMin) - (startHr * 60 + startMin);
                                        return Math.max(totalMins * root.pixelsPerMinute - 4, 48); // Minimum height for touch targets
                                    }

                                    color: modelData.color || Appearance.colors.colTertiaryContainer

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 4

                                        Text {
                                            text: {
                                                let startHr = parseInt(modelData.start.split(":")[0]);
                                                let startMin = parseInt(modelData.start.split(":")[1]);
                                                let endHr = parseInt(modelData.end.split(":")[0]);
                                                let endMin = parseInt(modelData.end.split(":")[1]);

                                                let formatTime = (hour, minute) => {
                                                    let testDate = new Date();
                                                    testDate.setHours(hour, minute, 0);
                                                    return Qt.formatTime(testDate, Config.options?.time.format ?? "hh:mm");
                                                };

                                                return formatTime(startHr, startMin) + " - " + formatTime(endHr, endMin);
                                            }
                                            font.weight: Font.Medium
                                            color: getContrastingTextColor(modelData.color)
                                            width: parent.width
                                            wrapMode: Text.WordWrap
                                            lineHeight: 1.2
                                        }

                                        Text {
                                            text: modelData.title
                                            font.weight: Font.Medium
                                            wrapMode: Text.WordWrap
                                            width: parent.width
                                            color: getContrastingTextColor(modelData.color)
                                            lineHeight: 1.1
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: currentTimeLine
                width: contentRow.width
                height: 3
                color: Appearance.colors.colPrimary
                y: root.currentTimeY
                visible: root.currentTimeY >= 0 && root.currentTimeY <= contentRow.height
                z: 10
                radius: Appearance.rounding.unsharpen

                // Material 3 time chip
                Rectangle {
                    x: (timeColumn.width / 2) - (width / 2)
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(timeText.implicitWidth + 20, timeColumn.width - 4)
                    height: 32
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colPrimary

                    Text {
                        id: timeText
                        anchors.centerIn: parent
                        text: DateTime.time
                        color: Appearance.colors.colOnPrimary
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
