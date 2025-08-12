import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property var chargeState: Battery.chargeState
    readonly property bool isCharging: Battery.isCharging
    readonly property bool isPluggedIn: Battery.isPluggedIn
    readonly property real percentage: Battery.percentage
    readonly property bool isLow: percentage <= Config.options.battery.low / 100

    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: 32

    hoverEnabled: true

    RowLayout {
        id: rowLayout

        spacing: 4
        anchors.centerIn: parent

        ClippedProgressBar {
            id: batteryProgress
            value: percentage
            highlightColor: (isLow && !isCharging) ? Appearance.m3colors.m3error : Appearance.colors.colOnSecondaryContainer

            Item {
                anchors.centerIn: parent
                width: batteryProgress.valueBarWidth
                height: batteryProgress.valueBarHeight

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 0

                    MaterialSymbol {
                        id: boltIcon
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: -2
                        Layout.rightMargin: -2
                        fill: 1
                        text: "bolt"
                        iconSize: Appearance.font.pixelSize.smaller
                        visible: isCharging && percentage < 1 // TODO: animation
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignVCenter
                        font: batteryProgress.font
                        text: batteryProgress.text
                    }
                }
            }
        }
    }

    BatteryPopup {
        id: batteryPopup
        hoverTarget: root
    }
}
