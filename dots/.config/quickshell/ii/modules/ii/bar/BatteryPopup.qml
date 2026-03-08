import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root
    
    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 4

        // Header
        StyledPopupHeaderRow {
            icon: "battery_android_full"
            label: Translation.tr("Battery")
        }

        StyledPopupValueRow {
            visible: {
                let timeValue = Battery.isCharging ? Battery.timeToFull : Battery.timeToEmpty;
                let power = Battery.energyRate;
                return !(Battery.chargeState == 4 || timeValue <= 0 || power <= 0.01);
            }
            icon: "schedule"
            label: Battery.isCharging ? Translation.tr("Time to full:") : Translation.tr("Time to empty:")
            value: {
                if (Battery.isCharging)
                    return DateUtils.formatDuration(Battery.timeToFull);
                else
                    return DateUtils.formatDuration(Battery.timeToEmpty);
            }
        }

        StyledPopupValueRow {
            visible:  !(Battery.chargeState != 4 && Battery.energyRate == 0)
            icon: "bolt"
            label: {
                if (Battery.chargeState == 4) {
                    return Translation.tr("Fully charged");
                } else if (Battery.chargeState == 1) {
                    return Translation.tr("Charging:");
                } else {
                    return Translation.tr("Discharging:");
                }
            }
            value: `${Battery.energyRate.toFixed(2)}W`
        }

        StyledPopupValueRow {
            icon: "heart_check"
            label: Translation.tr("Health:")
            value: `${(Battery.health).toFixed(1)}%`
        }
    }
}
