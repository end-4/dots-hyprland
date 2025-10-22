import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import qs.modules.bar as Bar

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property var chargeState: Battery.chargeState
    readonly property bool isCharging: Battery.isCharging
    readonly property bool isPluggedIn: Battery.isPluggedIn
    readonly property real percentage: Battery.percentage
    readonly property bool isLow: percentage <= Config.options.battery.low / 100

    implicitHeight: batteryProgress.implicitHeight
    hoverEnabled: true

    ClippedProgressBar {
        id: batteryProgress
        anchors.centerIn: parent
        vertical: true
        valueBarWidth: 21
        valueBarHeight: 40
        value: percentage
        highlightColor: (isLow && !isCharging) ? Appearance.m3colors.m3error : Appearance.colors.colOnSecondaryContainer

        font {
            pixelSize: text.length > 2 ? 11 : 13
            weight: text.length > 2 ? Font.Medium : Font.DemiBold
        }

        textMask: Item {
            anchors.centerIn: parent
            width: batteryProgress.valueBarWidth
            height: batteryProgress.valueBarHeight

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0

                MaterialSymbol {
                    id: boltIcon
                    Layout.alignment: Qt.AlignHCenter
                    fill: 1
                    text: isCharging ? "bolt" : "battery_android_full"
                    iconSize: Appearance.font.pixelSize.normal
                    animateChange: true
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    font: batteryProgress.font
                    text: batteryProgress.text
                }
            }
        }
    }

    Bar.BatteryPopup {
        id: batteryPopup
        hoverTarget: root
    }
}
