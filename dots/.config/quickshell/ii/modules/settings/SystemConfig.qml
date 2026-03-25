import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "deployed_code_update"
        title: Translation.tr("System Updates")

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            MaterialSymbol {
                iconSize: 28
                text: Updates.count > 0 ? "system_update" : "check_circle"
                color: Updates.count > 0 ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
            }
            ColumnLayout {
                spacing: 2
                StyledText {
                    text: Updates.checking ? Translation.tr("Checking...")
                        : Updates.count > 0
                            ? Translation.tr("%1 updates available").arg(Updates.count)
                            : Translation.tr("System up to date")
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnSecondaryContainer
                }
                StyledText {
                    visible: Updates.count > 0
                    text: Translation.tr("Arch Linux (checkupdates)")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
            }
        }

        ConfigSwitch {
            buttonIcon: "av_timer"
            text: Translation.tr("Enable update checks")
            checked: Config.options.updates.enableCheck
            onCheckedChanged: {
                Config.options.updates.enableCheck = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "notifications"
            text: Translation.tr("Notify when updates are available")
            enabled: Config.options.updates.enableCheck
            checked: Config.options.updates.notifyAvailableInBackground ?? false
            onCheckedChanged: {
                Config.options.updates.notifyAvailableInBackground = checked;
            }
        }

        ConfigSpinBox {
            icon: "schedule"
            text: Translation.tr("Check interval (mins)")
            value: Config.options.updates.checkInterval
            from: 30
            to: 1440
            stepSize: 30
            onValueChanged: {
                Config.options.updates.checkInterval = value;
            }
        }

        RowLayout {
            spacing: 8
            RippleButtonWithIcon {
                materialIcon: "refresh"
                mainText: Translation.tr("Check now")
                enabled: !Updates.checking
                onClicked: Updates.refresh()
            }
            RippleButtonWithIcon {
                materialIcon: "upgrade"
                mainText: Translation.tr("Run system update")
                onClicked: {
                    Quickshell.execDetached(["bash", "-c", Config.options.apps.update]);
                }
                StyledToolTip {
                    text: Translation.tr("Opens terminal with sudo pacman -Syu")
                }
            }
        }
    }

    ContentSection {
        icon: "computer"
        title: Translation.tr("System Tools")

        ContentSubsection {
            title: Translation.tr("Open system applications")
            tooltip: Translation.tr("Launch these from the config (edit apps.* in config.json to customize)")

            Flow {
                Layout.fillWidth: true
                spacing: 8
                Layout.topMargin: 8

                RippleButtonWithIcon {
                    materialIcon: "bluetooth"
                    mainText: Translation.tr("Bluetooth")
                    onClicked: Quickshell.execDetached(["bash", "-c", Config.options.apps.bluetooth])
                }
                RippleButtonWithIcon {
                    materialIcon: "wifi"
                    mainText: Translation.tr("Network")
                    onClicked: Quickshell.execDetached(["bash", "-c", Config.options.apps.network])
                }
                RippleButtonWithIcon {
                    materialIcon: "person"
                    mainText: Translation.tr("User accounts")
                    onClicked: Quickshell.execDetached(["bash", "-c", Config.options.apps.manageUser])
                }
                RippleButtonWithIcon {
                    materialIcon: "monitoring"
                    mainText: Translation.tr("Task manager")
                    onClicked: Quickshell.execDetached(["bash", "-c", Config.options.apps.taskManager])
                }
                RippleButtonWithIcon {
                    materialIcon: "volume_up"
                    mainText: Translation.tr("Volume mixer")
                    onClicked: {
                        Audio.launchConfigurableShellCommand(Config.options.apps.volumeMixer);
                    }
                }
                RippleButtonWithIcon {
                    materialIcon: "terminal"
                    mainText: Translation.tr("Terminal")
                    onClicked: Quickshell.execDetached(["bash", "-c", Config.options.apps.terminal])
                }
            }
        }
    }
}
