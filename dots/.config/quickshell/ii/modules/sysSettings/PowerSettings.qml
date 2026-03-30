import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * Power management settings — power profiles, battery thresholds, idle, suspend.
 */
ContentPage {
    forceWidth: true

    ContentSection {
        icon: "bolt"
        title: Translation.tr("Power Profile")

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            MaterialSymbol {
                text: PowerProfileService.currentProfileIcon
                iconSize: 28
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: Translation.tr("Current: %1").arg(PowerProfileService.currentProfileName)
                font { pixelSize: Appearance.font.pixelSize.normal; family: Appearance.font.family.title }
                color: Appearance.colors.colOnLayer0
                Layout.fillWidth: true
            }
        }

        Repeater {
            model: [
                { profile: PowerProfile.PowerSaver,   name: Translation.tr("Power Saver"),  icon: "energy_savings_leaf", desc: Translation.tr("Reduced performance, longer battery") },
                { profile: PowerProfile.Balanced,      name: Translation.tr("Balanced"),     icon: "airwave",             desc: Translation.tr("Standard performance and power usage") },
                { profile: PowerProfile.Performance,   name: Translation.tr("Performance"),  icon: "local_fire_department", desc: Translation.tr("Maximum performance, higher power draw") },
            ]
            delegate: RippleButton {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 56
                buttonRadius: Appearance.rounding.normal
                visible: modelData.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                colBackground: PowerProfiles.profile === modelData.profile ? Appearance.colors.colPrimaryContainer : "transparent"
                colBackgroundHover: Appearance.colors.colLayer1Hover
                onClicked: PowerProfileService.setProfile(
                    modelData.profile === PowerProfile.PowerSaver ? "power-saver" :
                    modelData.profile === PowerProfile.Performance ? "performance" : "balanced"
                )

                contentItem: RowLayout {
                    anchors { fill: parent; margins: 12 }
                    spacing: 12
                    MaterialSymbol {
                        text: PowerProfiles.profile === modelData.profile ? "radio_button_checked" : "radio_button_unchecked"
                        iconSize: 20
                        color: PowerProfiles.profile === modelData.profile ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                    }
                    MaterialSymbol {
                        text: modelData.icon
                        iconSize: 22
                        color: PowerProfiles.profile === modelData.profile ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer0
                    }
                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true
                        StyledText {
                            text: modelData.name
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: PowerProfiles.profile === modelData.profile ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer0
                        }
                        StyledText {
                            text: modelData.desc
                            font.pixelSize: Appearance.font.pixelSize.smallie
                            color: PowerProfiles.profile === modelData.profile ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                        }
                    }
                }
            }
        }

        StyledText {
            text: Translation.tr("Tip: Press Fn+Q to cycle profiles quickly")
            font.pixelSize: Appearance.font.pixelSize.smallie
            color: Appearance.colors.colSubtext
            font.italic: true
        }
    }
        icon: "battery_charging_full"
        title: Translation.tr("Battery Thresholds")

        ConfigSpinBox {
            icon: "battery_alert"
            text: Translation.tr("Low battery (%)")
            value: Config.options.battery.low
            from: 5; to: 50; stepSize: 5
            onValueChanged: { Config.options.battery.low = value; Config.save() }
        }

        ConfigSpinBox {
            icon: "battery_0_bar"
            text: Translation.tr("Critical battery (%)")
            value: Config.options.battery.critical
            from: 1; to: 20; stepSize: 1
            onValueChanged: { Config.options.battery.critical = value; Config.save() }
        }

        ConfigSpinBox {
            icon: "battery_full"
            text: Translation.tr("Full notification threshold (%)")
            value: Config.options.battery.full
            from: 80; to: 101; stepSize: 1
            onValueChanged: { Config.options.battery.full = value; Config.save() }
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
            onCheckedChanged: { Config.options.battery.automaticSuspend = checked; Config.save() }
        }

        ConfigSpinBox {
            icon: "battery_0_bar"
            text: Translation.tr("Suspend at battery (%)")
            value: Config.options.battery.suspend
            from: 1; to: 15; stepSize: 1
            enabled: Config.options.battery.automaticSuspend
            onValueChanged: { Config.options.battery.suspend = value; Config.save() }
        }
    }

    ContentSection {
        icon: "lock"
        title: Translation.tr("Lock Screen")

        ConfigSwitch {
            buttonIcon: "lock"
            text: Translation.tr("Use Hyprlock (instead of built-in)")
            checked: Config.options.lock.useHyprlock
            onCheckedChanged: { Config.options.lock.useHyprlock = checked; Config.save() }
        }
        ConfigSwitch {
            buttonIcon: "play_arrow"
            text: Translation.tr("Launch lock screen on startup")
            checked: Config.options.lock.launchOnStartup
            onCheckedChanged: { Config.options.lock.launchOnStartup = checked; Config.save() }
        }
        ConfigSwitch {
            buttonIcon: "blur_on"
            text: Translation.tr("Blur background when locked")
            checked: Config.options.lock.blur.enable
            onCheckedChanged: { Config.options.lock.blur.enable = checked; Config.save() }
        }
        ConfigSwitch {
            buttonIcon: "key"
            text: Translation.tr("Require password for power actions")
            checked: Config.options.lock.security.requirePasswordToPower
            onCheckedChanged: { Config.options.lock.security.requirePasswordToPower = checked; Config.save() }
        }
    }
}
