import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar as Bar

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property var chargeState: Battery.chargeState
    readonly property bool isCharging: Battery.isCharging
    readonly property bool isPluggedIn: Battery.isPluggedIn
    readonly property real percentage: Battery.percentage
    readonly property bool isLow: percentage <= Config.options.battery.low / 100

    implicitHeight: batteryProgress.implicitHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    ClippedProgressBar {
        id: batteryProgress
        anchors.centerIn: parent
        vertical: true
        valueBarWidth: 20
        valueBarHeight: 36
        value: percentage
        // value: 1
        highlightColor: (isLow && !isCharging) ? Appearance.m3colors.m3error : Appearance.colors.colOnSecondaryContainer

        font {
            pixelSize: 13
            weight: Font.DemiBold
        }

        textMask: Item {
            anchors.centerIn: parent
            width: batteryProgress.valueBarWidth
            height: batteryProgress.valueBarHeight

            Column {
                anchors.centerIn: parent
                spacing: -4

                MaterialSymbol {
                    id: boltIcon
                    anchors.horizontalCenter: parent.horizontalCenter
                    fill: 1
                    text: {
                        if (batteryProgress.value == 1) {
                            return "check";
                        } else if (root.isCharging) {
                            return "bolt";
                        } else {
                            return Icons.getBatteryIcon(Battery.percentage * 100);
                        }
                    }
                    iconSize: Appearance.font.pixelSize.normal
                    animateChange: true
                }
                StyledText {
                    visible: text.length <= 2
                    anchors.horizontalCenter: parent.horizontalCenter
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
