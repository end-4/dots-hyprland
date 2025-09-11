import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import Quickshell.Io

Item {
    id: root

    readonly property var prayerOrder: ["fajr", "dhuhr", "asr", "maghrib", "isha"]
    readonly property var prayerNames: {"fajr": "Fajr", "dhuhr": "Dhuhr", "asr": "Asr", "maghrib": "Maghrib", "isha": "Isha"}

    readonly property bool prayerDataAvailable: PrayerTimes ? PrayerTimes.dataLoaded : false

    ColumnLayout {
        anchors.fill: parent
        visible: prayerDataAvailable
        spacing: 10
        anchors.margins: 10
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 60
        color: "transparent"

        RowLayout {
            anchors.fill: parent
            spacing: 10

            ColumnLayout {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                spacing: 2
                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    iconSize: 15
                    color: Appearance.m3colors.m3primary
                    text: "wb_sunny"
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    color: Appearance.m3colors.m3onSurface
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    text: PrayerTimes.prayerData.sunrise ? Qt.formatTime(PrayerTimes.prayerData.sunrise, Config.options.time.format) : "--:--"
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                spacing: 5
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    color: Appearance.m3colors.m3onSurface
                    font.pixelSize: Appearance.font.pixelSize.medium
                    text: Translation.tr("Next prayer")
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    color: Appearance.m3colors.m3primary
                    font.bold: true
                    font.pixelSize: Appearance.font.pixelSize.large
                    text: PrayerTimes.prayerData.nextPrayerName + ": " + (PrayerTimes.prayerData.nextPrayerTime ? Qt.formatTime(PrayerTimes.prayerData.nextPrayerTime, Config.options.time.format) : "")
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    color: Appearance.m3colors.m3onSurface
                    font.pixelSize: Appearance.font.pixelSize.small
                    opacity: 0.9
                    text: PrayerTimes.prayerData.hijriDate || "September 9, 2025"
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                spacing: 2
                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    iconSize: 15
                    color: Appearance.m3colors.m3primary
                    text: "nightlight"
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    color: Appearance.m3colors.m3onSurface
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    text: PrayerTimes.prayerData.sunset ? Qt.formatTime(PrayerTimes.prayerData.sunset, Config.options.time.format) : "--:--"
                }
            }
        }
    }


        // Prayer times list
        ListView {
            id: prayerListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.prayerOrder
            delegate: Rectangle {
                width: prayerListView.width
                height: 50
                radius: Appearance.rounding.large
                color: PrayerTimes.prayerData.nextPrayerName === root.prayerNames[modelData] ?
                       Appearance.colors.colPrimaryContainer :
                       "transparent"
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 15
                    StyledText {
                        Layout.fillWidth: true
                        color: PrayerTimes.prayerData.nextPrayerName === root.prayerNames[modelData] ?
                               Appearance.m3colors.m3onPrimaryContainer :
                               Appearance.m3colors.m3onSurface
                        font.bold: PrayerTimes.prayerData.nextPrayerName === root.prayerNames[modelData]
                        text: root.prayerNames[modelData]
                    }
                    StyledText {
                        color: PrayerTimes.prayerData.nextPrayerName === root.prayerNames[modelData] ?
                               Appearance.m3colors.m3onPrimaryContainer :
                               Appearance.m3colors.m3onSurfaceVariant
                        text: PrayerTimes.prayerData[modelData] ? Qt.formatTime(PrayerTimes.prayerData[modelData], Config.options.time.format) : "--:--"
                        font.bold: PrayerTimes.prayerData.nextPrayerName === root.prayerNames[modelData]
                    }
                }
            }
        }
    }

    // Placeholder when list is empty
    Item {
        opacity: !prayerDataAvailable ? 1 : 0
        anchors.fill: parent
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 5
            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                iconSize: 55
                color: Appearance.m3colors.m3error
                text: "error"
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.m3colors.m3error
                horizontalAlignment: Text.AlignHCenter
                text: Translation.tr("No prayer times available")
            }
        }
        Behavior on opacity {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
    }
}
