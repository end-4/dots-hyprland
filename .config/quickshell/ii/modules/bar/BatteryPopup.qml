import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    readonly property real margin: 10
    implicitWidth: columnLayout.implicitWidth + margin * 2
    implicitHeight: columnLayout.implicitHeight + margin * 2
    color: Appearance.colors.colLayer0
    radius: Appearance.rounding.small
    border.width: 1
    border.color: Appearance.colors.colLayer0Border
    clip: true

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 8

        RowLayout {
            spacing: 5
            Layout.fillWidth: true
            MaterialSymbol { text: "thermostat"; color: Appearance.m3colors.m3onSecondaryContainer }
            StyledText { text: Translation.tr("Temperature:"); color: Appearance.colors.colOnLayer1 }
            StyledText { Layout.fillWidth: true; horizontalAlignment: Text.AlignRight; color: Appearance.colors.colOnLayer1; text: `${Battery.temperature}°C` }
        }

        // This row is hidden when the battery is full.
        RowLayout {
            spacing: 5
            Layout.fillWidth: true
            property bool rowVisible: {
                let timeValue = Battery.isCharging ? Battery.timeToFull : Battery.timeToEmpty;
                let power = Battery.energyRate;
                return !(Battery.chargeState == 4 || timeValue <= 0 || power <= 0.01);
            }
            visible: rowVisible
            opacity: rowVisible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 500 } }

            MaterialSymbol { text: "schedule"; color: Appearance.m3colors.m3onSecondaryContainer }
            StyledText { text: Battery.isCharging ? Translation.tr("Time to full:") : Translation.tr("Time to empty:"); color: Appearance.colors.colOnLayer1 }
            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                color: Appearance.colors.colOnLayer1
                text: {
                    function formatTime(seconds) {
                        var h = Math.floor(seconds / 3600);
                        var m = Math.floor((seconds % 3600) / 60);
                        if (h > 0)
                            return `${h}h, ${m}m`;
                        else
                            return `${m}m`;
                    }
                    if (Battery.isCharging)
                        return formatTime(Battery.timeToFull);
                    else
                        return formatTime(Battery.timeToEmpty);
                }
            }
        }

        RowLayout {
            spacing: 5
            Layout.fillWidth: true

            property bool rowVisible: !(Battery.chargeState != 4 && Battery.energyRate == 0)
            visible: rowVisible
            opacity: rowVisible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 500 } }

            MaterialSymbol {
                text: {
                    if (Battery.isCharging) {
                        return "power";
                    } else if (Battery.percentage >= 0.8) {
                        return "battery_full";
                    } else if (Battery.percentage >= 0.6) {
                        return "battery_5_bar";
                    } else if (Battery.percentage >= 0.4) {
                        return "battery_4_bar";
                    } else if (Battery.percentage >= 0.2) {
                        return "battery_2_bar";
                    } else {
                        return "battery_0_bar";
                    }
                }
                color: Appearance.m3colors.m3onSecondaryContainer
            }


            StyledText {
                text: {
                    if (Battery.chargeState == 4) {
                        return Translation.tr("Fully charged");
                    } else if (Battery.chargeState == 1) {
                        return Translation.tr("Charging:");
                    } else {
                        return Translation.tr("Discharging:");
                    }
                }
                color: Appearance.colors.colOnLayer1
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                color: Appearance.colors.colOnLayer1
                text: {
                    if (Battery.chargeState == 4) {
                        return "";
                    } else {
                        return `${Battery.energyRate.toFixed(2)}W`;
                    }
                }
            }
        }

    }
}
