import QtQuick
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: generalPage
    forceWidth: true
    property bool plymouthXanaInstalled: false

    Timer {
        id: generalIdleTimer
        interval: 200
        repeat: false
        onTriggered: {
            generalIdleProc.running = false;
            generalIdleProc.running = true;
        }
    }

    Process {
        id: generalIdleProc
        command: ["python3", Quickshell.shellPath("scripts/apply-screensaver-idle.py")]
    }

    Process {
        id: plymouthCheckProc
        running: true
        command: ["bash", "-c", "[ -f /usr/share/plymouth/themes/xana/xana.plymouth ] && echo 1 || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: generalPage.plymouthXanaInstalled = (text.trim() === "1")
        }
    }

    FileDialog {
        id: plymouthLogoPicker
        title: Translation.tr("Select boot splash logo")
        nameFilters: ["Images & Vector (*.png *.svg *.jpg *.jpeg *.webp *.pdf)", "All files (*)"]
        onAccepted: {
            const p = selectedFile.toString().replace(/^file:\/\//, "");
            const script = Quickshell.shellPath("scripts/apply-plymouth-logo.sh");
            Quickshell.execDetached(["bash", "-c", `${Config.options.apps.terminal} -e bash -c '"${0}" "${1}"; echo; read -p "Press Enter to close..."' "${script}" "${p}"`]);
        }
    }

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

    ContentSection {
        icon: "lock"
        title: Translation.tr("Lock")

        ConfigSwitch {
            buttonIcon: "lock_clock"
            text: Translation.tr("Lock screen on idle")
            checked: Config.options.lock.idle.enableLock
            onCheckedChanged: {
                if (Config.options.lock.idle.enableLock !== checked) {
                    Config.options.lock.idle.enableLock = checked;
                    generalIdleTimer.restart();
                }
            }
        }

        ConfigSpinBox {
            visible: Config.options.lock.idle.enableLock
            icon: "timer"
            text: Translation.tr("Lock timeout (minutes)")
            value: Config.options.lock.idle.lockMinutes
            from: 1
            to: 120
            stepSize: 1
            onValueChanged: {
                if (Config.options.lock.idle.lockMinutes !== value) {
                    Config.options.lock.idle.lockMinutes = value;
                    generalIdleTimer.restart();
                }
            }
        }

        ConfigSwitch {
            buttonIcon: "monitor"
            text: Translation.tr("Turn off display (DPMS)")
            checked: Config.options.lock.idle.enableDpms
            onCheckedChanged: {
                if (Config.options.lock.idle.enableDpms !== checked) {
                    Config.options.lock.idle.enableDpms = checked;
                    generalIdleTimer.restart();
                }
            }
        }

        ConfigSpinBox {
            visible: Config.options.lock.idle.enableDpms
            icon: "timer"
            text: Translation.tr("Display off timeout (minutes)")
            value: Config.options.lock.idle.dpmsMinutes
            from: 1
            to: 180
            stepSize: 1
            onValueChanged: {
                if (Config.options.lock.idle.dpmsMinutes !== value) {
                    Config.options.lock.idle.dpmsMinutes = value;
                    generalIdleTimer.restart();
                }
            }
        }

        ConfigSwitch {
            buttonIcon: "bedtime"
            text: Translation.tr("Deep sleep (Suspend)")
            checked: Config.options.lock.idle.enableSuspend
            onCheckedChanged: {
                if (Config.options.lock.idle.enableSuspend !== checked) {
                    Config.options.lock.idle.enableSuspend = checked;
                    generalIdleTimer.restart();
                }
            }
        }

        ConfigSpinBox {
            visible: Config.options.lock.idle.enableSuspend
            icon: "timer"
            text: Translation.tr("Suspend timeout (minutes)")
            value: Config.options.lock.idle.suspendMinutes
            from: 5
            to: 360
            stepSize: 5
            onValueChanged: {
                if (Config.options.lock.idle.suspendMinutes !== value) {
                    Config.options.lock.idle.suspendMinutes = value;
                    generalIdleTimer.restart();
                }
            }
        }

        RowLayout {
            visible: generalPage.plymouthXanaInstalled
            Layout.fillWidth: true
            spacing: 8
            MaterialSymbol {
                text: "image"
                iconSize: 20
                color: Appearance.m3colors.m3onSurface
            }
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Boot splash logo (Plymouth)")
                color: Appearance.m3colors.m3onSurface
                font.pixelSize: Appearance.font.pixelSize.small
            }
            RippleButton {
                implicitWidth: plymouthBtnTxt.implicitWidth + 24
                implicitHeight: 34
                buttonRadius: Appearance.rounding.full
                colBackground: Appearance.colors.colSecondaryContainer
                onClicked: plymouthLogoPicker.open()
                contentItem: StyledText {
                    id: plymouthBtnTxt
                    anchors.centerIn: parent
                    text: Translation.tr("Choose File")
                    color: Appearance.colors.colOnSecondaryContainer
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                }
            }
        }
    }
}
