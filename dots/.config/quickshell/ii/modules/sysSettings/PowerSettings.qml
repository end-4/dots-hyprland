import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * Power management settings — battery thresholds, idle inhibitor, suspend.
 */
ContentPage {
    forceWidth: true

    ContentSection {
        icon: "battery_charging_full"
        title: Translation.tr("Battery Thresholds")

        ConfigSpinBox {
            icon: "battery_alert"
            text: Translation.tr("Low battery (%)")
            value: Config.options.battery.low
            from: 5; to: 50; stepSize: 5
            onValueChanged: { Config.options.battery.low = value }
        }

        ConfigSpinBox {
            icon: "battery_0_bar"
            text: Translation.tr("Critical battery (%)")
            value: Config.options.battery.critical
            from: 1; to: 20; stepSize: 1
            onValueChanged: { Config.options.battery.critical = value }
        }

        ConfigSpinBox {
            icon: "battery_full"
            text: Translation.tr("Full notification threshold (%)")
            value: Config.options.battery.full
            from: 80; to: 101; stepSize: 1
            onValueChanged: { Config.options.battery.full = value }
            StyledToolTip { text: Translation.tr("Set to 101 to disable full-charge notification") }
        }
    }

    ContentSection {
        icon: "power_settings_new"
        title: Translation.tr("Suspend")

        ConfigSwitch {
            buttonIcon: "bedtime"
            text: Translation.tr("Auto-suspend on critical battery")
            checked: Config.options.battery.automaticSuspend
            onCheckedChanged: { Config.options.battery.automaticSuspend = checked }
        }

        ConfigSpinBox {
            icon: "battery_0_bar"
            text: Translation.tr("Suspend at battery (%)")
            value: Config.options.battery.suspend
            from: 1; to: 15; stepSize: 1
            enabled: Config.options.battery.automaticSuspend
            onValueChanged: { Config.options.battery.suspend = value }
        }
    }

    ContentSection {
        icon: "lock"
        title: Translation.tr("Lock Screen")

        ConfigSwitch {
            buttonIcon: "lock"
            text: Translation.tr("Use Hyprlock (instead of built-in)")
            checked: Config.options.lock.useHyprlock
            onCheckedChanged: { Config.options.lock.useHyprlock = checked }
        }
        ConfigSwitch {
            buttonIcon: "play_arrow"
            text: Translation.tr("Launch lock screen on startup")
            checked: Config.options.lock.launchOnStartup
            onCheckedChanged: { Config.options.lock.launchOnStartup = checked }
        }
        ConfigSwitch {
            buttonIcon: "blur_on"
            text: Translation.tr("Blur background when locked")
            checked: Config.options.lock.blur.enable
            onCheckedChanged: { Config.options.lock.blur.enable = checked }
        }
        ConfigSwitch {
            buttonIcon: "key"
            text: Translation.tr("Require password for power actions")
            checked: Config.options.lock.security.requirePasswordToPower
            onCheckedChanged: { Config.options.lock.security.requirePasswordToPower = checked }
        }
    }
}
