pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import Quickshell
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool hovered: false
    implicitWidth: rowLayout.implicitWidth + 10 * 2
    implicitHeight: Appearance.sizes.barHeight

    hoverEnabled: false

    onClicked: {
        PrayerTimes.refresh();
    }

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent

        MaterialSymbol {
            fill: 0
            text: "mosque"
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            visible: true
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: {
                if (!PrayerTimes.prayerData.nextPrayerTime) {
                    return "Loading..."
                }
                return PrayerTimes.prayerData.nextPrayerName + ": " + Qt.formatTime(PrayerTimes.prayerData.nextPrayerTime, Config.options.time.format)
            }
            Layout.alignment: Qt.AlignVCenter
        }
    }

    //PrayerTimesPopup {
    //    id: prayerTimesPopup
    //    hoverTarget: root
    //}
}
