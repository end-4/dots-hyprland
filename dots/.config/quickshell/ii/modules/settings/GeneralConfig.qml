import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../common/functions/BatterySavingsPresets.js" as SavingsPresets
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: root
    function useSavingsPreset(preset) {
        const values = SavingsPresets.options(preset.options);
        Object.keys(values).forEach(key => Config.options.battery.savings[key] = values[key]);
        presetName.text = preset.name;
    }
    readonly property var energyHistory: energyHistoryLoader.item
    Loader {
        id: energyHistoryLoader
        active: root.visible && Config.ready && Config.options.battery.monitorConsumption
            && Battery.available && UPower.onBattery
        sourceComponent: BatteryPowerHistory {
            active: true
            powerWatts: Battery.energyRate
        }
    }
    forceWidth: true

    Process {
        id: translationProc
        property string locale: ""
        command: [Directories.aiTranslationScriptPath, translationProc.locale]
    }

    ContentSection {
        icon: "volume_up"
        title: Translation.tr("Audio")

        ConfigSwitch {
            buttonIcon: "hearing"
            text: Translation.tr("Earbang protection")
            checked: Config.options.audio.protection.enable
            onCheckedChanged: {
                Config.options.audio.protection.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Prevents abrupt increments and restricts volume limit")
            }
        }
        ConfigRow {
            enabled: Config.options.audio.protection.enable
            ConfigSpinBox {
                icon: "arrow_warm_up"
                text: Translation.tr("Max allowed increase")
                value: Config.options.audio.protection.maxAllowedIncrease
                from: 0
                to: 100
                stepSize: 2
                onValueChanged: {
                    Config.options.audio.protection.maxAllowedIncrease = value;
                }
            }
            ConfigSpinBox {
                icon: "vertical_align_top"
                text: Translation.tr("Volume limit")
                value: Config.options.audio.protection.maxAllowed
                from: 0
                to: 154 // pavucontrol allows up to 153%
                stepSize: 2
                onValueChanged: {
                    Config.options.audio.protection.maxAllowed = value;
                }
            }
        }
    }

    ContentSection {
        icon: "monitoring"
        title: Translation.tr("Battery consumption")
        ConfigSwitch {
            buttonIcon: "monitoring"
            text: Translation.tr("Monitor battery consumption")
            checked: Config.options.battery.monitorConsumption
            onCheckedChanged: Config.options.battery.monitorConsumption = checked
        }
        StyledText {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: Translation.tr("Measures total battery drain while this page is open. No settings are changed automatically.")
        }
        ColumnLayout {
            Layout.fillWidth: true
            visible: Config.options.battery.monitorConsumption
            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: !Battery.available ? Translation.tr("No laptop battery detected")
                    : !UPower.onBattery ? Translation.tr("Unplug the charger to measure battery drain")
                    : !energyHistory?.validReading ? Translation.tr("Battery power reading unavailable")
                    : Translation.tr("Current consumption: %1 W").arg(Battery.energyRate.toFixed(2))
            }
            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                visible: energyHistoryLoader.active && (energyHistory?.sampleCount ?? 0) > 0
                text: (energyHistory?.sampleCount ?? 0) < 3 ? Translation.tr("Collecting samples for a recent average...")
                    : Translation.tr("Recent average: %1 W (%2 samples)").arg(energyHistory.averageWatts.toFixed(2)).arg((energyHistory?.sampleCount ?? 0))
            }
            RippleButtonWithIcon {
                materialIcon: "restart_alt"
                mainText: Translation.tr("Start a new comparison")
                enabled: energyHistoryLoader.active
                onClicked: { energyHistory?.reset(); energyHistory?.sample(); }
            }
            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: Translation.tr("Change one option at a time, start a new comparison, and keep the same workload for several minutes. Total watts do not identify consumption by app or component.")
            }
        }
    }

    ContentSection {
        icon: "energy_savings_leaf"
        title: Translation.tr("Battery savings")
        ConfigSwitch {
            buttonIcon: "battery_android_bolt"
            text: Translation.tr("Apply selected options on battery power")
            checked: Config.options.battery.savings.enable
            onCheckedChanged: Config.options.battery.savings.enable = checked
        }
        StyledText {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: Translation.tr("Options are restored when disabled or plugged in. Later manual changes are preserved. Enable one option at a time to compare consumption.")
        }
        StyledText {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: !Config.options.battery.savings.enable ? Translation.tr("Battery savings disabled")
                : !Battery.available ? Translation.tr("No laptop battery detected")
                : !UPower.onBattery ? Translation.tr("Waiting for battery power")
                : Translation.tr("Battery savings enabled")
        }
        StyledText {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            visible: BatterySavings.processError.length > 0 || (BatterySavings.state.errors || []).length > 0
            text: Translation.tr("Some options could not be applied or restored:") + "\n"
                + ((BatterySavings.state.errors || []).join("\n") || BatterySavings.processError)
        }
        StyledText {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            visible: (BatterySavings.state.warnings || []).length > 0
            text: Translation.tr("Another application is holding a power profile. The profile option will wait.")
        }
        ConfigSwitch {
            buttonIcon: "brightness_6"
            text: Translation.tr("Limit internal screen brightness")
            checked: Config.options.battery.savings.limitBrightness
            onCheckedChanged: Config.options.battery.savings.limitBrightness = checked
        }
        ConfigSpinBox {
            enabled: Config.options.battery.savings.limitBrightness
            text: Translation.tr("Maximum brightness (%)")
            from: 10
            to: 100
            stepSize: 5
            value: Config.options.battery.savings.brightnessPercent
            onValueChanged: Config.options.battery.savings.brightnessPercent = value
        }
        ConfigSwitch {
            buttonIcon: "speed"
            text: Translation.tr("Use a power profile on battery")
            checked: Config.options.battery.savings.setProfile
            onCheckedChanged: Config.options.battery.savings.setProfile = checked
        }
        ConfigSelectionArray {
            enabled: Config.options.battery.savings.setProfile
            currentValue: Config.options.battery.savings.profile
            onSelected: value => Config.options.battery.savings.profile = value
            options: [
                { displayName: Translation.tr("Power Saver"), icon: "energy_savings_leaf", value: "power-saver" },
                { displayName: Translation.tr("Balanced"), icon: "airwave", value: "balanced" }
            ].concat(PowerProfiles.hasPerformanceProfile ? [
                { displayName: Translation.tr("Performance"), icon: "local_fire_department", value: "performance" }
            ] : [])
        }
        ConfigSwitch {
            buttonIcon: "blur_off"
            text: Translation.tr("Disable blur on battery")
            checked: Config.options.battery.savings.disableBlur
            onCheckedChanged: Config.options.battery.savings.disableBlur = checked
        }
        ConfigSwitch {
            buttonIcon: "animation"
            text: Translation.tr("Disable animations on battery")
            checked: Config.options.battery.savings.disableAnimations
            onCheckedChanged: Config.options.battery.savings.disableAnimations = checked
        }
        ContentSubsectionLabel { text: Translation.tr("My battery presets") }
        MaterialTextField {
            id: presetName
            Layout.fillWidth: true
            maximumLength: 64
            placeholderText: Translation.tr("Preset name")
        }
        RippleButtonWithIcon {
            materialIcon: "save"
            mainText: Translation.tr("Save current options")
            enabled: presetName.text.trim().length > 0 && (
                SavingsPresets.list(Config.options.battery.savings.presets).length < 16
                || SavingsPresets.list(Config.options.battery.savings.presets).some(preset => preset.name === presetName.text.trim()))
            onClicked: Config.options.battery.savings.presets = SavingsPresets.save(
                Config.options.battery.savings.presets, presetName.text, Config.options.battery.savings)
        }
        StyledText {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: Translation.tr("Save up to 16 presets. Choosing one loads its options without enabling battery savings.")
        }
        Repeater {
            model: SavingsPresets.list(Config.options.battery.savings.presets)
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                RippleButtonWithIcon {
                    Layout.fillWidth: true
                    materialIcon: "tune"
                    mainText: modelData.name
                    onClicked: root.useSavingsPreset(modelData)
                }
                RippleButtonWithIcon {
                    materialIcon: "delete"
                    mainText: Translation.tr("Delete")
                    onClicked: Config.options.battery.savings.presets = SavingsPresets.list(
                        Config.options.battery.savings.presets).filter(preset => preset.name !== modelData.name)
                }
            }
        }
    }

    ContentSection {
        icon: "battery_android_full"
        title: Translation.tr("Battery")

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "warning"
                text: Translation.tr("Low warning")
                value: Config.options.battery.low
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.low = value;
                }
            }
            ConfigSpinBox {
                icon: "dangerous"
                text: Translation.tr("Critical warning")
                value: Config.options.battery.critical
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.critical = value;
                }
            }
        }
        ConfigRow {
            uniform: false
            Layout.fillWidth: false
            ConfigSwitch {
                buttonIcon: "pause"
                text: Translation.tr("Automatic suspend")
                checked: Config.options.battery.automaticSuspend
                onCheckedChanged: {
                    Config.options.battery.automaticSuspend = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Automatically suspends the system when battery is low")
                }
            }
            ConfigSpinBox {
                enabled: Config.options.battery.automaticSuspend
                text: Translation.tr("at")
                value: Config.options.battery.suspend
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.suspend = value;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "charger"
                text: Translation.tr("Full warning")
                value: Config.options.battery.full
                from: 0
                to: 101
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.full = value;
                }
            }
        }
    }

    ContentSection {
        icon: "language"
        title: Translation.tr("Language")

        ContentSubsection {
            title: Translation.tr("Interface Language")
            tooltip: Translation.tr("Select the language for the user interface.\n\"Auto\" will use your system's locale.")

            StyledComboBox {
                id: languageSelector
                buttonIcon: "language"
                textRole: "displayName"

                model: [
                    {
                        displayName: Translation.tr("Auto (System)"),
                        value: "auto"
                    },
                    ...Translation.allAvailableLanguages.map(lang => {
                        return {
                            displayName: lang,
                            value: lang
                        };
                    })]

                currentIndex: {
                    const index = model.findIndex(item => item.value === Config.options.language.ui);
                    return index !== -1 ? index : 0;
                }

                onActivated: index => {
                    Config.options.language.ui = model[index].value;
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Generate translation with Gemini")
            tooltip: Translation.tr("You'll need to enter your Gemini API key first.\nType /key on the sidebar for instructions.")

            ConfigRow {
                MaterialTextArea {
                    id: localeInput
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Locale code, e.g. fr_FR, de_DE, zh_CN...")
                    text: Config.options.language.ui === "auto" ? Qt.locale().name : Config.options.language.ui
                }
                RippleButtonWithIcon {
                    id: generateTranslationBtn
                    Layout.fillHeight: true
                    nerdIcon: ""
                    enabled: !translationProc.running || (translationProc.locale !== localeInput.text.trim())
                    mainText: enabled ? Translation.tr("Generate\nTypically takes 2 minutes") : Translation.tr("Generating...\nDon't close this window!")
                    onClicked: {
                        translationProc.locale = localeInput.text.trim();
                        translationProc.running = false;
                        translationProc.running = true;
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "rule"
        title: Translation.tr("Policies")

        ConfigRow {

            // AI policy
            ColumnLayout {
                ContentSubsectionLabel {
                    text: Translation.tr("AI")
                }

                ConfigSelectionArray {
                    currentValue: Config.options.policies.ai
                    onSelected: newValue => {
                        Config.options.policies.ai = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Local only"),
                            icon: "sync_saved_locally",
                            value: 2
                        }
                    ]
                }
            }

            // Weeb policy
            ColumnLayout {

                ContentSubsectionLabel {
                    text: Translation.tr("Weeb")
                }

                ConfigSelectionArray {
                    currentValue: Config.options.policies.weeb
                    onSelected: newValue => {
                        Config.options.policies.weeb = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Closet"),
                            icon: "ev_shadow",
                            value: 2
                        }
                    ]
                }
            }
        }
    }

    ContentSection {
        icon: "notification_sound"
        title: Translation.tr("Sounds")
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "battery_android_full"
                text: Translation.tr("Battery")
                checked: Config.options.sounds.battery
                onCheckedChanged: {
                    Config.options.sounds.battery = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "av_timer"
                text: Translation.tr("Pomodoro")
                checked: Config.options.sounds.pomodoro
                onCheckedChanged: {
                    Config.options.sounds.pomodoro = checked;
                }
            }
        }
    }

    ContentSection {
        icon: "nest_clock_farsight_analog"
        title: Translation.tr("Time")

        ConfigSwitch {
            buttonIcon: "pace"
            text: Translation.tr("Second precision")
            checked: Config.options.time.secondPrecision
            onCheckedChanged: {
                Config.options.time.secondPrecision = checked;
            }
            StyledToolTip {
                text: Translation.tr("Enable if you want clocks to show seconds accurately")
            }
        }

        ContentSubsection {
            title: Translation.tr("Format")
            tooltip: ""

            ConfigSelectionArray {
                currentValue: Config.options.time.format
                onSelected: newValue => {
                    if (newValue === "hh:mm") {
                        Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME12\\b/TIME/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                    } else {
                        Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME\\b/TIME12/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                    }

                    Config.options.time.format = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("24h"),
                        value: "hh:mm"
                    },
                    {
                        displayName: Translation.tr("12h am/pm"),
                        value: "h:mm ap"
                    },
                    {
                        displayName: Translation.tr("12h AM/PM"),
                        value: "h:mm AP"
                    },
                ]
            }
        }
    }

    ContentSection {
        icon: "work_alert"
        title: Translation.tr("Work safety")

        ConfigSwitch {
            buttonIcon: "assignment"
            text: Translation.tr("Hide clipboard images copied from sussy sources")
            checked: Config.options.workSafety.enable.clipboard
            onCheckedChanged: {
                Config.options.workSafety.enable.clipboard = checked;
            }
        }
        ConfigSwitch {
            buttonIcon: "wallpaper"
            text: Translation.tr("Hide sussy/anime wallpapers")
            checked: Config.options.workSafety.enable.wallpaper
            onCheckedChanged: {
                Config.options.workSafety.enable.wallpaper = checked;
            }
        }
    }
}
