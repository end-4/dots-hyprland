import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "speed"
        title: Translation.tr("Performance & Internals")

        ConfigSpinBox {
            icon: "timer"
            text: Translation.tr("Race condition delay (ms)")
            value: Config.options.hacks.arbitraryRaceConditionDelay
            from: 0
            to: 500
            stepSize: 5
            onValueChanged: {
                Config.options.hacks.arbitraryRaceConditionDelay = value;
            }
            StyledToolTip {
                text: Translation.tr("Increase if you see glitches during workspace switching or shell reloads")
            }
        }

        ContentSubsection {
            title: Translation.tr("Scrolling")
            ConfigRow {
                uniform: true
                ConfigSpinBox {
                    icon: "mouse"
                    text: Translation.tr("Mouse scroll factor")
                    value: Config.options.interactions.scrolling.mouseScrollFactor
                    from: 10
                    to: 1000
                    stepSize: 10
                    onValueChanged: {
                        Config.options.interactions.scrolling.mouseScrollFactor = value;
                    }
                }
                ConfigSpinBox {
                    icon: "touchpad"
                    text: Translation.tr("Touchpad scroll factor")
                    value: Config.options.interactions.scrolling.touchpadScrollFactor
                    from: 10
                    to: 2000
                    stepSize: 50
                    onValueChanged: {
                        Config.options.interactions.scrolling.touchpadScrollFactor = value;
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "dangerous"
        title: Translation.tr("Conflict Management")

        ConfigSwitch {
            buttonIcon: "notifications_off"
            text: Translation.tr("Auto-kill other notification daemons")
            checked: Config.options.conflictKiller.autoKillNotificationDaemons
            onCheckedChanged: {
                Config.options.conflictKiller.autoKillNotificationDaemons = checked;
            }
        }
        ConfigSwitch {
            buttonIcon: "mfg_canonical_connected"
            text: Translation.tr("Auto-kill other trays")
            checked: Config.options.conflictKiller.autoKillTrays
            onCheckedChanged: {
                Config.options.conflictKiller.autoKillTrays = checked;
            }
        }
    }

    ContentSection {
        icon: "apps"
        title: Translation.tr("Application Overrides")

        ContentSubsection {
            title: Translation.tr("Commands for system utilities")
            
            ConfigRow {
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Terminal (e.g. kitty -1)")
                    text: Config.options.apps.terminal
                    onTextChanged: {
                        Config.options.apps.terminal = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Volume Mixer")
                    text: Config.options.apps.volumeMixer
                    onTextChanged: {
                        Config.options.apps.volumeMixer = text;
                    }
                }
            }
            ConfigRow {
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Network Manager")
                    text: Config.options.apps.network
                    onTextChanged: {
                        Config.options.apps.network = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Bluetooth Manager")
                    text: Config.options.apps.bluetooth
                    onTextChanged: {
                        Config.options.apps.bluetooth = text;
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "window"
        title: Translation.tr("Window & Media")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "format_align_center"
                text: Translation.tr("Center titlebar text")
                checked: Config.options.windows.centerTitle
                onCheckedChanged: {
                    Config.options.windows.centerTitle = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "title"
                text: Translation.tr("Show titlebar")
                checked: Config.options.windows.showTitlebar
                onCheckedChanged: {
                    Config.options.windows.showTitlebar = checked;
                }
            }
        }

        ConfigSwitch {
            buttonIcon: "library_music"
            text: Translation.tr("Filter duplicate media players")
            checked: Config.options.media.filterDuplicatePlayers
            onCheckedChanged: {
                Config.options.media.filterDuplicatePlayers = checked;
            }
        }
    }

    ContentSection {
        icon: "settings_suggest"
        title: Translation.tr("System-wide Tuning")

        ContentSubsection {
            title: Translation.tr("CPU Frequency Governor")
            tooltip: Translation.tr("Requires 'cpupower' package and sudo privileges")
            
            ConfigSelectionArray {
                id: governorSelector
                currentValue: "unknown" // We'll need a way to fetch current governor
                onSelected: newValue => {
                    Quickshell.execDetached(["sudo", "cpupower", "frequency-set", "-g", newValue]);
                }
                options: [
                    { displayName: "Performance", value: "performance", icon: "speed" },
                    { displayName: "Schedutil", value: "schedutil", icon: "bolt" },
                    { displayName: "Powersave", value: "powersave", icon: "eco" }
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("ZRAM (CachyOS)")
            
            ConfigRow {
                StyledText {
                    text: Translation.tr("Status: Managed by system")
                    color: Appearance.colors.colSubtext
                }
                RippleButtonWithIcon {
                    materialIcon: "rebase"
                    mainText: Translation.tr("Optimize now")
                    onClicked: {
                        Quickshell.execDetached(["sudo", "zram-config", "reload"]);
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Kernel Tweaks")
            
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "memory_alt"
                    text: Translation.tr("Transparent Huge Pages")
                    checked: false // Status needs to be fetched
                    onCheckedChanged: {
                        const val = checked ? "always" : "never";
                        Quickshell.execDetached(["bash", "-c", `echo ${val} | sudo tee /sys/kernel/mm/transparent_hugepage/enabled`]);
                    }
                }
                ConfigSwitch {
                    buttonIcon: "database"
                    text: Translation.tr("BFQ Disk Scheduler")
                    checked: false // Status needs to be fetched
                    onCheckedChanged: {
                        const val = checked ? "bfq" : "mq-deadline";
                        Quickshell.execDetached(["bash", "-c", `echo ${val} | sudo tee /sys/block/nvme0n1/queue/scheduler`]);
                    }
                    StyledToolTip {
                        text: Translation.tr("Better responsiveness for HDD/SATA SSDs. NVMe might prefer 'none' or 'mq-deadline'")
                    }
                }
            }
        }
    }
}
